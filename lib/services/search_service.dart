import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_similarity/string_similarity.dart';

import '../models/movie.dart';
import '../utils/constants.dart';
import 'api/source_manager.dart';

/// 搜索服务：防抖、多源聚合、拼写纠错、历史与二级缓存。
class SearchService {
  SearchService(this._sourceManager);

  final SourceManager _sourceManager;

  /// 内存一级缓存：query -> 条目
  final Map<String, _MemCacheEntry> _memory = {};

  static const _hiveBox = 'search_cache_v1';
  static const _prefsKeyHistory = 'search_history_v1';

  int _debounceGen = 0;

  /// 防抖执行搜索（500ms），仅保留最后一次输入
  Future<List<Movie>> searchDebounced(
    String raw, {
    required void Function(String normalized) onNormalized,
  }) async {
    final gen = ++_debounceGen;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (gen != _debounceGen) return [];
    final q = raw.trim();
    onNormalized(q);
    return search(q);
  }

  /// 主搜索：缓存 -> 网络 -> 纠错重试
  Future<List<Movie>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final cached = await _readCache(q);
    if (cached != null) return cached;

    var list = await _sourceManager.searchAll(q);
    list = _dedupeByTitleYear(list);

    if (list.length < 3) {
      final alt = _suggestSimilarQuery(q);
      if (alt != null && alt != q) {
        final l2 = await _sourceManager.searchAll(alt);
        list = _dedupeByTitleYear([...list, ...l2]);
      }
    }

    await _writeCache(q, list);
    await _pushHistory(q);
    return list;
  }

  List<Movie> _dedupeByTitleYear(List<Movie> input) {
    final map = <String, Movie>{};
    for (final m in input) {
      map.putIfAbsent('${m.title}_${m.year ?? ''}', () => m);
    }
    return map.values.toList();
  }

  /// 简单拼写纠错：结果过少时尝试最相近的变体（演示）
  String? _suggestSimilarQuery(String q) {
    final dict = <String>[
      '星际穿越',
      '流浪地球',
      '三体',
      '奥本海默',
      '沙丘',
      '复仇者联盟',
    ];
    final best = StringSimilarity.findBestMatch(q, dict);
    if (best.bestMatch.rating > 0.35) {
      return best.bestMatch.target;
    }
    return null;
  }

  Future<List<Movie>?> _readCache(String q) async {
    final now = DateTime.now();
    final mem = _memory[q];
    if (mem != null && now.difference(mem.at) < AppConstants.searchCacheTtl) {
      return mem.movies;
    }

    final box = await Hive.openBox<String>(_hiveBox);
    final raw = box.get(_key(q));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ts = map['ts'] as int;
      final at = DateTime.fromMillisecondsSinceEpoch(ts);
      if (now.difference(at) >= AppConstants.searchCacheTtl) return null;
      final list = (map['data'] as List<dynamic>)
          .map((e) => Movie.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _memory[q] = _MemCacheEntry(at: at, movies: list);
      return list;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String q, List<Movie> movies) async {
    final at = DateTime.now();
    _memory[q] = _MemCacheEntry(at: at, movies: movies);
    final box = await Hive.openBox<String>(_hiveBox);
    await box.put(
      _key(q),
      jsonEncode({
        'ts': at.millisecondsSinceEpoch,
        'data': movies.map((e) => e.toJson()).toList(),
      }),
    );
  }

  String _key(String q) => 'q_${q.hashCode}';

  Future<void> _pushHistory(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getStringList(_prefsKeyHistory) ?? <String>[];
    cur.remove(q);
    cur.insert(0, q);
    while (cur.length > AppConstants.searchHistoryMax) {
      cur.removeLast();
    }
    await prefs.setStringList(_prefsKeyHistory, cur);
  }

  Future<List<String>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKeyHistory) ?? [];
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyHistory);
  }
}

class _MemCacheEntry {
  _MemCacheEntry({required this.at, required this.movies});
  final DateTime at;
  final List<Movie> movies;
}
