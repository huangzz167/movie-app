import 'package:sqflite/sqflite.dart';

/// 数据库版本与建表 SQL 集中管理。
class AppDatabase {
  AppDatabase._();
  static const int version = 1;
  static const String dbName = 'jiguang_yingshi.db';

  /// 建表语句：观看历史、收藏、下载任务。
  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE watch_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  video_id TEXT NOT NULL,
  video_title TEXT NOT NULL,
  poster_url TEXT,
  source_name TEXT,
  played_duration INTEGER NOT NULL DEFAULT 0,
  total_duration INTEGER NOT NULL DEFAULT 0,
  episode_info TEXT,
  last_watched_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    await db.execute(
      'CREATE INDEX idx_watch_history_last ON watch_history(last_watched_at);',
    );

    await db.execute('''
CREATE TABLE favorites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  video_id TEXT NOT NULL UNIQUE,
  video_title TEXT NOT NULL,
  poster_url TEXT,
  video_type TEXT,
  year TEXT,
  rating REAL,
  source_name TEXT,
  added_at INTEGER NOT NULL
);
''');
    await db.execute('CREATE UNIQUE INDEX idx_fav_video ON favorites(video_id);');

    await db.execute('''
CREATE TABLE download_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id TEXT NOT NULL UNIQUE,
  video_id TEXT NOT NULL,
  video_title TEXT NOT NULL,
  poster_url TEXT,
  url TEXT NOT NULL,
  saved_dir TEXT,
  file_name TEXT,
  total_bytes INTEGER NOT NULL DEFAULT 0,
  downloaded_bytes INTEGER NOT NULL DEFAULT 0,
  status INTEGER NOT NULL DEFAULT 0,
  quality TEXT,
  episode_index INTEGER,
  created_at INTEGER NOT NULL,
  completed_at INTEGER
);
''');
    await db.execute('CREATE INDEX idx_dl_status ON download_tasks(status);');
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // 预留迁移逻辑
  }
}
