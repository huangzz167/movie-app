import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_args.dart';
import '../services/watch_history_service.dart';
import '../utils/helpers.dart';
import '../widgets/video_player_controls.dart';

/// 播放器页：media_kit 内核 + 记忆进度 + 定时同步历史
///
/// **Android**：需在 `AndroidManifest.xml` 声明网络与存储等权限（见项目 `android/` 注释）。
/// **iOS**：需在 `Info.plist` 增加相册/网络等说明（见 `ios/Runner/Info.plist` 注释）。
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.args});

  final PlayerArgs args;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _vcontroller;
  Timer? _historyTimer;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  String get _posKey => 'progress_${widget.args.movie.id}';

  @override
  void initState() {
    super.initState();
    _player = Player();
    _vcontroller = VideoController(_player);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    _posSub = _player.stream.position.listen((d) => _pos = d);
    _durSub = _player.stream.duration.listen((d) => _dur = d);
    await _player.open(Media(widget.args.playUrl));
    await _player.play();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_posKey) ?? 0;
    if (saved > 5 && mounted) {
      final dur = Duration(seconds: saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('从 ${AppHelpers.formatDurationSeconds(saved)} 继续观看？'),
          action: SnackBarAction(
            label: '继续',
            onPressed: () async {
              await _player.seek(dur);
              await _player.play();
            },
          ),
        ),
      );
      setState(() => _resumeOffered = true);
    }

    final wh = context.read<WatchHistoryService>();
    await wh.recordWatchStart(
      videoId: widget.args.movie.id,
      videoTitle: widget.args.movie.title,
      posterUrl: widget.args.movie.posterUrl,
      sourceName: widget.args.movie.sourceName,
      episodeInfo: widget.args.episodeLabel,
    );

    _historyTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await wh.updateProgress(
        videoId: widget.args.movie.id,
        playedSeconds: _pos.inSeconds,
        totalSeconds: _dur.inSeconds,
        episodeInfo: widget.args.episodeLabel,
      );
    });
  }

  Future<void> _onExit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_posKey, _pos.inSeconds);
    final wh = context.read<WatchHistoryService>();
    await wh.updateProgress(
      videoId: widget.args.movie.id,
      playedSeconds: _pos.inSeconds,
      totalSeconds: _dur.inSeconds,
      episodeInfo: widget.args.episodeLabel,
    );
    _historyTimer?.cancel();
    if (mounted) context.pop();
  }

  void _showCastDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('可用投屏设备（演示）', style: TextStyle(color: Colors.white)),
              ),
              ListTile(
                leading: const Icon(Icons.tv, color: Colors.white),
                title: const Text('客厅电视', style: TextStyle(color: Colors.white)),
                subtitle: const Text('已连接（模拟）', style: TextStyle(color: Colors.green)),
                onTap: () {
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('演示模式：已模拟连接设备')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.speaker, color: Colors.white),
                title: const Text('卧室投影仪', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(c),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Video(
              controller: _vcontroller,
              controls: NoVideoControls,
            ),
          ),
          VideoPlayerControls(
            player: _player,
            videoController: _vcontroller,
            title: widget.args.movie.title,
            onBack: _onExit,
            onCastTap: _showCastDialog,
          ),
        ],
      ),
    );
  }
}
