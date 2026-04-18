import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/download_task.dart';
import '../services/download_service.dart';

/// 下载任务列表与进度刷新
class DownloadProvider extends ChangeNotifier {
  DownloadProvider(this._service);

  final DownloadService _service;

  final List<DownloadTaskRow> _active = [];
  final List<DownloadTaskRow> _done = [];
  Timer? _timer;

  List<DownloadTaskRow> get active => List.unmodifiable(_active);
  List<DownloadTaskRow> get done => List.unmodifiable(_done);

  Future<void> load() async {
    await _service.syncFromPlugin();
    final all = await _service.listAll();
    _active
      ..clear()
      ..addAll(
        all.where((e) {
          final s = e.status;
          return s != DownloadTaskStatusCode.complete.value &&
              s != DownloadTaskStatusCode.canceled.value &&
              s != DownloadTaskStatusCode.failed.value;
        }),
      );
    _done
      ..clear()
      ..addAll(
        all.where((e) => e.status == DownloadTaskStatusCode.complete.value),
      );
    notifyListeners();
  }

  void startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _service.syncFromPlugin();
      await load();
    });
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
