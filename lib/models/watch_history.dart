/// 观看历史数据库行模型。
class WatchHistory {
  WatchHistory({
    this.dbId,
    required this.videoId,
    required this.videoTitle,
    this.posterUrl,
    this.sourceName,
    this.playedDuration = 0,
    this.totalDuration = 0,
    this.episodeInfo,
    required this.lastWatchedAt,
    required this.createdAt,
  });

  final int? dbId;
  final String videoId;
  final String videoTitle;
  final String? posterUrl;
  final String? sourceName;
  final int playedDuration;
  final int totalDuration;
  final String? episodeInfo;
  final DateTime lastWatchedAt;
  final DateTime createdAt;

  factory WatchHistory.fromMap(Map<String, dynamic> map) {
    return WatchHistory(
      dbId: map['id'] as int?,
      videoId: map['video_id'] as String,
      videoTitle: map['video_title'] as String,
      posterUrl: map['poster_url'] as String?,
      sourceName: map['source_name'] as String?,
      playedDuration: (map['played_duration'] as num?)?.toInt() ?? 0,
      totalDuration: (map['total_duration'] as num?)?.toInt() ?? 0,
      episodeInfo: map['episode_info'] as String?,
      lastWatchedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['last_watched_at'] as num).toInt(),
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (dbId != null) 'id': dbId,
      'video_id': videoId,
      'video_title': videoTitle,
      'poster_url': posterUrl,
      'source_name': sourceName,
      'played_duration': playedDuration,
      'total_duration': totalDuration,
      'episode_info': episodeInfo,
      'last_watched_at': lastWatchedAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory WatchHistory.fromJson(Map<String, dynamic> json) =>
      WatchHistory.fromMap(json);
}
