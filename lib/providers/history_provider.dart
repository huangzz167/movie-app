import 'package:flutter/foundation.dart';

import '../models/watch_history.dart';
import '../services/watch_history_service.dart';

/// 观看历史列表状态
class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._service);

  final WatchHistoryService _service;

  final List<WatchHistory> _items = [];
  bool _loading = false;

  List<WatchHistory> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  Future<void> load({bool refresh = false}) async {
    if (refresh) _items.clear();
    _loading = true;
    notifyListeners();
    try {
      final page = refresh ? 0 : (_items.length ~/ 20);
      final batch = await _service.getHistoryList(page: page);
      if (refresh) {
        _items
          ..clear()
          ..addAll(batch);
      } else {
        _items.addAll(batch);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    await _service.clearAllHistory();
    _items.clear();
    notifyListeners();
  }

  Future<void> remove(int dbId) async {
    await _service.deleteHistoryItem(dbId);
    _items.removeWhere((e) => e.dbId == dbId);
    notifyListeners();
  }
}
