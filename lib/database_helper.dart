import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'digital_detox.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT UNIQUE,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            full_name TEXT NOT NULL,
            phone_number TEXT,
            date_of_birth TEXT,
            age INTEGER,
            gender TEXT,
            screen_time_limit REAL,
            created_at TEXT NOT NULL,
            synced_with_firebase INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE user_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            email TEXT,
            login_time TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE moods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood TEXT NOT NULL,
            time TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS user_sessions');
          await db.execute('DROP TABLE IF EXISTS users');

          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uid TEXT UNIQUE,
              email TEXT UNIQUE NOT NULL,
              password_hash TEXT NOT NULL,
              full_name TEXT NOT NULL,
              phone_number TEXT,
              date_of_birth TEXT,
              age INTEGER,
              gender TEXT,
              screen_time_limit REAL,
              created_at TEXT NOT NULL,
              synced_with_firebase INTEGER DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE user_sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              email TEXT,
              login_time TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS moods (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              mood TEXT NOT NULL,
              time TEXT NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>?> createUser({
    required String email,
    required String password,
    required UserProfile userProfile,
  }) async {
    try {
      final db = await database;

      List<Map<String, dynamic>> existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUser.isNotEmpty) {
        throw Exception('User with this email already exists');
      }

      String uid = 'local_${DateTime.now().millisecondsSinceEpoch}';

      String passwordHash = _hashPassword(password);

      int userId = await db.insert('users', {
        'uid': uid,
        'email': email,
        'password_hash': passwordHash,
        'full_name': userProfile.fullName,
        'phone_number': userProfile.phoneNumber,
        'date_of_birth': userProfile.dateOfBirth,
        'age': userProfile.age,
        'gender': userProfile.gender,
        'screen_time_limit': userProfile.screenTimeLimit,
        'created_at': DateTime.now().toIso8601String(),
        'synced_with_firebase': 0,
      });

      return {
        'id': userId,
        'uid': uid,
        'email': email,
        'full_name': userProfile.fullName,
        'created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;
      String passwordHash = _hashPassword(password);

      List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email, passwordHash],
      );

      if (users.isEmpty) {
        return null; 
      }

      Map<String, dynamic> user = users.first;

      await db.insert('user_sessions', {
        'user_id': user['id'],
        'email': email,
        'login_time': DateTime.now().toIso8601String(),
      });

      return {
        'id': user['id'],
        'uid': user['uid'],
        'email': user['email'],
        'full_name': user['full_name'],
        'phone_number': user['phone_number'],
        'age': user['age'],
        'gender': user['gender'],
        'screen_time_limit': user['screen_time_limit'],
      };
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final db = await database;
      List<Map<String, dynamic>> sessions = await db.query(
        'user_sessions',
        orderBy: 'login_time DESC',
        limit: 1,
      );

      if (sessions.isEmpty) return null;

      String email = sessions.first['email'];
      List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.trim().toLowerCase()],
      );

      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      return null;
    }
  }
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'phone_number = ?',
        whereArgs: [phone.trim()],
      );

      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserPassword(int userId, String newPassword) async {
    try {
      final db = await database;
      String passwordHash = _hashPassword(newPassword);

      await db.update(
        'users',
        {'password_hash': passwordHash},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLoginHistory(String email) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> sessions = await db.query(
        'user_sessions',
        where: 'email = ?',
        whereArgs: [email],
        orderBy: 'login_time DESC',
        limit: 10,
      );
      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<void> logout() async {
    try {
      final db = await database;
      await db.delete('user_sessions');
    } catch (e) {
      // Debug: Logout error
    }
  }

  Future<void> syncWithFirebase() async {
    try {
      final db = await database;
      final unsyncedUsers = await db.query(
        'users',
        where: 'synced_with_firebase = ?',
        whereArgs: [0],
      );
      if (unsyncedUsers.isNotEmpty) {
        // Debug: Would sync ${unsyncedUsers.length} users to Firebase
      }
    } catch (e) {
      // Debug: Firebase sync error
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // Mood Tracker methods
  Future<void> insertMood(Map<String, dynamic> moodData) async {
    final db = await database;
    await db.insert(
      'moods', 
      moodData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMoods() async {
    final db = await database;
    return await db.query('moods', orderBy: 'timestamp DESC');
  }
}
