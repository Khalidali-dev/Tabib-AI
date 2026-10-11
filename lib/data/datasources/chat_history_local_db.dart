import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import '../../domain/domain.dart';

/// Database datasource managing persistent chat consultation history.
/// Supports full offline SQLite on mobile platforms and in-memory caching on Web/Tests.
class ChatHistoryLocalDb {
  ChatHistoryLocalDb._internal();
  static final ChatHistoryLocalDb instance = ChatHistoryLocalDb._internal();

  static const String _sessionsTable = 'chat_sessions';
  static const String _messagesTable = 'chat_messages';
  static const String _dbFileName = 'tabib_chat_history.db';
  static const int _dbVersion = 1;

  sqflite.Database? _database;
  final Map<String, ChatSession> _webSessionCache = {};

  Future<void> init() async {
    if (kIsWeb) return;
    if (_database != null && _database!.isOpen) return;

    try {
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = p.join(dbPath, _dbFileName);

      _database = await sqflite.openDatabase(
        fullPath,
        version: _dbVersion,
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onOpen: (db) async {
          await _createTables(db);
        },
      );
      debugPrint('[ChatHistoryLocalDb] SQLite chat history database initialized.');
    } catch (e) {
      debugPrint('[ChatHistoryLocalDb] Error initializing SQLite: $e');
    }
  }

  Future<void> _createTables(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_sessionsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        preview_snippet TEXT NOT NULL,
        message_count INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_messagesTable (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        sender TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES $_sessionsTable (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Retrieves all chat sessions ordered by most recently active first.
  Future<List<ChatSession>> getAllSessions() async {
    if (kIsWeb || _database == null || !_database!.isOpen) {
      final list = _webSessionCache.values.toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    }

    try {
      final rows = await _database!.query(
        _sessionsTable,
        orderBy: 'updated_at DESC',
      );

      return rows.map((r) {
        return ChatSession(
          id: r['id'] as String,
          title: r['title'] as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
          previewSnippet: r['preview_snippet'] as String,
          messageCount: r['message_count'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint('[ChatHistoryLocalDb] Error fetching sessions: $e');
      return [];
    }
  }

  /// Retrieves a specific session along with all its recorded messages.
  Future<ChatSession?> getSessionWithMessages(String sessionId) async {
    if (kIsWeb || _database == null || !_database!.isOpen) {
      return _webSessionCache[sessionId];
    }

    try {
      final sessionRows = await _database!.query(
        _sessionsTable,
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (sessionRows.isEmpty) return null;
      final s = sessionRows.first;

      final msgRows = await _database!.query(
        _messagesTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC',
      );

      final messages = msgRows.map((m) {
        final senderStr = m['sender'] as String;
        MessageSender sender = MessageSender.doctor;
        if (senderStr == 'patient') {
          sender = MessageSender.patient;
        } else if (senderStr == 'system') {
          sender = MessageSender.system;
        }

        return ChatMessage(
          id: m['id'] as String,
          sender: sender,
          content: m['content'] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
        );
      }).toList();

      return ChatSession(
        id: s['id'] as String,
        title: s['title'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(s['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(s['updated_at'] as int),
        previewSnippet: s['preview_snippet'] as String,
        messageCount: s['message_count'] as int,
        messages: messages,
      );
    } catch (e) {
      debugPrint('[ChatHistoryLocalDb] Error fetching session details: $e');
      return null;
    }
  }

  /// Saves or updates all messages for an active consultation session.
  Future<void> saveSessionMessages({
    required String sessionId,
    required String sessionTitle,
    required List<ChatMessage> messages,
  }) async {
    if (messages.isEmpty) return;

    // Filter out streaming or empty placeholder messages
    final persistentMessages = messages
        .where((m) => m.content.trim().isNotEmpty && !m.isStreaming)
        .toList();

    if (persistentMessages.isEmpty) return;

    final firstPatient = persistentMessages.firstWhere(
      (m) => m.sender == MessageSender.patient,
      orElse: () => persistentMessages.first,
    );

    final title = sessionTitle.isNotEmpty
        ? sessionTitle
        : (firstPatient.content.length > 40
            ? '${firstPatient.content.substring(0, 37)}...'
            : firstPatient.content);

    final lastMessage = persistentMessages.last;
    final snippet = lastMessage.content.length > 90
        ? '${lastMessage.content.substring(0, 87)}...'
        : lastMessage.content;

    final now = DateTime.now();

    if (kIsWeb || _database == null || !_database!.isOpen) {
      final existing = _webSessionCache[sessionId];
      _webSessionCache[sessionId] = ChatSession(
        id: sessionId,
        title: title,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        previewSnippet: snippet,
        messageCount: persistentMessages.length,
        messages: persistentMessages,
      );
      return;
    }

    try {
      await _database!.transaction((txn) async {
        // 1. Upsert session header
        await txn.insert(
          _sessionsTable,
          {
            'id': sessionId,
            'title': title,
            'created_at': persistentMessages.first.timestamp.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
            'preview_snippet': snippet,
            'message_count': persistentMessages.length,
          },
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );

        // 2. Insert or replace individual messages
        final batch = txn.batch();
        for (final msg in persistentMessages) {
          batch.insert(
            _messagesTable,
            {
              'id': msg.id,
              'session_id': sessionId,
              'sender': msg.sender.name,
              'content': msg.content,
              'timestamp': msg.timestamp.millisecondsSinceEpoch,
            },
            conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      debugPrint('[ChatHistoryLocalDb] Error persisting session messages: $e');
    }
  }

  /// Deletes a consultation session and all associated messages.
  Future<void> deleteSession(String sessionId) async {
    if (kIsWeb || _database == null || !_database!.isOpen) {
      _webSessionCache.remove(sessionId);
      return;
    }

    try {
      await _database!.delete(
        _messagesTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await _database!.delete(
        _sessionsTable,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      debugPrint('[ChatHistoryLocalDb] Error deleting session: $e');
    }
  }

  /// Clears all past consultation records.
  Future<void> clearAllSessions() async {
    if (kIsWeb || _database == null || !_database!.isOpen) {
      _webSessionCache.clear;
      return;
    }

    try {
      await _database!.delete(_messagesTable);
      await _database!.delete(_sessionsTable);
    } catch (e) {
      debugPrint('[ChatHistoryLocalDb] Error clearing history: $e');
    }
  }
}
