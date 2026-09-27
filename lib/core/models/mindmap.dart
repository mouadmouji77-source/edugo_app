import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Représente un nœud individuel dans la carte mentale (Mind Map)
class MindMapNode {
  String id; // Identifiant unique du nœud
  String label; // Texte affiché sur le nœud
  String? details; // Détails supplémentaires (optionnel)
  int level; // Niveau hiérarchique : 0=racine, 1=branches principales, 2=sous-sections, etc.
  List<MindMapNode> children; // Liste des nœuds enfants
  Offset position; // Position (x, y) du nœud sur le canevas
  Color color; // Couleur du nœud
  bool isExpanded; // Indique si les enfants sont affichés ou masqués
  bool isHighlighted; // Utilisé pour mettre en avant un nœud lors d'une recherche

  MindMapNode({
    required this.id,
    required this.label,
    this.details,
    this.level = 0,
    List<MindMapNode>? children,
    Offset? position,
    Color? color,
    this.isExpanded = true,
    this.isHighlighted = false,
  })  : children = children ?? [],
        position = position ?? Offset.zero,
        color = color ?? Colors.blue;

  /// Crée un nœud à partir d'une Map (utile pour Firestore/JSON)
  factory MindMapNode.fromMap(Map<String, dynamic> map) {
    return MindMapNode(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      details: map['details'],
      level: map['level'] ?? 0,
      children: (map['children'] as List<dynamic>?)
              ?.map((c) => MindMapNode.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      position: map['position'] != null
          ? Offset(
              (map['position']['x'] ?? 0).toDouble(),
              (map['position']['y'] ?? 0).toDouble(),
            )
          : Offset.zero,
      color: map['color'] != null ? Color(map['color']) : Colors.blue,
      isExpanded: map['isExpanded'] ?? true,
    );
  }

  /// Convertit le nœud en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'details': details,
      'level': level,
      'children': children.map((c) => c.toMap()).toList(),
      'position': {'x': position.dx, 'y': position.dy},
      'color': color.value,
      'isExpanded': isExpanded,
    };
  }

  /// Crée une copie du nœud avec des modifications optionnelles
  MindMapNode copyWith({
    String? id,
    String? label,
    String? details,
    int? level,
    List<MindMapNode>? children,
    Offset? position,
    Color? color,
    bool? isExpanded,
    bool? isHighlighted,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      label: label ?? this.label,
      details: details ?? this.details,
      level: level ?? this.level,
      children: children ?? this.children.map((c) => c.copyWith()).toList(),
      position: position ?? this.position,
      color: color ?? this.color,
      isExpanded: isExpanded ?? this.isExpanded,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  /// Calcule le nombre total de nœuds dans cette sous-arborescence
  int get totalNodes {
    return 1 + children.fold(0, (sum, child) => sum + child.totalNodes);
  }
}

/// Modèle représentant une carte mentale complète
class MindMap {
  final String id; // ID du document Firestore
  final String uid; // ID de l'utilisateur propriétaire
  final String title; // Titre de la carte mentale
  final MindMapNode rootNode; // Nœud racine de la carte
  final String? sourceText; // Texte original utilisé pour générer la carte
  final DateTime createdAt; // Date de création
  final DateTime updatedAt; // Date de dernière mise à jour

  MindMap({
    required this.id,
    required this.uid,
    required this.title,
    required this.rootNode,
    this.sourceText,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un objet MindMap à partir d'un document Firestore
  factory MindMap.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MindMap(
      id: doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      rootNode: MindMapNode.fromMap(data['rootNode'] ?? {}),
      sourceText: data['sourceText'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertit l'objet pour le stockage Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'title': title,
      'rootNode': rootNode.toMap(),
      'sourceText': sourceText,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convertit l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'rootNode': rootNode.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crée un objet MindMap à partir d'un JSON
  factory MindMap.fromJson(Map<String, dynamic> json, String uid) {
    return MindMap(
      id: json['id'] ?? '',
      uid: uid,
      title: json['title'] ?? '',
      rootNode: MindMapNode.fromMap(json['rootNode'] ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

