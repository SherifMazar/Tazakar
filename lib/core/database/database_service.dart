import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// DatabaseService - خدمة قاعدة البيانات المشفرة
/// تستخدم SQLCipher لتشفير AES-256
/// Singleton pattern - نسخة واحدة فقط في كل التطبيق
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// مفتاح التشفير - سيُستبدل بـ hardware enclave لاحقاً
  static const String _encryptionKey = 'tazakar_temp_key_change_in_production';
  static const String _dbName = 'tazakar.db';
  static const int _dbVersion = 1;

  /// الحصول على قاعدة البيانات (تفتحها إن لم تكن مفتوحة)
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// تهيئة قاعدة البيانات
  Future<Database> _initDatabase() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDir.path, _dbName);
    debugPrint('📂 Database path: $dbPath');

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // onConfigure يُنفَّذ أولاً قبل كل شيء — المكان الصحيح لتطبيق مفتاح التشفير
      onConfigure: (db) async {
        await db.rawQuery("PRAGMA key = '$_encryptionKey'");
        debugPrint('🔐 Encryption key applied');
      },
    );
  }

  /// إنشاء الجداول عند أول تشغيل
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🗄️ Creating database schema v$version...');
    await _createTables(db);
    await _seedSystemCategories(db);
    debugPrint('✅ Database schema created successfully');
  }

  /// ترقية قاعدة البيانات عند تغيير الإصدار
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('⬆️ Upgrading database from v$oldVersion to v$newVersion');
    // سنضيف migration logic لاحقاً
  }

  /// إنشاء جميع الجداول الستة
  Future<void> _createTables(Database db) async {
    // جدول الفئات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '#6366F1',
        icon TEXT NOT NULL DEFAULT 'folder',
        is_system INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // جدول التذكيرات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT,
        category_id INTEGER,
        due_at TEXT,
        is_done INTEGER NOT NULL DEFAULT 0,
        recurrence TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // جدول الوسوم (Tags)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // جدول ربط التذكيرات بالوسوم
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminder_tags (
        reminder_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (reminder_id, tag_id),
        FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // جدول قواعد التكرار
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurrence_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reminder_id INTEGER NOT NULL UNIQUE,
        frequency TEXT NOT NULL,
        interval_value INTEGER NOT NULL DEFAULT 1,
        end_date TEXT,
        FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE CASCADE
      )
    ''');

    // جدول إعدادات التطبيق
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    debugPrint('✅ All 6 tables created');
  }

  /// إضافة الفئات الافتراضية الثمانية
  Future<void> _seedSystemCategories(Database db) async {
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'General',
        'name_ar': 'عام',
        'color': '#6366F1',
        'icon': 'inbox',
        'is_system': 1,
      },
      {
        'name': 'Work',
        'name_ar': 'عمل',
        'color': '#3B82F6',
        'icon': 'work',
        'is_system': 1,
      },
      {
        'name': 'Personal',
        'name_ar': 'شخصي',
        'color': '#8B5CF6',
        'icon': 'person',
        'is_system': 1,
      },
      {
        'name': 'Health',
        'name_ar': 'صحة',
        'color': '#10B981',
        'icon': 'favorite',
        'is_system': 1,
      },
      {
        'name': 'Family',
        'name_ar': 'عائلة',
        'color': '#F59E0B',
        'icon': 'family_restroom',
        'is_system': 1,
      },
      {
        'name': 'Finance',
        'name_ar': 'مالية',
        'color': '#EF4444',
        'icon': 'account_balance',
        'is_system': 1,
      },
      {
        'name': 'Education',
        'name_ar': 'تعليم',
        'color': '#06B6D4',
        'icon': 'school',
        'is_system': 1,
      },
      {
        'name': 'Shopping',
        'name_ar': 'تسوق',
        'color': '#F97316',
        'icon': 'shopping_cart',
        'is_system': 1,
      },
    ];

    for (final category in categories) {
      await db.insert('categories', category);
    }
    debugPrint('✅ 8 system categories seeded');
  }

  /// التحقق من أن قاعدة البيانات تعمل
  Future<Map<String, dynamic>> verifyDatabase() async {
    final db = await database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    final categories = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories',
    );

    return {
      'tables': tables.map((t) => t['name']).toList(),
      'categories_count': categories.isNotEmpty ? categories.first['count'] : 0,
    };
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
