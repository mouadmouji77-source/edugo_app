import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/models/mindmap.dart';
import '../../../../services/firebase_service.dart';
import '../../../../services/ai_service.dart';
import '../../../../features/auth/providers/auth_providers.dart';

/// Provider qui récupère la liste des cartes mentales de l'utilisateur
final userMindMapsProvider = StreamProvider<List<MindMap>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return FirebaseService.mindmaps
      .where('uid', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final mindmaps = snapshot.docs.map((doc) => MindMap.fromFirestore(doc)).toList();
        // Tri par date de mise à jour (plus récent en premier)
        mindmaps.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return mindmaps;
      });
});

/// Provider qui récupère une carte mentale spécifique par son ID
final mindMapProvider = StreamProvider.family<MindMap?, String>((ref, id) {
  return FirebaseService.mindmaps
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? MindMap.fromFirestore(doc) : null);
});

/// Provider pour accéder au contrôleur des cartes mentales
final mindMapControllerProvider = Provider<MindMapController>((ref) {
  return MindMapController(ref);
});

/// Contrôleur gérant la logique métier des cartes mentales
class MindMapController {
  final Ref _ref;
  final _uuid = const Uuid();

  MindMapController(this._ref);

  /// Génère une nouvelle carte mentale à partir d'un texte via l'IA
  Future<MindMap> generateFromText(String text, {String? title}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('Utilisateur non authentifié');

    try {
      // Appel au service IA pour générer la structure
      final rootNode = await AiService.generateMindMap(text, title: title);
      
      final mindMap = MindMap(
        id: _uuid.v4(),
        uid: user.uid,
        title: title ?? rootNode.label,
        rootNode: rootNode,
        sourceText: text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sauvegarde dans Firestore
      await FirebaseService.mindmaps.doc(mindMap.id).set(mindMap.toFirestore());
      
      return mindMap;
    } catch (e) {
      throw Exception('Échec de la génération de la carte mentale : $e');
    }
  }

  /// Sauvegarde une carte mentale existante
  Future<void> saveMindMap(MindMap mindMap) async {
    await FirebaseService.mindmaps.doc(mindMap.id).set(mindMap.toFirestore());
  }

  /// Supprime une carte mentale
  Future<void> deleteMindMap(String id) async {
    await FirebaseService.mindmaps.doc(id).delete();
  }

  /// Exporte la carte mentale au format JSON
  Future<String> exportAsJson(MindMap mindMap) async {
    return jsonEncode(mindMap.toJson());
  }

  /// Importe une carte mentale depuis un JSON
  Future<MindMap> importFromJson(String jsonString) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('Utilisateur non authentifié');

    final json = jsonDecode(jsonString);
    final mindMap = MindMap.fromJson(json, user.uid);
    
    final newMindMap = MindMap(
      id: _uuid.v4(),
      uid: user.uid,
      title: mindMap.title,
      rootNode: mindMap.rootNode,
      sourceText: mindMap.sourceText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await FirebaseService.mindmaps.doc(newMindMap.id).set(newMindMap.toFirestore());
    return newMindMap;
  }

  Future<void> exportAsPdf(MindMap mindMap) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  mindMap.title,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildPdfNode(mindMap.rootNode, 0),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  pw.Widget _buildPdfNode(MindMapNode node, int depth) {
    return pw.Container(
      margin: pw.EdgeInsets.only(left: depth * 20.0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            margin: const pw.EdgeInsets.only(bottom: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  node.label,
                  style: pw.TextStyle(
                    fontSize: 14 - depth * 1.0,
                    fontWeight: depth == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                ),
                if (node.details != null && node.details!.isNotEmpty)
                  pw.Text(
                    node.details!,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
              ],
            ),
          ),
          ...node.children.map((child) => _buildPdfNode(child, depth + 1)),
        ],
      ),
    );
  }
}

// State notifier for managing the current mindmap being edited
class MindMapEditorNotifier extends Notifier<MindMap?> {
  @override
  MindMap? build() => null;

  void setMindMap(MindMap mindMap) {
    state = mindMap;
  }

  void updateNode(String nodeId, {String? label, String? details}) {
    final currentState = state;
    if (currentState == null) return;
    
    MindMapNode updateNodeRecursive(MindMapNode node) {
      if (node.id == nodeId) {
        return node.copyWith(
          label: label ?? node.label,
          details: details ?? node.details,
        );
      }
      return node.copyWith(
        children: node.children.map((c) => updateNodeRecursive(c)).toList(),
      );
    }
    
    state = MindMap(
      id: currentState.id,
      uid: currentState.uid,
      title: currentState.title,
      rootNode: updateNodeRecursive(currentState.rootNode),
      sourceText: currentState.sourceText,
      createdAt: currentState.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void addChild(String parentId, MindMapNode newNode) {
    final currentState = state;
    if (currentState == null) return;
    
    MindMapNode addChildRecursive(MindMapNode node) {
      if (node.id == parentId) {
        return node.copyWith(
          children: [...node.children, newNode],
        );
      }
      return node.copyWith(
        children: node.children.map((c) => addChildRecursive(c)).toList(),
      );
    }
    
    state = MindMap(
      id: currentState.id,
      uid: currentState.uid,
      title: currentState.title,
      rootNode: addChildRecursive(currentState.rootNode),
      sourceText: currentState.sourceText,
      createdAt: currentState.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void deleteNode(String nodeId) {
    final currentState = state;
    if (currentState == null) return;
    if (currentState.rootNode.id == nodeId) return; // Can't delete root
    
    MindMapNode deleteNodeRecursive(MindMapNode node) {
      return node.copyWith(
        children: node.children
            .where((c) => c.id != nodeId)
            .map((c) => deleteNodeRecursive(c))
            .toList(),
      );
    }
    
    state = MindMap(
      id: currentState.id,
      uid: currentState.uid,
      title: currentState.title,
      rootNode: deleteNodeRecursive(currentState.rootNode),
      sourceText: currentState.sourceText,
      createdAt: currentState.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void toggleExpanded(String nodeId) {
    final currentState = state;
    if (currentState == null) return;
    
    MindMapNode toggleRecursive(MindMapNode node) {
      if (node.id == nodeId) {
        return node.copyWith(isExpanded: !node.isExpanded);
      }
      return node.copyWith(
        children: node.children.map((c) => toggleRecursive(c)).toList(),
      );
    }
    
    state = MindMap(
      id: currentState.id,
      uid: currentState.uid,
      title: currentState.title,
      rootNode: toggleRecursive(currentState.rootNode),
      sourceText: currentState.sourceText,
      createdAt: currentState.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void clear() {
    state = null;
  }
}

final mindMapEditorProvider = NotifierProvider<MindMapEditorNotifier, MindMap?>(() {
  return MindMapEditorNotifier();
});

