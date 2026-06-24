import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Veritabanı Singleton yapısı (Sürekli yeni bağlantı açmamak için)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    // Telefonun hafızasında gizli veritabanı dosyasının yolunu oluşturur
    String path = join(await getDatabasesPath(), 'qwen_chat.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Sohbet Odaları Tablosu
        await db.execute('''
          CREATE TABLE sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        
        // Mesajlar Tablosu
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER,
            is_user INTEGER,
            content TEXT,
            thinking TEXT,
            image_path TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // Yeni bir sohbet oluştur
  static Future<int> createSession(String title) async {
    final db = await database;
    return await db.insert('sessions', {'title': title});
  }

  // Geçmiş sohbetlerin listesini getir
  static Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await database;
    return await db.query('sessions', orderBy: 'created_at DESC');
  }

  // Seçilen sohbetteki mesajları getir
  static Future<List<Map<String, dynamic>>> getMessages(int sessionId) async {
    final db = await database;
    return await db.query('messages', where: 'session_id = ?', whereArgs:[sessionId], orderBy: 'id ASC');
  }

  // Yeni mesaj ekle
  static Future<int> insertMessage(int sessionId, bool isUser, String content, {String thinking = "", String? imagePath}) async {
    final db = await database;
    return await db.insert('messages', {
      'session_id': sessionId,
      'is_user': isUser ? 1 : 0,
      'content': content,
      'thinking': thinking,
      'image_path': imagePath,
    });
  }

  // Yapay zeka yazmayı bitirince mesajı güncelle
  static Future<void> updateMessage(int id, String content, String thinking) async {
    final db = await database;
    await db.update(
      'messages',
      {'content': content, 'thinking': thinking},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // YENİ EKLENEN: Seçili sohbeti ve içindeki tüm mesajları kalıcı olarak siler
  static Future<void> deleteSession(int sessionId) async {
    final db = await database;
    // Önce o sohbete ait mesajları sil, sonra sohbetin kendisini sil
    await db.delete('messages', where: 'session_id = ?', whereArgs: [sessionId]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }
}