import 'package:flutter/foundation.dart';

import '../models/favorite.dart';
import '../models/movie.dart';
import '../services/favorite_service.dart';

/// 收藏列表与全局计数
class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider(this._service);

  final FavoriteService _service;

  final List<FavoriteItem> _items = [];
  int _count = 0;
  bool _loading = false;

  List<FavoriteItem> get items => List.unmodifiable(_items);
  int get count => _count;
  bool get loading => _loading;

  Future<void> load({String? type, bool refresh = false}) async {
    if (refresh) _items.clear();
    _loading = true;
    notifyListeners();
    try {
      final page = refresh ? 0 : (_items.length ~/ 20);
      final batch = await _service.getFavorites(type: type, page: page);
      if (refresh) {
        _items
          ..clear()
          ..addAll(batch);
      } else {
        _items.addAll(batch);
      }
      _count = await _service.count();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> toggle(Movie m) async {
    final added = await _service.toggleFavorite(m);
    _count = await _service.count();
    await load(refresh: true);
    return added;
  }

  Future<bool> isFavorite(String id) => _service.isFavorite(id);

  Future<void> deleteMany(List<String> ids) async {
    await _service.deleteMany(ids);
    _count = await _service.count();
    await load(refresh: true);
  }
}
