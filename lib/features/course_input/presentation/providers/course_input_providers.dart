import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/summary.dart';
import '../../../../services/firebase_service.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/local_database_service.dart';
import '../../../../features/auth/providers/auth_providers.dart';

final courseInputControllerProvider = Provider<CourseInputController>((ref) {
  return CourseInputController(ref);
});

class CourseInputController {
  final Ref _ref;
  final _uuid = const Uuid();

  CourseInputController(this._ref);

  Future<String> createSummaryFromText({
    required String title,
    required String content,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    try {
      // Generate AI summary
      final summaryText = await AiService.generateSummary(content);
      
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
      );

      // Save to Firestore
      await FirebaseService.summaries.doc(summary.id).set(summary.toFirestore());

      // Save locally automatically
      await LocalDatabaseService.saveSummary(
        title: summary.title,
        originalText: null,
        summaryContent: summary.content,
        keywords: summary.keywords,
        language: null,
      );

      return summary.id;
    } catch (e) {
      throw Exception('Failed to create summary: $e');
    }
  }
}
