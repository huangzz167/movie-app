import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../models/movie.dart';
import '../../utils/constants.dart';
import 'parser.dart';
import 'source_config.dart';

/// 聚合源管理：测速排序、失败冷却、并行拉取与去重。
class SourceManager {
  SourceManager() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.networkTimeout,
        receiveTimeout: AppConstants.networkTimeout,
        sendTimeout: AppConstants.networkTimeout,
        responseType: ResponseType.plain,
        validateStatus: (s) => s != null && s < 600,
      ),
    );
    _sources = SourceConfig.builtin();
  }

  late final Dio _dio;
  late List<SourceConfig> _sources;

  /// 源失败冷却截止时刻
  final Map<String, DateTime> _cooldownUntil = {};

  /// 带重试的 GET（网络层友好处理）
  Future<Response<String>> _getWithRetry(String url) async {
    DioException? last;
    for (var i = 0; i <= AppConstants.maxRetry; i++) {
      try {
        return await _dio.get<String>(url);
      } on DioException catch (e) {
        last = e;
        await Future<void>.delayed(Duration(milliseconds: 350 * (i + 1)));
      }
    }
    throw last ?? DioException(requestOptions: RequestOptions(path: url));
  }

  /// 启动时测速并排序（并行 HEAD/GET）
  Future<void> warmupAndSort() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) return;

    final futures = _sources.map((s) async {
      final sw = Stopwatch()..start();
      try {
        await _dio.get<String>(
          s.configUrl,
          options: Options(validateStatus: (_) => true),
        );
        sw.stop();
        return MapEntry(s, sw.elapsedMilliseconds);
      } catch (_) {
        sw.stop();
        return MapEntry(s, 1 << 30);
      }
    });
    final results = await Future.wait(futures);
    results.sort((a, b) => a.value.compareTo(b.value));
    _sources = results.map((e) => e.key).toList();
    for (var i = 0; i < _sources.length; i++) {
      _sources[i].priority = 100 - i;
    }
  }

  bool _inCooldown(String name) {
    final t = _cooldownUntil[name];
    if (t == null) return false;
    if (DateTime.now().isAfter(t)) {
      _cooldownUntil.remove(name);
      return false;
    }
    return true;
  }

  void _fail(String name) {
    _cooldownUntil[name] = DateTime.now().add(const Duration(minutes: 5));
  }

  /// 拉取首页推荐（多源合并，按 updateTime 排序）
  Future<List<Movie>> fetchHomeFeed({int limit = 30}) async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      return _mockFeed();
    }

    final lists = await Future.wait(
      _sources.map((s) async {
        if (_inCooldown(s.name)) return <Movie>[];
        try {
          final res = await _getWithRetry(s.configUrl);
          final data = _decode(res.data);
          final sites = TvBoxParser.parseSitesFromConfig(data);
          if (sites.isEmpty) {
            final movies = TvBoxParser.parseMovieList(data, sourceName: s.name);
            return movies;
          }
          // 仅演示：取第一个站点 api 尝试拉列表（真实环境需按 TVBox 规则拼 path）
          final first = sites.isNotEmpty ? sites.first : null;
          if (first == null) return <Movie>[];
          final api = '${first['api'] ?? ''}'.trim();
          if (api.isEmpty) return <Movie>[];
          final listUrl = '$api?ac=list';
          final r2 = await _getWithRetry(listUrl);
          return TvBoxParser.parseMovieList(
            _decode(r2.data),
            sourceName: s.name,
          );
        } catch (_) {
          _fail(s.name);
          return <Movie>[];
        }
      }),
    );

    final merged = <String, Movie>{};
    for (final part in lists) {
      for (final m in part) {
        merged.putIfAbsent(
          '${m.title}_${m.year ?? ''}',
          () => m,
        );
      }
    }
    var out = merged.values.toList();
    out.sort((a, b) => (b.updateTime ?? '').compareTo(a.updateTime ?? ''));
    if (out.isEmpty) out = _mockFeed();
    return out.take(limit).toList();
  }

  /// 并行搜索（多源合并去重）
  Future<List<Movie>> searchAll(String keyword) async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      return _mockFeed()
          .where(
            (m) => m.title.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();
    }

    final lists = await Future.wait(
      _sources.map((s) async {
        if (_inCooldown(s.name)) return <Movie>[];
        try {
          final res = await _getWithRetry(s.configUrl);
          final data = _decode(res.data);
          final sites = TvBoxParser.parseSitesFromConfig(data);
          Map<String, dynamic>? first;
          if (sites.isNotEmpty) {
            first = sites.first;
          }
          if (first == null) {
            return TvBoxParser.parseMovieList(data, sourceName: s.name)
                .where(
                  (m) =>
                      m.title.contains(keyword) ||
                      (m.actors?.contains(keyword) ?? false),
                )
                .toList();
          }
          final api = '${first['api'] ?? ''}'.trim();
          if (api.isEmpty) return <Movie>[];
          final url =
              '$api?ac=videolist&wd=${Uri.encodeComponent(keyword)}';
          final r2 = await _getWithRetry(url);
          return TvBoxParser.parseMovieList(
            _decode(r2.data),
            sourceName: s.name,
          );
        } catch (_) {
          _fail(s.name);
          return <Movie>[];
        }
      }),
    );

    final merged = <String, Movie>{};
    for (final part in lists) {
      for (final m in part) {
        merged.putIfAbsent('${m.title}_${m.year ?? ''}', () => m);
      }
    }
    var out = merged.values.toList();
    out.sort((a, b) => (b.updateTime ?? '').compareTo(a.updateTime ?? ''));
    if (out.isEmpty) {
      out = _mockFeed()
          .where(
            (m) => m.title.contains(keyword),
          )
          .toList();
    }
    return out;
  }

  dynamic _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// 离线/接口失败时的本地演示数据
  List<Movie> _mockFeed() {
    return [
      Movie(
        id: 'demo1',
        title: '星际穿越',
        year: '2014',
        rating: 9.4,
        posterUrl:
            'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        backdropUrl:
            'https://image.tmdb.org/t/p/w1280/nCbkOy07TEpqpL0E3eKSJVKFvYR.jpg',
        description:
            '一组探险家利用新发现的虫洞，超越人类太空旅行的限制，在广袤的宇宙中进行星际航行。',
        director: '克里斯托弗·诺兰',
        actors: '马修·麦康纳,安妮·海瑟薇',
        type: '电影',
        playUrl: AppConstants.demoHlsUrl,
        sourceName: '演示',
        updateTime: '2024-01-01',
      ),
      Movie(
        id: 'demo2',
        title: '流浪地球2',
        year: '2023',
        rating: 8.3,
        posterUrl:
            'https://image.tmdb.org/t/p/w500/pTxCdW6R9pZJZZqnpJ0Z1bYAKDh.jpg',
        description: '太阳危机下的人类自救与希望。',
        director: '郭帆',
        actors: '吴京,刘德华',
        type: '电影',
        playUrl: AppConstants.demoHlsUrl,
        sourceName: '演示',
        updateTime: '2023-12-20',
      ),
      Movie(
        id: 'demo3',
        title: '三体',
        year: '2023',
        rating: 8.7,
        posterUrl: 'https://picsum.photos/seed/santi/300/450',
        description: '人类文明与三体文明的首次接触。',
        type: '剧集',
        playUrl: AppConstants.demoHlsUrl,
        sourceName: '演示',
        updateTime: '2023-11-15',
      ),
    ];
  }
}
