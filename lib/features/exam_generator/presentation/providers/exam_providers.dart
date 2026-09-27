import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/exam.dart';
import '../../../../services/firebase_service.dart';
import '../../../../services/ai_service.dart';
import '../../../../features/auth/providers/auth_providers.dart';

final userExamsProvider = StreamProvider<List<Exam>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return FirebaseService.exams
      .where('uid', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final exams = snapshot.docs.map((doc) => Exam.fromFirestore(doc)).toList();
        exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return exams;
      });
});

final examProvider = StreamProvider.family<Exam?, String>((ref, examId) {
  return FirebaseService.exams
      .doc(examId)
      .snapshots()
      .map((doc) => doc.exists ? Exam.fromFirestore(doc) : null);
});

final examControllerProvider = Provider<ExamController>((ref) {
  return ExamController(ref);
});

class ExamController {
  final Ref _ref;
  final _uuid = const Uuid();

  ExamController(this._ref);

  Future<Exam> generateExam({
    Uint8List? pdfBytes,
    String? textContent,
    required String schoolName,
    required String examTitle,
    String? logoBase64,
    required ExamDifficulty difficulty,
    required TotalScore totalScore,
    required int numberOfQuestions,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    try {
      String courseContent;
      
      if (textContent != null && textContent.isNotEmpty) {
        courseContent = textContent;
      } else if (pdfBytes != null) {
        courseContent = await AiService.extractTextFromPdf(pdfBytes);
        
        if (courseContent.isEmpty) {
          throw Exception('PDF appears to be empty. Please upload a PDF with text content.');
        }
        
        if (courseContent.contains('Unable to extract') || courseContent.contains('No text could be extracted')) {
          throw Exception('Could not extract text from PDF. It may be an image-based PDF.');
        }
      } else {
        throw Exception('Please provide either a PDF file or text content.');
      }
      
      if (courseContent.length < 100) {
        throw Exception('Content is too short. Please provide more substantial content.');
      }

      final questions = await AiService.generateExamQuestions(
        content: courseContent,
        difficulty: difficulty,
        totalScore: totalScore,
        numberOfQuestions: numberOfQuestions,
      );

      if (questions.isEmpty) {
        throw Exception('No questions could be generated');
      }

      // Create exam object
      final exam = Exam(
        id: _uuid.v4(),
        uid: user.uid,
        schoolName: schoolName,
        examTitle: examTitle,
        logoBase64: logoBase64,
        difficulty: difficulty,
        totalScore: totalScore,
        questions: questions,
        sourceContent: courseContent,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await FirebaseService.exams.doc(exam.id).set(exam.toFirestore());

      return exam;
    } catch (e) {
      throw Exception('Failed to generate exam: $e');
    }
  }

  Future<void> deleteExam(String examId) async {
    await FirebaseService.exams.doc(examId).delete();
  }
}

