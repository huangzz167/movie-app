/// 影视条目模型，兼容 TVBox 列表/详情常见字段。
class Movie {
  Movie({
    required this.id,
    required this.title,
    this.subTitle,
    this.posterUrl,
    this.backdropUrl,
    this.year,
    this.rating,
    this.type,
    this.area,
    this.director,
    this.actors,
    this.description,
    this.playUrl,
    this.sourceName,
    this.updateTime,
    this.episodes,
  });

  /// 业务主键（多源聚合时可能为 vod_id 或 hash）
  final String id;
  final String title;
  final String? subTitle;
  final String? posterUrl;
  final String? backdropUrl;
  final String? year;
  final double? rating;
  /// 电影 / 剧集 等
  final String? type;
  final String? area;
  final String? director;
  final String? actors;
  final String? description;
  /// 解析后的首个可播 m3u8（若有）
  final String? playUrl;
  final String? sourceName;
  final String? updateTime;
  /// 剧集列表：名称 -> 播放地址
  final Map<String, String>? episodes;

  Movie copyWith({
    String? id,
    String? title,
    String? subTitle,
    String? posterUrl,
    String? backdropUrl,
    String? year,
    double? rating,
    String? type,
    String? area,
    String? director,
    String? actors,
    String? description,
    String? playUrl,
    String? sourceName,
    String? updateTime,
    Map<String, String>? episodes,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      type: type ?? this.type,
      area: area ?? this.area,
      director: director ?? this.director,
      actors: actors ?? this.actors,
      description: description ?? this.description,
      playUrl: playUrl ?? this.playUrl,
      sourceName: sourceName ?? this.sourceName,
      updateTime: updateTime ?? this.updateTime,
      episodes: episodes ?? this.episodes,
    );
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '未知标题',
      subTitle: json['subTitle'] as String?,
      posterUrl: json['posterUrl'] as String?,
      backdropUrl: json['backdropUrl'] as String?,
      year: json['year'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      type: json['type'] as String?,
      area: json['area'] as String?,
      director: json['director'] as String?,
      actors: json['actors'] as String?,
      description: json['description'] as String?,
      playUrl: json['playUrl'] as String?,
      sourceName: json['sourceName'] as String?,
      updateTime: json['updateTime'] as String?,
      episodes: json['episodes'] != null
          ? Map<String, String>.from(json['episodes'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subTitle': subTitle,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'year': year,
      'rating': rating,
      'type': type,
      'area': area,
      'director': director,
      'actors': actors,
      'description': description,
      'playUrl': playUrl,
      'sourceName': sourceName,
      'updateTime': updateTime,
      'episodes': episodes,
    };
  }
}
