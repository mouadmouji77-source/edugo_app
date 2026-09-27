import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un Résumé généré par l'IA
class Summary {
  final String id; // ID du document Firestore
  final String uid; // ID de l'utilisateur propriétaire
  final String title; // Titre du résumé
  final String? originalText; // Texte source original (optionnel)
  final String content; // Contenu du résumé généré
  final List<String> keywords; // Liste des mots-clés extraits
  final DateTime createdAt; // Date de création
  final String? pdfUrl; // URL du fichier PDF associé (optionnel)

  const Summary({
    required this.id,
    required this.uid,
    required this.title,
    this.originalText,
    required this.content,
    required this.keywords,
    required this.createdAt,
    this.pdfUrl,
  });

  /// Crée un Résumé à partir d'un document Firestore
  factory Summary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Summary(
      id: doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      originalText: data['originalText'],
      content: data['content'] ?? '',
      keywords: List<String>.from(data['keywords'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      pdfUrl: data['pdfUrl'],
    );
  }

  /// Convertit le Résumé pour le stockage Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'title': title,
      if (originalText != null) 'originalText': originalText,
      'content': content,
      'keywords': keywords,
      'createdAt': Timestamp.fromDate(createdAt),
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
    };
  }

  /// Crée une copie du résumé avec des modifications optionnelles
  Summary copyWith({
    String? id,
    String? uid,
    String? title,
    String? originalText,
    String? content,
    List<String>? keywords,
    DateTime? createdAt,
    String? pdfUrl,
  }) {
    return Summary(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      originalText: originalText ?? this.originalText,
      content: content ?? this.content,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }
}
