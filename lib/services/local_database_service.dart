import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _dbName = 'edugo_offline.db';
  static const int _dbVersion = 1;

  // Tables
  static const String tableSummaries = 'saved_summaries';
  static const String tableQuizzes = 'saved_quizzes';

  // Initialize database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // For web, use databaseFactoryFfiWeb
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Initialize FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Saved summaries table
    await db.execute('''
      CREATE TABLE $tableSummaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        originalText TEXT,
        summaryContent TEXT NOT NULL,
        keywords TEXT,
        language TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isFavorite INTEGER DEFAULT 0
      )
    ''');

    // Saved quizzes table
    await db.execute('''
      CREATE TABLE $tableQuizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        questionsJson TEXT NOT NULL,
        score INTEGER,
        totalQuestions INTEGER,
        createdAt TEXT NOT NULL,
        completedAt TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations here
  }

  // ==================== SUMMARIES ====================

  // Save a summary
  static Future<int> saveSummary({
    required String title,
    String? originalText,
    required String summaryContent,
    List<String>? keywords,
    String? language,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert(tableSummaries, {
      'title': title,
      'originalText': originalText,
      'summaryContent': summaryContent,
      'keywords': keywords?.join(','),
      'language': language,
      'createdAt': now,
      'updatedAt': now,
      'isFavorite': 0,
    });
  }

  // Get all summaries
  static Future<List<SavedSummary>> getAllSummaries() async {
    final db = await database;
    final maps = await db.query(
      tableSummaries,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => SavedSummary.fromMap(map)).toList();
  }

  // Get a summary by ID
  static Future<SavedSummary?> getSummaryById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableSummaries,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SavedSummary.fromMap(maps.first);
  }

  // Update a summary
  static Future<int> updateSummary(int id, {
    String? title,
    String? summaryContent,
    bool? isFavorite,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (summaryContent != null) updates['summaryContent'] = summaryContent;
    if (isFavorite != null) updates['isFavorite'] = isFavorite ? 1 : 0;

    return await db.update(
      tableSummaries,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a summary
  static Future<int> deleteSummary(int id) async {
    final db = await database;
    return await db.delete(
      tableSummaries,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Toggle favorite
  static Future<void> toggleFavorite(int id) async {
    final db = await database;
    final summary = await getSummaryById(id);
    if (summary != null) {
      await updateSummary(id, isFavorite: !summary.isFavorite);
    }
  }

  // Search summaries
  static Future<List<SavedSummary>> searchSummaries(String query) async {
    final db = await database;
    final maps = await db.query(
      tableSummaries,
      where: 'title LIKE ? OR summaryContent LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => SavedSummary.fromMap(map)).toList();
  }

  // Count saved summaries
  static Future<int> getSummariesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableSummaries');
    return result.first['count'] as int;
  }

  // ==================== QUIZ ====================

  // Save a quiz
  static Future<int> saveQuiz({
    required String title,
    required String questionsJson,
    int? score,
    int? totalQuestions,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert(tableQuizzes, {
      'title': title,
      'questionsJson': questionsJson,
      'score': score,
      'totalQuestions': totalQuestions,
      'createdAt': now,
      'completedAt': score != null ? now : null,
    });
  }

  // Get all quizzes
  static Future<List<SavedQuiz>> getAllQuizzes() async {
    final db = await database;
    final maps = await db.query(
      tableQuizzes,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => SavedQuiz.fromMap(map)).toList();
  }

  // Delete a quiz
  static Future<int> deleteQuiz(int id) async {
    final db = await database;
    return await db.delete(
      tableQuizzes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// ==================== MODELS ====================

class SavedSummary {
  final int id;
  final String title;
  final String? originalText;
  final String summaryContent;
  final List<String> keywords;
  final String? language;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  SavedSummary({
    required this.id,
    required this.title,
    this.originalText,
    required this.summaryContent,
    required this.keywords,
    this.language,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
  });

  factory SavedSummary.fromMap(Map<String, dynamic> map) {
    return SavedSummary(
      id: map['id'] as int,
      title: map['title'] as String,
      originalText: map['originalText'] as String?,
      summaryContent: map['summaryContent'] as String,
      keywords: (map['keywords'] as String?)?.split(',') ?? [],
      language: map['language'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isFavorite: (map['isFavorite'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'originalText': originalText,
      'summaryContent': summaryContent,
      'keywords': keywords.join(','),
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }
}

class SavedQuiz {
  final int id;
  final String title;
  final String questionsJson;
  final int? score;
  final int? totalQuestions;
  final DateTime createdAt;
  final DateTime? completedAt;

  SavedQuiz({
    required this.id,
    required this.title,
    required this.questionsJson,
    this.score,
    this.totalQuestions,
    required this.createdAt,
    this.completedAt,
  });

  factory SavedQuiz.fromMap(Map<String, dynamic> map) {
    return SavedQuiz(
      id: map['id'] as int,
      title: map['title'] as String,
      questionsJson: map['questionsJson'] as String,
      score: map['score'] as int?,
      totalQuestions: map['totalQuestions'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt'] as String) 
          : null,
    );
  }
}

