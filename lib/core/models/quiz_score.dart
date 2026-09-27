import 'package:cloud_firestore/cloud_firestore.dart';

class QuizScore {
  final String id;
  final String uid;
  final String quizId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final List<int> selectedAnswers;

  const QuizScore({
    required this.id,
    required this.uid,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.selectedAnswers,
  });

  factory QuizScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizScore(
      id: doc.id,
      uid: data['uid'] ?? '',
      quizId: data['quizId'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      selectedAnswers: List<int>.from(data['selectedAnswers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'quizId': quizId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': Timestamp.fromDate(completedAt),
      'selectedAnswers': selectedAnswers,
    };
  }

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
}
