import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/quiz.dart';
import '../../../../core/models/quiz_score.dart';
import '../../../../services/firebase_service.dart';
import '../../../../features/auth/providers/auth_providers.dart';

final quizProvider = StreamProvider.family<Quiz?, String>((ref, quizId) {
  return FirebaseService.quizzes
      .doc(quizId)
      .snapshots()
      .map((doc) => doc.exists ? Quiz.fromFirestore(doc) : null);
});

final userQuizzesProvider = StreamProvider<List<Quiz>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return FirebaseService.quizzes
      .where('uid', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final quizzes = snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList();
        // Sort client-side to avoid needing composite index
        quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return quizzes;
      });
});

final userScoresProvider = StreamProvider<List<QuizScore>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return FirebaseService.scores
      .where('uid', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final scores = snapshot.docs.map((doc) => QuizScore.fromFirestore(doc)).toList();
        // Sort client-side to avoid needing composite index
        scores.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return scores;
      });
});

final quizControllerProvider = Provider<QuizController>((ref) {
  return QuizController(ref);
});

class QuizController {
  final Ref _ref;
  final _uuid = const Uuid();

  QuizController(this._ref);

  Future<int> submitQuiz({
    required Quiz quiz,
    required List<int> selectedAnswers,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    try {
      // Calculate score
      int score = 0;
      for (int i = 0; i < quiz.questions.length; i++) {
        if (i < selectedAnswers.length && 
            selectedAnswers[i] == quiz.questions[i].correctIndex) {
          score++;
        }
      }

      // Create quiz score object
      final quizScore = QuizScore(
        id: _uuid.v4(),
        uid: user.uid,
        quizId: quiz.id,
        score: score,
        totalQuestions: quiz.questions.length,
        completedAt: DateTime.now(),
        selectedAnswers: selectedAnswers,
      );

      // Save to Firestore
      await FirebaseService.scores.doc(quizScore.id).set(quizScore.toFirestore());

      return score;
    } catch (e) {
      throw Exception('Failed to submit quiz: $e');
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await FirebaseService.quizzes.doc(quizId).delete();
    } catch (e) {
      throw Exception('Failed to delete quiz: $e');
    }
  }
}
