import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: (db, version) {});
  }

  Future createChatTableForFriend(String userId, String friendId) async {
    final db = await instance.database;
    final tableName = _getChatTableName(userId, friendId);
    await db.execute('''
CREATE TABLE IF NOT EXISTS $tableName (
  id TEXT PRIMARY KEY,
  senderId TEXT NOT NULL,
  receiverId TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  isRead BOOLEAN NOT NULL
)
''');
  }

  Future<void> insertChatMessage(String userId, String friendId, Map<String, dynamic> chatMessage) async {
    final db = await instance.database;
    final tableName = _getChatTableName(userId, friendId);
    await createChatTableForFriend(userId, friendId);
    await db.insert(tableName, chatMessage);
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId, String friendId) async {
    final db = await instance.database;
    final tableName = _getChatTableName(userId, friendId);
    final result = await db.query(tableName);
    return result;
  }

  String _getChatTableName(String userId, String friendId) {
    // 简单的方法为每个好友聊天创建唯一的表名
    return 'chat_${userId}_$friendId';
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
