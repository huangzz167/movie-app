import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

/// 存储统计：图片缓存、已下载视频占用、清理。
class StorageService {
  StorageService(this._db);

  final DatabaseHelper _db;

  /// 统计临时目录下图片相关缓存体积（含 cached_network_image 常见目录）
  Future<int> imageCacheBytes() async {
    final tmp = await getTemporaryDirectory();
    final paths = <Directory>[
      Directory('${tmp.path}/libCachedImageData'),
    ];
    var total = 0;
    for (final d in paths) {
      if (await d.exists()) {
        total += await _dirSize(d);
      }
    }
    return total;
  }

  Future<int> downloadedVideosBytes() async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory('${dir.path}/jgy_downloads');
    if (!await d.exists()) return 0;
    return _dirSize(d);
  }

  Future<void> clearImageCache() async {
    await DefaultCacheManager().emptyCache();
    final tmp = await getTemporaryDirectory();
    final d = Directory('${tmp.path}/libCachedImageData');
    if (await d.exists()) {
      await d.delete(recursive: true);
    }
  }

  Future<void> clearDownloadedVideos() async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory('${dir.path}/jgy_downloads');
    if (await d.exists()) {
      await d.delete(recursive: true);
    }
    final rows = await _db.queryDownloadTasks();
    for (final r in rows) {
      await _db.deleteDownloadTask(r.taskId);
    }
  }

  Future<int> _dirSize(Directory root) async {
    var total = 0;
    await for (final e in root.list(recursive: true, followLinks: false)) {
      if (e is File) {
        try {
          total += await e.length();
        } catch (_) {}
      }
    }
    return total;
  }
}
