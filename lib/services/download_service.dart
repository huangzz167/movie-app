import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../database/database_helper.dart';
import '../models/download_task.dart';

/// 下载任务编排：创建/暂停/恢复/取消，并与本地库同步。
///
/// **关于 m3u8 边下边播（progressive_video_cache）**
/// 可在播放器侧引入 `progressive_video_cache`（或同类库），将 HLS 分片缓存到本地目录，
/// 再把本地目录作为 `Player` 的播放地址或自定义 `DataSource`，实现“边下边播”。
/// 本文件聚焦 `flutter_downloader` 的文件下载与任务状态持久化，二者可并行：下载走本服务，
/// 播放走 media_kit + 缓存库。
class DownloadService {
  DownloadService(this._db);

  final DatabaseHelper _db;

  /// 确保存储权限（Android 13+ 以系统策略为准）
  Future<bool> ensurePermission() async {
    if (Platform.isAndroid) {
      final st = await Permission.storage.request();
      return st.isGranted;
    }
    return true;
  }

  Future<String> _saveDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory('${dir.path}/jgy_downloads');
    if (!await d.exists()) await d.create(recursive: true);
    return d.path;
  }

  /// 创建下载任务并登记数据库
  Future<String?> enqueue({
    required String videoId,
    required String videoTitle,
    String? posterUrl,
    required String url,
    String quality = '自动',
    int? episodeIndex,
  }) async {
    final ok = await ensurePermission();
    if (!ok) return null;

    final savedDir = await _saveDir();
    final fileName = _fileNameFor(videoTitle, url);

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: savedDir,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: false,
    );

    if (taskId == null) return null;

    await _db.insertDownloadTask({
      'task_id': taskId,
      'video_id': videoId,
      'video_title': videoTitle,
      'poster_url': posterUrl,
      'url': url,
      'saved_dir': savedDir,
      'file_name': fileName,
      'total_bytes': 0,
      'downloaded_bytes': 0,
      'status': DownloadTaskStatusCode.enqueued.value,
      'quality': quality,
      'episode_index': episodeIndex,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    return taskId;
  }

  String _fileNameFor(String title, String url) {
    final ext = url.contains('.m3u8') ? 'm3u8' : 'mp4';
    final safe = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '$safe.$ext';
  }

  Future<void> pause(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  Future<void> resume(String taskId) async {
    await FlutterDownloader.resume(taskId: taskId);
  }

  Future<void> cancel(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
    await _db.deleteDownloadTask(taskId);
  }

  Future<void> retry(String taskId) async {
    await FlutterDownloader.retry(taskId: taskId);
  }

  /// 从插件同步任务状态到数据库
  Future<void> syncFromPlugin() async {
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null) return;
    for (final t in tasks) {
      final row = await _db.getDownloadByTaskId(t.taskId);
      if (row == null) continue;
      await _db.updateDownloadTaskByTaskId(
        t.taskId,
        {
          'downloaded_bytes': t.progress,
          'total_bytes': t.progress <= 0 ? row.totalBytes : t.progress,
          'status': t.status.index,
          if (t.status == DownloadTaskStatus.complete)
            'completed_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }
  }

  Future<List<DownloadTaskRow>> listByStatus(int status) {
    return _db.queryDownloadTasks(statusEquals: status);
  }

  Future<List<DownloadTaskRow>> listAll() {
    return _db.queryDownloadTasks();
  }
}
