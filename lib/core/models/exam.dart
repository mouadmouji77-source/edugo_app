import 'package:cloud_firestore/cloud_firestore.dart';

/// Énumération pour le niveau de difficulté de l'examen
enum ExamDifficulty { easy, medium, hard }

/// Énumération pour le score total de l'examen
enum TotalScore { twenty, hundred }

/// Modèle représentant une question d'examen individuelle
class ExamQuestion {
  final String question; // Texte de la question
  final double points; // Nombre de points attribués
  final String? expectedAnswer; // Réponse attendue (optionnel)
  final ExamDifficulty difficulty; // Niveau de difficulté de la question

  ExamQuestion({
    required this.question,
    required this.points,
    this.expectedAnswer,
    required this.difficulty,
  });

  /// Crée une question à partir d'une Map
  factory ExamQuestion.fromMap(Map<String, dynamic> map) {
    return ExamQuestion(
      question: map['question'] ?? '',
      points: (map['points'] ?? 0).toDouble(),
      expectedAnswer: map['expectedAnswer'],
      difficulty: ExamDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => ExamDifficulty.medium,
      ),
    );
  }

  /// Convertit la question en Map
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'points': points,
      'expectedAnswer': expectedAnswer,
      'difficulty': difficulty.name,
    };
  }
}

/// Modèle représentant un Examen complet
class Exam {
  final String id; // ID du document Firestore
  final String uid; // ID de l'utilisateur propriétaire
  final String schoolName; // Nom de l'établissement
  final String examTitle; // Titre de l'examen
  final String? logoBase64; // Logo de l'établissement en base64 (optionnel)
  final ExamDifficulty difficulty; // Difficulté globale
  final TotalScore totalScore; // Score total (sur 20 ou 100)
  final List<ExamQuestion> questions; // Liste des questions
  final String sourceContent; // Contenu source utilisé pour générer l'examen
  final DateTime createdAt; // Date de création

  Exam({
    required this.id,
    required this.uid,
    required this.schoolName,
    required this.examTitle,
    this.logoBase64,
    required this.difficulty,
    required this.totalScore,
    required this.questions,
    required this.sourceContent,
    required this.createdAt,
  });

  /// Retourne la valeur numérique du score total
  double get totalPoints => totalScore == TotalScore.twenty ? 20.0 : 100.0;

  /// Crée un Examen à partir d'un document Firestore
  factory Exam.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exam(
      id: doc.id,
      uid: data['uid'] ?? '',
      schoolName: data['schoolName'] ?? '',
      examTitle: data['examTitle'] ?? 'Examen',
      logoBase64: data['logoBase64'],
      difficulty: ExamDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => ExamDifficulty.medium,
      ),
      totalScore: data['totalScore'] == 'hundred' 
          ? TotalScore.hundred 
          : TotalScore.twenty,
      questions: (data['questions'] as List<dynamic>?)
              ?.map((q) => ExamQuestion.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      sourceContent: data['sourceContent'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertit l'Examen pour le stockage Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'schoolName': schoolName,
      'examTitle': examTitle,
      'logoBase64': logoBase64,
      'difficulty': difficulty.name,
      'totalScore': totalScore == TotalScore.twenty ? 'twenty' : 'hundred',
      'questions': questions.map((q) => q.toMap()).toList(),
      'sourceContent': sourceContent,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

