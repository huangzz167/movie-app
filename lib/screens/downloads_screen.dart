import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';

import '../models/download_task.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// 下载页：下载中 / 已完成、批量管理（演示）
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  bool _batch = false;
  final Set<String> _sel = {};
  DownloadProvider? _dp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _dp = context.read<DownloadProvider>();
      await context.read<DownloadService>().syncFromPlugin();
      await _dp!.load();
      _dp!.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _dp?.stopAutoRefresh();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, dp, _) {
        return Scaffold(
          backgroundColor: const Color(AppConstants.colorBg),
          appBar: AppBar(
            title: const Text('下载管理'),
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: '下载中'),
                Tab(text: '已完成'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  _batch = !_batch;
                  _sel.clear();
                }),
                child: Text(_batch ? '完成' : '批量'),
              ),
            ],
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _ActiveList(
                items: dp.active,
                batch: _batch,
                selected: _sel,
                onToggle: (id) => setState(() {
                  if (_sel.contains(id)) {
                    _sel.remove(id);
                  } else {
                    _sel.add(id);
                  }
                }),
              ),
              _DoneList(
                items: dp.done,
                batch: _batch,
                selected: _sel,
                onToggle: (id) => setState(() {
                  if (_sel.contains(id)) {
                    _sel.remove(id);
                  } else {
                    _sel.add(id);
                  }
                }),
              ),
            ],
          ),
          bottomNavigationBar: _batch && _sel.isNotEmpty
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton(
                      onPressed: () async {
                        final ds = context.read<DownloadService>();
                        for (final id in _sel) {
                          await FlutterDownloader.cancel(taskId: id);
                          await ds.syncFromPlugin();
                        }
                        setState(() {
                          _sel.clear();
                          _batch = false;
                        });
                        await dp.load();
                      },
                      child: const Text('取消所选任务'),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _ActiveList extends StatelessWidget {
  const _ActiveList({
    required this.items,
    required this.batch,
    required this.selected,
    required this.onToggle,
  });

  final List<DownloadTaskRow> items;
  final bool batch;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('暂无下载中的任务', style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (c, i) {
        final t = items[i];
        final prog = t.totalBytes <= 0
            ? 0.0
            : (t.downloadedBytes / t.totalBytes).clamp(0.0, 1.0);
        return ListTile(
          leading: batch
              ? Checkbox(
                  value: selected.contains(t.taskId),
                  onChanged: (_) => onToggle(t.taskId),
                )
              : const Icon(Icons.downloading),
          title: Text(t.videoTitle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: prog),
              Text(
                '状态：${DownloadTaskStatusCode.fromInt(t.status).name}',
                style: const TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.pause_circle_outline),
            onPressed: () async {
              await FlutterDownloader.pause(taskId: t.taskId);
            },
          ),
        );
      },
    );
  }
}

class _DoneList extends StatelessWidget {
  const _DoneList({
    required this.items,
    required this.batch,
    required this.selected,
    required this.onToggle,
  });

  final List<DownloadTaskRow> items;
  final bool batch;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('暂无已完成任务', style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (c, i) {
        final t = items[i];
        return ListTile(
          leading: batch
              ? Checkbox(
                  value: selected.contains(t.taskId),
                  onChanged: (_) => onToggle(t.taskId),
                )
              : const Icon(Icons.check_circle, color: Colors.green),
          title: Text(t.videoTitle),
          subtitle: Text(
            AppHelpers.formatBytes(t.totalBytes),
            style: const TextStyle(color: Colors.white38),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('本地播放需解析文件路径（演示）')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await context.read<DownloadService>().cancel(t.taskId);
                  await context.read<DownloadProvider>().load();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
