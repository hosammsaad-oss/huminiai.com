import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:humini_ai/models/message_model.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'humini_chat.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT,
            isUser INTEGER,
            timestamp TEXT
          )
        ''');
      },
    );
  }









  // حفظ رسالة جديدة
  Future<void> insertMessage(MessageModel msg) async {
    final dbClient = await db;
    await dbClient.insert('messages', {
      'text': msg.text,
      'isUser': msg.isUser ? 1 : 0,
      'timestamp': msg.timestamp.toIso8601String(),
    });
  }

  // استرجاع كل الرسائل
  Future<List<MessageModel>> getMessages() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query('messages', orderBy: 'timestamp ASC');
    return List.generate(maps.length, (i) {
      return MessageModel(
        text: maps[i]['text'],
        isUser: maps[i]['isUser'] == 1,
        timestamp: DateTime.parse(maps[i]['timestamp']),
      );
    });
  }

  // مسح السجل (اختياري)
  Future<void> clearChat() async {
    final dbClient = await db;
    await dbClient.delete('messages');
  }
}