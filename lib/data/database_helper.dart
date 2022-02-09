import 'dart:async';

import 'package:background_location/common/constant.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static DatabaseHelper? _databaseHelper;
  DatabaseHelper._instance() {
    _databaseHelper = this;
  }

  factory DatabaseHelper() => _databaseHelper ?? DatabaseHelper._instance();

  static Database? _database;

  Future<Database?> get database async {
    _database ??= await _initDb();
    return _database;
  }

  Future<Database> _initDb() async {
    final path = await getDatabasesPath();
    final databasePath = '$path/trackticket.db';

    var db = await openDatabase(databasePath, version: 1, onCreate: _onCreate);
    return db;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${TableName.ticket} (
        id INTEGER PRIMARY KEY,
        title TEXT,
        description TEXT,
        arrival_status TEXT,
        ticket_status TEXT,
      );
    ''');
    await db.execute('''
      CREATE TABLE ${TableName.checklist} (
        id INTEGER PRIMARY KEY,
        title TEXT,
        type TEXT,
        time TEXT,
        status TEXT,
        ticket_id INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE ${TableName.history} (
        id INTEGER PRIMARY KEY,
        action TEXT,
        time TEXT,
        latitude TEXT,
        longitude TEXT,
        ticket_id INTEGER
      );
    ''');
  }

  Future<int> insertData(String table, Map<String, dynamic> value) async {
    final db = await database;
    return await db!.insert(table, value);
  }

  Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db!.query(table);

    return results;
  }

  Future<Map<String, dynamic>?> getDataById(String table, int id) async {
    final db = await database;
    final results = await db!.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getDataByQuery(
    String table, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    final db = await database;
    final results = await db!.query(
      table,
      where: where,
      whereArgs: whereArgs,
    );

    if (results.isNotEmpty) {
      return results;
    } else {
      return null;
    }
  }

  Future<int> updateData(
    String table,
    Map<String, dynamic> value,
    int id,
  ) async {
    final db = await database;
    return await db!.update(
      table,
      value,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> removeData(String table, int id) async {
    final db = await database;
    return await db!.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> removeDataByQuery(
    String table, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    final db = await database;
    return await db!.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
}
