import 'dart:convert';

import '../../models/movie.dart';

/// TVBox 风格 JSON 解析：兼容 list / records / data 等常见字段。
class TvBoxParser {
  TvBoxParser._();

  /// 从配置 JSON 中提取站点列表（sites / spider / 数组根）
  static List<Map<String, dynamic>> parseSitesFromConfig(dynamic root) {
    if (root == null) return [];
    if (root is List) {
      return root.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (root is Map) {
      final m = Map<String, dynamic>.from(root);
      if (m['sites'] is List) {
        return (m['sites'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      if (m['data'] is List) {
        return (m['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
  }

  /// 解析分类/列表接口返回的 vod 列表
  static List<Movie> parseMovieList(dynamic json, {String? sourceName}) {
    final List<dynamic> raw = _extractList(json);
    final out = <Movie>[];
    for (final item in raw) {
      if (item is Map) {
        final m = _mapToMovie(Map<String, dynamic>.from(item), sourceName);
        if (m != null) out.add(m);
      }
    }
    return out;
  }

  static List<dynamic> _extractList(dynamic json) {
    if (json is List) return json;
    if (json is Map) {
      final m = json;
      for (final key in ['list', 'data', 'records', 'result']) {
        if (m[key] is List) return m[key] as List<dynamic>;
      }
    }
    return [];
  }

  static Movie? _mapToMovie(Map<String, dynamic> map, String? sourceName) {
    final id = _str(map, ['vod_id', 'id', 'tid', 'book_id']) ??
        _hashId(map);
    final title = _str(map, ['vod_name', 'name', 'title', 'book_name']);
    if (title == null || title.isEmpty) return null;
    final poster = _str(map, ['vod_pic', 'pic', 'cover', 'img']);
    final year = _str(map, ['vod_year', 'year']);
    final rating = _double(map, ['vod_score', 'score', 'rating']);
    final type = _str(map, ['type_name', 'vod_class', 'category']);
    final area = _str(map, ['vod_area', 'area']);
    final director = _str(map, ['vod_director', 'director']);
    final actors = _str(map, ['vod_actor', 'actor']);
    final desc = _str(map, ['vod_content', 'des', 'desc', 'content']);
    final play = _str(map, ['vod_play_url', 'play_url', 'url']);
    final update = _str(map, ['vod_time', 'time', 'update']);

    return Movie(
      id: id,
      title: title,
      posterUrl: poster,
      backdropUrl: poster,
      year: year,
      rating: rating,
      type: type,
      area: area,
      director: director,
      actors: actors,
      description: desc,
      playUrl: _firstPlayUrl(play),
      sourceName: sourceName,
      updateTime: update,
    );
  }

  static String _hashId(Map<String, dynamic> map) {
    final raw = jsonEncode(map);
    return 'h_${raw.hashCode}';
  }

  static String? _str(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v != null && '$v'.isNotEmpty) return '$v';
    }
    return null;
  }

  static double? _double(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }
    return null;
  }

  /// TVBox 常见 play 字段：`线路1$$$url1#name2$url2` 或直链
  static String? _firstPlayUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains('.m3u8')) {
      final m = RegExp(r'https?:\/\/[^\s]+\.m3u8').firstMatch(raw);
      if (m != null) return m.group(0);
    }
    final parts = raw.split(r'$');
    for (final p in parts.reversed) {
      if (p.startsWith('http')) return p.trim();
    }
    return raw.split('#').firstWhere(
          (e) => e.startsWith('http'),
          orElse: () => '',
        ).isEmpty
        ? null
        : raw.split('#').firstWhere((e) => e.startsWith('http'));
  }

  /// 详情页补充剧集映射
  static Map<String, String>? parseEpisodes(String? playUrlField) {
    if (playUrlField == null || playUrlField.isEmpty) return null;
    final map = <String, String>{};
    final segs = playUrlField.split('#');
    for (final s in segs) {
      final idx = s.lastIndexOf(r'$');
      if (idx > 0 && idx < s.length - 1) {
        final name = s.substring(0, idx);
        final url = s.substring(idx + 1);
        if (url.startsWith('http')) map[name] = url;
      }
    }
    return map.isEmpty ? null : map;
  }
}
