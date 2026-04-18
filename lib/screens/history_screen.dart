import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../models/player_args.dart';
import '../models/watch_history.dart';
import '../providers/history_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// 观看历史：分组、进度条、左滑删除
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load(refresh: true);
    });
  }

  Map<String, List<WatchHistory>> _group(List<WatchHistory> list) {
    final map = <String, List<WatchHistory>>{};
    for (final h in list) {
      final label = AppHelpers.historyGroupLabel(h.lastWatchedAt);
      map.putIfAbsent(label, () => []).add(h);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, hp, _) {
        final grouped = _group(hp.items);
        final order = ['今天', '昨天', '更早'];
        return Scaffold(
          backgroundColor: const Color(AppConstants.colorBg),
          appBar: AppBar(
            title: const Text('观看历史'),
            actions: [
              TextButton(
                onPressed: hp.items.isEmpty
                    ? null
                    : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('清空历史'),
                            content: const Text('确定清空全部观看记录？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('清空'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await hp.clearAll();
                        }
                      },
                child: const Text('清空'),
              ),
            ],
          ),
          body: hp.loading && hp.items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : hp.items.isEmpty
                  ? const _EmptyHistory()
                  : ListView(
                      children: [
                        for (final key in order)
                          if (grouped[key] != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                key,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...grouped[key]!.map((h) => _HistoryTile(
                                  item: h,
                                  onDelete: () => hp.remove(h.dbId!),
                                  onOpen: () {
                                    final m = Movie(
                                      id: h.videoId,
                                      title: h.videoTitle,
                                      posterUrl: h.posterUrl,
                                      sourceName: h.sourceName,
                                      playUrl: AppConstants.demoHlsUrl,
                                    );
                                    context.push(
                                      '/player',
                                      extra: PlayerArgs(
                                        movie: m,
                                        playUrl: AppConstants.demoHlsUrl,
                                        episodeLabel: h.episodeInfo,
                                      ),
                                    );
                                  },
                                )),
                          ],
                      ],
                    ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.onDelete,
    required this.onOpen,
  });

  final WatchHistory item;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final total = item.totalDuration <= 0 ? 1 : item.totalDuration;
    final p = (item.playedDuration / total).clamp(0.0, 1.0);
    return Dismissible(
      key: ValueKey(item.dbId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 72,
            color: const Color(AppConstants.colorCard),
            child: const Icon(Icons.movie, color: Colors.white24),
          ),
        ),
        title: Text(item.videoTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: p, minHeight: 4),
            const SizedBox(height: 4),
            Text(
              '最后观看：${AppHelpers.formatDateTime(item.lastWatchedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          const Text('还没有观看记录', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('去首页逛逛'),
          ),
        ],
      ),
    );
  }
}
