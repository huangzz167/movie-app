/// 下载任务状态（与 flutter_downloader 对齐的简化枚举）。
enum DownloadTaskStatusCode {
  undefined(0),
  enqueued(1),
  running(2),
  complete(3),
  failed(4),
  canceled(5),
  paused(6);

  const DownloadTaskStatusCode(this.value);
  final int value;

  static DownloadTaskStatusCode fromInt(int v) {
    return DownloadTaskStatusCode.values.firstWhere(
      (e) => e.value == v,
      orElse: () => DownloadTaskStatusCode.undefined,
    );
  }
}

/// 本地持久化的下载任务行。
class DownloadTaskRow {
  DownloadTaskRow({
    this.dbId,
    required this.taskId,
    required this.videoId,
    required this.videoTitle,
    this.posterUrl,
    required this.url,
    this.savedDir,
    this.fileName,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = 0,
    this.quality,
    this.episodeIndex,
    required this.createdAt,
    this.completedAt,
  });

  final int? dbId;
  final String taskId;
  final String videoId;
  final String videoTitle;
  final String? posterUrl;
  final String url;
  final String? savedDir;
  final String? fileName;
  final int totalBytes;
  final int downloadedBytes;
  final int status;
  final String? quality;
  final int? episodeIndex;
  final DateTime createdAt;
  final DateTime? completedAt;

  factory DownloadTaskRow.fromMap(Map<String, dynamic> map) {
    return DownloadTaskRow(
      dbId: map['id'] as int?,
      taskId: map['task_id'] as String,
      videoId: map['video_id'] as String,
      videoTitle: map['video_title'] as String,
      posterUrl: map['poster_url'] as String?,
      url: map['url'] as String,
      savedDir: map['saved_dir'] as String?,
      fileName: map['file_name'] as String?,
      totalBytes: (map['total_bytes'] as num?)?.toInt() ?? 0,
      downloadedBytes: (map['downloaded_bytes'] as num?)?.toInt() ?? 0,
      status: (map['status'] as num?)?.toInt() ?? 0,
      quality: map['quality'] as String?,
      episodeIndex: (map['episode_index'] as num?)?.toInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as num).toInt(),
      ),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['completed_at'] as num).toInt(),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (dbId != null) 'id': dbId,
      'task_id': taskId,
      'video_id': videoId,
      'video_title': videoTitle,
      'poster_url': posterUrl,
      'url': url,
      'saved_dir': savedDir,
      'file_name': fileName,
      'total_bytes': totalBytes,
      'downloaded_bytes': downloadedBytes,
      'status': status,
      'quality': quality,
      'episode_index': episodeIndex,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory DownloadTaskRow.fromJson(Map<String, dynamic> json) =>
      DownloadTaskRow.fromMap(json);
}
