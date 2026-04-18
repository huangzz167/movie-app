import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../utils/helpers.dart';

/// 自定义播放控制层：进度、倍速、清晰度（轨道）、全屏、投屏（演示）
class VideoPlayerControls extends StatefulWidget {
  const VideoPlayerControls({
    super.key,
    required this.player,
    required this.videoController,
    required this.onBack,
    required this.onCastTap,
    this.title = '',
  });

  final Player player;
  final VideoController videoController;
  final VoidCallback onBack;
  final VoidCallback onCastTap;
  final String title;

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  bool _visible = true;
  Timer? _hideTimer;
  bool _playing = true;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  double _rate = 1;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playSub;
  StreamSubscription<double>? _rateSub;
  List<VideoTrack> _videoTracks = [];
  VideoTrack? _selectedVideoTrack;

  @override
  void initState() {
    super.initState();
    _posSub = widget.player.stream.position.listen((d) {
      setState(() => _pos = d);
    });
    _durSub = widget.player.stream.duration.listen((d) {
      setState(() => _dur = d);
    });
    _playSub = widget.player.stream.playing.listen((v) {
      setState(() => _playing = v);
    });
    _rateSub = widget.player.stream.rate.listen((v) {
      setState(() => _rate = v);
    });
    widget.player.stream.tracks.listen((tracks) {
      // media_kit：Tracks.video 一般为 TracksVideo（含 list / selected）
      final tv = tracks.video;
      final dyn = tv as dynamic;
      final list = dyn.list;
      final sel = dyn.selected;
      setState(() {
        if (list is List) {
          _videoTracks = List<VideoTrack>.from(list.cast<VideoTrack>());
        } else {
          _videoTracks = <VideoTrack>[];
        }
        _selectedVideoTrack = sel is VideoTrack ? sel : null;
      });
    });
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _toggleUi() {
    setState(() => _visible = !_visible);
    if (_visible) _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _rateSub?.cancel();
    super.dispose();
  }

  Future<void> _pickRate() async {
    final rates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('播放倍速', style: TextStyle(color: Colors.white)),
              ),
              ...rates.map(
                (r) => ListTile(
                  title: Text('${r}x', style: const TextStyle(color: Colors.white)),
                  trailing: _rate == r ? const Icon(Icons.check, color: Colors.red) : null,
                  onTap: () async {
                    await widget.player.setRate(r);
                    setState(() => _rate = r);
                    if (mounted) Navigator.pop(c);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickQuality() async {
    final tracks = _videoTracks;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('清晰度 / 轨道', style: TextStyle(color: Colors.white)),
              ),
              if (tracks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '当前片源仅单一轨道（演示）',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ...tracks.map(
                (t) => ListTile(
                  title: Text(
                    t.id.isNotEmpty ? t.id : '轨道',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    t.toString(),
                    style: const TextStyle(color: Colors.white38),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _selectedVideoTrack == t
                      ? const Icon(Icons.check, color: Colors.red)
                      : null,
                  onTap: () async {
                    await widget.player.setVideoTrack(t);
                    setState(() => _selectedVideoTrack = t);
                    if (mounted) Navigator.pop(c);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _toggleUi();
        if (_visible) _scheduleHide();
      },
      child: Stack(
        children: [
          if (_visible)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 4,
                  left: 4,
                  right: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickQuality,
                      child: const Text('HD', style: TextStyle(color: Colors.white)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cast, color: Colors.white),
                      onPressed: widget.onCastTap,
                    ),
                  ],
                ),
              ),
            ),
          if (_visible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 12,
                  left: 12,
                  right: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppHelpers.formatDurationSeconds(_pos.inSeconds),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Expanded(
                          child: Slider(
                            value: _dur.inMilliseconds == 0
                                ? 0
                                : _pos.inMilliseconds
                                        .clamp(0, _dur.inMilliseconds)
                                        .toDouble() /
                                    _dur.inMilliseconds,
                            onChanged: (v) async {
                              final target = Duration(
                                milliseconds:
                                    (_dur.inMilliseconds * v).round(),
                              );
                              await widget.player.seek(target);
                            },
                          ),
                        ),
                        Text(
                          AppHelpers.formatDurationSeconds(_dur.inSeconds),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 44,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            if (_playing) {
                              await widget.player.pause();
                            } else {
                              await widget.player.play();
                            }
                          },
                        ),
                        TextButton.icon(
                          onPressed: _pickRate,
                          icon: const Icon(Icons.speed, color: Colors.white),
                          label: Text(
                            '${_rate}x',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.fullscreen, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).push(
                              PageRouteBuilder<void>(
                                opaque: false,
                                pageBuilder: (ctx, _, __) {
                                  return FullscreenPlayerPage(
                                    controller: widget.videoController,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 简易全屏页：复用同一 VideoController
class FullscreenPlayerPage extends StatelessWidget {
  const FullscreenPlayerPage({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Video(
          controller: controller,
          controls: NoVideoControls,
        ),
      ),
    );
  }
}
