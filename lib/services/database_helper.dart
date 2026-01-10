import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sbl_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_scrum TEXT NOT NULL,
        task_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');
  }

  // Add a task to the offline queue
  Future<int> addPendingTask(String operationScrum, Map<String, dynamic> taskData) async {
    final db = await database;
    return await db.insert('pending_tasks', {
      'operation_scrum': operationScrum,
      'task_data': jsonEncode(taskData),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  // Get all pending tasks
  Future<List<Map<String, dynamic>>> getPendingTasks() async {
    final db = await database;
    return await db.query('pending_tasks', orderBy: 'created_at ASC');
  }

  // Delete a successfully synced task
  Future<int> deletePendingTask(int id) async {
    final db = await database;
    return await db.delete('pending_tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Increment retry count
  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_tasks SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // Get pending tasks count for a specific operation
  Future<int> getPendingTasksCount(String operationScrum) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_tasks WHERE operation_scrum = ?',
      [operationScrum],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
