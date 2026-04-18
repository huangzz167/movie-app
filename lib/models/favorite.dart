/// 收藏条目模型。
class FavoriteItem {
  FavoriteItem({
    this.dbId,
    required this.videoId,
    required this.videoTitle,
    this.posterUrl,
    this.videoType,
    this.year,
    this.rating,
    this.sourceName,
    required this.addedAt,
  });

  final int? dbId;
  final String videoId;
  final String videoTitle;
  final String? posterUrl;
  final String? videoType;
  final String? year;
  final double? rating;
  final String? sourceName;
  final DateTime addedAt;

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      dbId: map['id'] as int?,
      videoId: map['video_id'] as String,
      videoTitle: map['video_title'] as String,
      posterUrl: map['poster_url'] as String?,
      videoType: map['video_type'] as String?,
      year: map['year'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      sourceName: map['source_name'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['added_at'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (dbId != null) 'id': dbId,
      'video_id': videoId,
      'video_title': videoTitle,
      'poster_url': posterUrl,
      'video_type': videoType,
      'year': year,
      'rating': rating,
      'source_name': sourceName,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory FavoriteItem.fromJson(Map<String, dynamic> json) =>
      FavoriteItem.fromMap(json);
}
