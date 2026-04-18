import '../database/database_helper.dart';
import '../models/watch_history.dart';
import '../utils/constants.dart';

/// 观看历史：入库、分页、清理。
class WatchHistoryService {
  WatchHistoryService(this._db);

  final DatabaseHelper _db;

  /// 进入播放时创建或更新一条记录
  Future<void> recordWatchStart({
    required String videoId,
    required String videoTitle,
    String? posterUrl,
    String? sourceName,
    String? episodeInfo,
  }) async {
    final now = DateTime.now();
    await _db.upsertWatchHistoryByVideoId(
      videoId: videoId,
      row: {
        'video_id': videoId,
        'video_title': videoTitle,
        'poster_url': posterUrl,
        'source_name': sourceName,
        'played_duration': 0,
        'total_duration': 0,
        'episode_info': episodeInfo,
        'last_watched_at': now.millisecondsSinceEpoch,
        'created_at': now.millisecondsSinceEpoch,
      },
    );
  }

  /// 定时或退出时更新进度
  Future<void> updateProgress({
    required String videoId,
    required int playedSeconds,
    required int totalSeconds,
    String? episodeInfo,
  }) async {
    final now = DateTime.now();
    await _db.upsertWatchHistoryByVideoId(
      videoId: videoId,
      row: {
        'video_id': videoId,
        'played_duration': playedSeconds,
        'total_duration': totalSeconds,
        if (episodeInfo != null) 'episode_info': episodeInfo,
        'last_watched_at': now.millisecondsSinceEpoch,
      },
    );
  }

  Future<List<WatchHistory>> getHistoryList({int page = 0}) async {
    return _db.queryWatchHistory(
      offset: page * AppConstants.pageSize,
      limit: AppConstants.pageSize,
    );
  }

  Future<void> clearAllHistory() => _db.clearWatchHistory();

  Future<void> deleteHistoryItem(int id) => _db.deleteWatchHistory(id);
}
