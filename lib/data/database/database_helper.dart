import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/stage_result.dart';

/// SQLite database helper for conversation and settings storage.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, DatabaseConfig.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConfig.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT,
        stage1_json TEXT,
        stage2_json TEXT,
        stage3_json TEXT,
        metadata_json TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    // App settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_messages_conversation ON messages(conversation_id)');
    await db.execute(
        'CREATE INDEX idx_conversations_updated ON conversations(updated_at DESC)');
  }

  // ============ Conversation Operations ============

  Future<Conversation> createConversation({String? id}) async {
    final db = await database;
    final conversation = Conversation.create(id: id);

    await db.insert('conversations', {
      'id': conversation.id,
      'title': conversation.title,
      'created_at': conversation.createdAt.toIso8601String(),
      'updated_at': conversation.updatedAt.toIso8601String(),
    });

    return conversation;
  }

  Future<Conversation?> getConversation(String id) async {
    final db = await database;
    final results = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final row = results.first;
    final messageCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM messages WHERE conversation_id = ?',
          [id],
        )) ??
        0;

    return Conversation(
      id: row['id'] as String,
      title: row['title'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      messageCount: messageCount,
    );
  }

  Future<List<Conversation>> listConversations() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT c.*, COUNT(m.id) as message_count
      FROM conversations c
      LEFT JOIN messages m ON c.id = m.conversation_id
      GROUP BY c.id
      ORDER BY c.updated_at DESC
    ''');

    return results
        .map((row) => Conversation(
              id: row['id'] as String,
              title: row['title'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              messageCount: (row['message_count'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<void> updateConversationTitle(String id, String title) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'title': title,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Message Operations ============

  Future<Message> addUserMessage(String conversationId, String content) async {
    final db = await database;
    final now = DateTime.now();

    final id = await db.insert('messages', {
      'conversation_id': conversationId,
      'role': 'user',
      'content': content,
      'created_at': now.toIso8601String(),
    });

    // Update conversation timestamp
    await db.update(
      'conversations',
      {'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return Message(
      id: id,
      conversationId: conversationId,
      role: 'user',
      content: content,
      createdAt: now,
    );
  }

  Future<Message> addAssistantMessage({
    required String conversationId,
    required List<ModelResponseResult> stage1,
    required List<RankingResult> stage2,
    required SynthesisResult stage3,
    required CouncilMetadata metadata,
  }) async {
    final db = await database;
    final now = DateTime.now();

    final id = await db.insert('messages', {
      'conversation_id': conversationId,
      'role': 'assistant',
      'stage1_json': jsonEncode(stage1.map((r) => r.toJson()).toList()),
      'stage2_json': jsonEncode(stage2.map((r) => r.toJson()).toList()),
      'stage3_json': jsonEncode(stage3.toJson()),
      'metadata_json': jsonEncode(metadata.toJson()),
      'created_at': now.toIso8601String(),
    });

    // Update conversation timestamp
    await db.update(
      'conversations',
      {'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return Message(
      id: id,
      conversationId: conversationId,
      role: 'assistant',
      stage1: stage1,
      stage2: stage2,
      stage3: stage3,
      metadata: metadata,
      createdAt: now,
    );
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return results.map((row) {
      final role = row['role'] as String;

      if (role == 'user') {
        return Message(
          id: row['id'] as int,
          conversationId: conversationId,
          role: role,
          content: row['content'] as String?,
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      } else {
        // Parse stage data
        final stage1Json = row['stage1_json'] as String?;
        final stage2Json = row['stage2_json'] as String?;
        final stage3Json = row['stage3_json'] as String?;
        final metadataJson = row['metadata_json'] as String?;

        return Message(
          id: row['id'] as int,
          conversationId: conversationId,
          role: role,
          stage1: stage1Json != null
              ? (jsonDecode(stage1Json) as List)
                  .map((r) => ModelResponseResult.fromJson(r))
                  .toList()
              : null,
          stage2: stage2Json != null
              ? (jsonDecode(stage2Json) as List)
                  .map((r) => RankingResult.fromJson(r))
                  .toList()
              : null,
          stage3: stage3Json != null
              ? SynthesisResult.fromJson(jsonDecode(stage3Json))
              : null,
          metadata: metadataJson != null
              ? CouncilMetadata.fromJson(jsonDecode(metadataJson))
              : null,
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      }
    }).toList();
  }

  // ============ Settings Operations ============

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  // ============ Utility ============

  Future<void> clearAllConversations() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('conversations');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('conversations');
    await db.delete('app_settings');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
