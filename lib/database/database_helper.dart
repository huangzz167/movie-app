import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import '../models/download_task.dart';
import '../models/favorite.dart';
import '../models/watch_history.dart';

/// 单例数据库助手：封装各表 CRUD、分页与条件筛选。
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, AppDatabase.dbName);
    return openDatabase(
      path,
      version: AppDatabase.version,
      onCreate: AppDatabase.onCreate,
      onUpgrade: AppDatabase.onUpgrade,
    );
  }

  // --- watch_history ---

  Future<int> insertWatchHistory(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('watch_history', row);
  }

  Future<int> updateWatchHistory(int id, Map<String, dynamic> row) async {
    final db = await database;
    return db.update(
      'watch_history',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> upsertWatchHistoryByVideoId({
    required String videoId,
    required Map<String, dynamic> row,
  }) async {
    final db = await database;
    final list = await db.query(
      'watch_history',
      where: 'video_id = ?',
      whereArgs: [videoId],
      limit: 1,
    );
    if (list.isEmpty) {
      return db.insert('watch_history', row);
    }
    final id = list.first['id'] as int;
    final merged = Map<String, dynamic>.from(list.first);
    merged.addAll(row);
    merged['id'] = id;
    return db.update(
      'watch_history',
      merged,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<WatchHistory>> queryWatchHistory({
    int offset = 0,
    int limit = 50,
    String? videoId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'watch_history',
      where: videoId != null ? 'video_id = ?' : null,
      whereArgs: videoId != null ? [videoId] : null,
      orderBy: 'last_watched_at DESC',
      offset: offset,
      limit: limit,
    );
    return rows.map(WatchHistory.fromMap).toList();
  }

  Future<int> deleteWatchHistory(int id) async {
    final db = await database;
    return db.delete('watch_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteWatchHistoryByVideoId(String videoId) async {
    final db = await database;
    return db.delete(
      'watch_history',
      where: 'video_id = ?',
      whereArgs: [videoId],
    );
  }

  Future<int> clearWatchHistory() async {
    final db = await database;
    return db.delete('watch_history');
  }

  Future<int> batchDeleteWatchHistory(List<int> ids) async {
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete('watch_history', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    return ids.length;
  }

  // --- favorites ---

  Future<int> insertFavorite(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('favorites', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteFavoriteByVideoId(String videoId) async {
    final db = await database;
    return db.delete('favorites', where: 'video_id = ?', whereArgs: [videoId]);
  }

  Future<FavoriteItem?> getFavoriteByVideoId(String videoId) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      where: 'video_id = ?',
      whereArgs: [videoId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FavoriteItem.fromMap(rows.first);
  }

  Future<List<FavoriteItem>> queryFavorites({
    int offset = 0,
    int limit = 100,
    String? videoType,
  }) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      where: videoType != null ? 'video_type = ?' : null,
      whereArgs: videoType != null ? [videoType] : null,
      orderBy: 'added_at DESC',
      offset: offset,
      limit: limit,
    );
    return rows.map(FavoriteItem.fromMap).toList();
  }

  Future<int> countFavorites() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM favorites');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> batchDeleteFavorites(List<String> videoIds) async {
    final db = await database;
    final batch = db.batch();
    for (final id in videoIds) {
      batch.delete('favorites', where: 'video_id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    return videoIds.length;
  }

  // --- download_tasks ---

  Future<int> insertDownloadTask(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('download_tasks', row);
  }

  Future<int> updateDownloadTaskByTaskId(
    String taskId,
    Map<String, dynamic> row,
  ) async {
    final db = await database;
    return db.update(
      'download_tasks',
      row,
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<DownloadTaskRow>> queryDownloadTasks({
    int? statusEquals,
    int offset = 0,
    int limit = 200,
  }) async {
    final db = await database;
    final rows = await db.query(
      'download_tasks',
      where: statusEquals != null ? 'status = ?' : null,
      whereArgs: statusEquals != null ? [statusEquals] : null,
      orderBy: 'created_at DESC',
      offset: offset,
      limit: limit,
    );
    return rows.map(DownloadTaskRow.fromMap).toList();
  }

  Future<DownloadTaskRow?> getDownloadByTaskId(String taskId) async {
    final db = await database;
    final rows = await db.query(
      'download_tasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DownloadTaskRow.fromMap(rows.first);
  }

  Future<int> deleteDownloadTask(String taskId) async {
    final db = await database;
    return db.delete(
      'download_tasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> batchDeleteDownloadTasks(List<String> taskIds) async {
    final db = await database;
    final batch = db.batch();
    for (final id in taskIds) {
      batch.delete('download_tasks', where: 'task_id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    return taskIds.length;
  }
}
