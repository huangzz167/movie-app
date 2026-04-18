import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import '../services/api/source_manager.dart';

/// 首页影片数据与加载状态
class MovieProvider extends ChangeNotifier {
  MovieProvider(this._sourceManager);

  final SourceManager _sourceManager;

  List<Movie> _feed = [];
  List<Movie> _hotMovies = [];
  List<Movie> _latestShows = [];
  bool _loading = false;
  String? _error;

  List<Movie> get feed => _feed;
  List<Movie> get hotMovies => _hotMovies;
  List<Movie> get latestShows => _latestShows;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadHome() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _sourceManager.warmupAndSort();
      final list = await _sourceManager.fetchHomeFeed(limit: 40);
      _feed = list;
      _hotMovies = list.where((m) => (m.type ?? '').contains('电影')).toList();
      if (_hotMovies.isEmpty) _hotMovies = list.take(10).toList();
      _latestShows =
          list.where((m) => (m.type ?? '').contains('剧')).toList();
      if (_latestShows.isEmpty) _latestShows = list.skip(3).take(10).toList();
    } catch (e) {
      _error = '加载失败，请检查网络后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Movie? pickHero() => _feed.isNotEmpty ? _feed.first : null;
}
