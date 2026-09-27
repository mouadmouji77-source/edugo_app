import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un Quiz complet
class Quiz {
  final String id; // ID du document Firestore
  final String uid; // ID de l'utilisateur propriétaire
  final String summaryId; // ID du résumé associé
  final List<QuizQuestion> questions; // Liste des questions du quiz
  final DateTime createdAt; // Date de création

  const Quiz({
    required this.id,
    required this.uid,
    required this.summaryId,
    required this.questions,
    required this.createdAt,
  });

  /// Crée un Quiz à partir d'un document Firestore
  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      uid: data['uid'] ?? '',
      summaryId: data['summaryId'] ?? '',
      questions: (data['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromMap(q))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit le Quiz pour le stockage Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'summaryId': summaryId,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Modèle représentant une question de quiz individuelle
class QuizQuestion {
  final String question; // Texte de la question
  final List<String> options; // Liste des options de réponse
  final int correctIndex; // Index de la bonne réponse (0-3)
  final String? explanation; // Explication de la réponse (optionnel)

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  /// Crée une question à partir d'une Map
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      explanation: map['explanation'],
    );
  }

  /// Convertit la question en Map
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      if (explanation != null) 'explanation': explanation,
    };
  }
}
