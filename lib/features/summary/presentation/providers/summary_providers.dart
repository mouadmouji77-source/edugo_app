import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../core/models/summary.dart';
import '../../../../core/models/quiz.dart';
import '../../../../services/firebase_service.dart';
import '../../../../services/ai_service.dart';
import '../../../../features/auth/providers/auth_providers.dart';

final summaryProvider = StreamProvider.family<Summary?, String>((ref, summaryId) {
  return FirebaseService.summaries
      .doc(summaryId)
      .snapshots()
      .map((doc) => doc.exists ? Summary.fromFirestore(doc) : null);
});

final userSummariesProvider = StreamProvider<List<Summary>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return FirebaseService.summaries
      .where('uid', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final summaries = snapshot.docs.map((doc) => Summary.fromFirestore(doc)).toList();
        // Sort client-side to avoid needing composite index
        summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return summaries;
      });
});

final summaryControllerProvider = Provider<SummaryController>((ref) {
  return SummaryController(ref);
});

class SummaryController {
  final Ref _ref;
  final _uuid = const Uuid();

  SummaryController(this._ref);

  Future<String> generateQuizFromSummary(Summary summary, {int numberOfQuestions = 5}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    try {
      // Generate quiz questions using AI
      final questions = await AiService.generateQuiz(
        summary.content,
        numberOfQuestions: numberOfQuestions,
      );

      if (questions.isEmpty) {
        throw Exception('No questions could be generated from this summary');
      }

      // Create quiz object
      final quiz = Quiz(
        id: _uuid.v4(),
        uid: user.uid,
        summaryId: summary.id,
        questions: questions,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await FirebaseService.quizzes.doc(quiz.id).set(quiz.toFirestore());

      return quiz.id;
    } catch (e) {
      throw Exception('Failed to generate quiz: $e');
    }
  }

  Future<void> exportSummaryAsPdf(Summary summary) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    summary.title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated on: ${summary.createdAt.toString().split('.').first}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  summary.content,
                  style: const pw.TextStyle(fontSize: 14),
                ),
                if (summary.keywords.isNotEmpty) ...[
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Keywords:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summary.keywords
                        .map((keyword) => pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue100,
                                borderRadius: pw.BorderRadius.circular(12),
                              ),
                              child: pw.Text(
                                keyword,
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Save or print the PDF
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  Future<void> deleteSummary(String summaryId) async {
    try {
      await FirebaseService.summaries.doc(summaryId).delete();
    } catch (e) {
      throw Exception('Failed to delete summary: $e');
    }
  }
}
