import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import '../../../../core/models/summary.dart';
import '../../../../services/firebase_service.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/local_database_service.dart';
import '../../../../features/auth/providers/auth_providers.dart';

final pdfUploadControllerProvider = Provider<PdfUploadController>((ref) {
  return PdfUploadController(ref);
});

class PdfUploadController {
  final Ref _ref;
  final _uuid = const Uuid();

  PdfUploadController(this._ref);

  Future<String> uploadAndProcessPdf({
    required String title,
    required PlatformFile file,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get PDF bytes
      final Uint8List? pdfBytes = file.bytes;
      if (pdfBytes == null) {
        throw Exception('Could not read PDF file. Please try again.');
      }

      // Extract text from PDF using Cloud Function
      final extractedText = await AiService.extractTextFromPdf(pdfBytes);
      
      if (extractedText.isEmpty) {
        throw Exception('No text could be extracted from this PDF.');
      }
      
      // Generate summary from extracted text
      final summaryText = await AiService.generateSummary(extractedText);
      
      // Extract keywords
      final keywords = await AiService.extractKeywords(summaryText);

      // Create summary object
      final summary = Summary(
        id: _uuid.v4(),
        uid: user.uid,
        title: title,
        content: summaryText,
        keywords: keywords,
        createdAt: DateTime.now(),
        pdfUrl: null,
      );

      // Save to Firestore
      await FirebaseService.summaries.doc(summary.id).set(summary.toFirestore());

      // Save locally automatically
      await LocalDatabaseService.saveSummary(
        title: summary.title,
        originalText: null, // We don't save the full extracted text locally to save space
        summaryContent: summary.content,
        keywords: summary.keywords,
        language: null,
      );

      return summary.id;
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    }
  }
}
