import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/models/exam.dart';
import '../core/models/mindmap.dart';
import '../core/models/quiz.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../config/api_keys.dart';

/// Service gérant toutes les interactions avec l'IA (Groq API)
/// Ce service permet de générer des résumés, des quiz, des examens et des cartes mentales (Mind Maps).
class AiService {
  
  /// Méthode privée pour appeler l'API Groq
  /// [prompt] : Le texte envoyé à l'IA
  /// [temperature] : Contrôle la créativité de l'IA (0.0 = factuel, 1.0 = créatif)
  static Future<String> _callGroqAPI(String prompt, {double temperature = 0.7}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiKeys.groqBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
        },
        body: jsonEncode({
          'model': ApiKeys.groqModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Erreur API Groq: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'appel à l\'API Groq: $e');
    }
  }

  /// Génère un résumé complet à partir d'un texte source
  /// L'IA détecte automatiquement la langue et répond dans la même langue.
  static Future<String> generateSummary(String text) async {
    try {
      final prompt = '''Génère un résumé complet du texte suivant. 
Le résumé doit être clair, concis et capturer tous les points clés.
IMPORTANT: Écris le résumé dans la MÊME LANGUE que le texte d'entrée.

Texte:
$text

Résumé:''';

      return await _callGroqAPI(prompt, temperature: 0.5);
    } catch (e) {
      throw Exception('Erreur lors de la génération du résumé: $e');
    }
  }

  /// Extrait les mots-clés les plus importants d'un texte
  static Future<List<String>> extractKeywords(String text) async {
    try {
      final prompt = '''Extrait les mots-clés les plus importants du texte suivant.
Retourne UNIQUEMENT un tableau JSON de chaînes de caractères.
Exemple: ["mot1", "mot2", "mot3"]

Texte:
$text

Mots-clés (JSON uniquement):''';

      final response = await _callGroqAPI(prompt, temperature: 0.3);
      
      // Extraction du JSON de la réponse de l'IA
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final List<dynamic> keywords = jsonDecode(jsonStr);
        return keywords.map((k) => k.toString()).toList();
      }
      
      // Solution de secours si le JSON échoue
      return response
          .replaceAll(RegExp(r'[\[\]"]'), '')
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de l\'extraction des mots-clés: $e');
    }
  }

  /// Génère un quiz à choix multiples à partir d'un texte
  static Future<List<QuizQuestion>> generateQuiz(String summaryText, {int numberOfQuestions = 5}) async {
    try {
      final prompt = '''À partir du texte suivant, génère $numberOfQuestions questions de quiz à choix multiples.
IMPORTANT: Génère les questions dans la MÊME LANGUE que le texte d'entrée.
Retourne UNIQUEMENT un tableau JSON valide avec cette structure exacte:
[
  {
    "question": "Texte de la question ?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": 0
  }
]

Texte:
$summaryText

Tableau JSON:''';

      final response = await _callGroqAPI(prompt, temperature: 0.7);
      
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('Réponse JSON invalide de Groq');
      }
      
      final jsonStr = jsonMatch.group(0)!;
      final List<dynamic> questionsData = jsonDecode(jsonStr);
      
      return questionsData
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la génération du quiz: $e');
    }
  }

  /// Extrait le texte d'un fichier PDF en utilisant Syncfusion
  static Future<String> extractTextFromPdf(Uint8List pdfBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final StringBuffer extractedText = StringBuffer();
      
      for (int i = 0; i < document.pages.count; i++) {
        final String pageText = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        extractedText.writeln(pageText);
      }
      
      document.dispose();
      final text = extractedText.toString().trim();
      
      if (text.isEmpty) {
        throw Exception('Aucun texte n\'a pu être extrait du PDF. Il s\'agit peut-être d\'un scan ou d\'un fichier protégé.');
      }
      
      return text;
    } catch (e) {
      throw Exception('Erreur lors de l\'extraction du texte PDF: $e');
    }
  }

  /// Génère des questions d'examen structurées (Essai, Réponse courte, Problème)
  static Future<List<ExamQuestion>> generateExamQuestions({
    required String content,
    required ExamDifficulty difficulty,
    required TotalScore totalScore,
    required int numberOfQuestions,
  }) async {
    try {
      final difficultyText = difficulty == ExamDifficulty.easy ? 'facile' : 
                            difficulty == ExamDifficulty.medium ? 'moyen' : 'difficile';
      final totalScoreValue = totalScore == TotalScore.twenty ? 20 : 100;
      
      final prompt = '''Génère $numberOfQuestions questions d'examen basées sur le contenu suivant.
Niveau de difficulté: $difficultyText
Score total: $totalScoreValue points

Retourne UNIQUEMENT un tableau JSON avec cette structure:
[
  {
    "question": "Texte de la question ?",
    "points": 5,
    "type": "essay"
  }
]
Types possibles: "essay", "short_answer", "problem_solving"

Contenu:
$content

Tableau JSON:''';

      final response = await _callGroqAPI(prompt, temperature: 0.7);
      
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('Réponse JSON invalide de Groq');
      }
      
      final jsonStr = jsonMatch.group(0)!;
      final List<dynamic> questionsData = jsonDecode(jsonStr);
      
      return questionsData.map((q) => ExamQuestion.fromMap({
        ...q as Map<String, dynamic>,
        'difficulty': difficulty.name,
      })).toList();
    } catch (e) {
      throw Exception('Erreur lors de la génération de l\'examen: $e');
    }
  }

  /// Génère une structure hiérarchique pour une carte mentale (Mind Map)
  static Future<MindMapNode> generateMindMap(String text, {String? title}) async {
    try {
      final prompt = '''Crée une carte mentale hiérarchique à partir du texte suivant.
IMPORTANT: Écris la carte mentale dans la MÊME LANGUE que le texte d'entrée.
Retourne UNIQUEMENT un objet JSON avec cette structure:
{
  "title": "Sujet Principal",
  "children": [
    {
      "title": "Sous-thème 1",
      "children": [
        {"title": "Détail 1", "children": []}
      ]
    }
  ]
}

Texte:
$text

Objet JSON:''';

      final response = await _callGroqAPI(prompt, temperature: 0.6);
      
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('Réponse JSON invalide de Groq');
      }
      
      final jsonStr = jsonMatch.group(0)!;
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      return _parseMindMapNode(data, 0);
    } catch (e) {
      throw Exception('Erreur lors de la génération de la carte mentale: $e');
    }
  }

  /// Aide récursive pour transformer le JSON de l'IA en objets MindMapNode
  /// Gère également l'attribution des couleurs par branche.
  static MindMapNode _parseMindMapNode(Map<String, dynamic> data, int level, {Color? branchColor}) {
    final String label = data['title'] ?? data['label'] ?? 'Nouveau Nœud';
    final List<dynamic> childrenData = data['children'] ?? [];
    
    Color nodeColor;
    if (level == 0) {
      nodeColor = Colors.blue.shade700; // Couleur du nœud racine
    } else if (level == 1) {
      // Couleurs distinctes pour les branches principales
      final colors = [
        Colors.green.shade600,
        Colors.orange.shade600,
        Colors.purple.shade600,
        Colors.teal.shade600,
        Colors.pink.shade600,
        Colors.indigo.shade600,
      ];
      nodeColor = colors[DateTime.now().millisecond % colors.length];
    } else {
      // Les sous-nœuds héritent de la couleur de leur branche parente
      nodeColor = branchColor ?? Colors.grey.shade600;
    }

    final List<MindMapNode> children = childrenData.map((child) {
      return _parseMindMapNode(
        child as Map<String, dynamic>, 
        level + 1,
        branchColor: nodeColor,
      );
    }).toList();

    return MindMapNode(
      // Génération d'un ID unique basé sur le temps, le niveau et le contenu
      id: 'node-${DateTime.now().millisecondsSinceEpoch}-${level}-${label.hashCode}-${childrenData.length}',
      label: label,
      level: level,
      children: children,
      color: nodeColor,
      isExpanded: true,
    );
  }
}
