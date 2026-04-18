import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../models/player_args.dart';
import '../providers/favorite_provider.dart';
import '../services/download_service.dart';
import '../utils/constants.dart';

/// 详情页：大图、简介、底部固定操作条
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _fav = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final v =
          await context.read<FavoriteProvider>().isFavorite(widget.movie.id);
      if (mounted) setState(() => _fav = v);
    });
  }

  Future<void> _toggleFav() async {
    final added =
        await context.read<FavoriteProvider>().toggle(widget.movie);
    if (mounted) setState(() => _fav = added);
  }

  Future<void> _download() async {
    final url = widget.movie.playUrl ?? AppConstants.demoHlsUrl;
    final ds = context.read<DownloadService>();
    final id = await ds.enqueue(
      videoId: widget.movie.id,
      videoTitle: widget.movie.title,
      posterUrl: widget.movie.posterUrl,
      url: url,
    );
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要存储权限或下载初始化失败')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加入下载队列')),
      );
    }
  }

  void _play() {
    final url = widget.movie.playUrl ?? AppConstants.demoHlsUrl;
    context.push(
      '/player',
      extra: PlayerArgs(movie: widget.movie, playUrl: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;
    final banner = m.backdropUrl ?? m.posterUrl;
    return Scaffold(
      backgroundColor: const Color(AppConstants.colorBg),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: banner != null && banner.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: banner,
                          fit: BoxFit.cover,
                        )
                      : Container(color: const Color(AppConstants.colorCard)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (m.year != null)
                            Text('${m.year}  ', style: const TextStyle(color: Colors.white54)),
                          if (m.rating != null)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(AppConstants.colorRating), size: 18),
                                Text(
                                  m.rating!.toStringAsFixed(1),
                                  style: const TextStyle(color: Color(AppConstants.colorRating)),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        m.description ?? '暂无简介',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      if (m.director != null)
                        Text('导演：${m.director}', style: const TextStyle(color: Colors.white54)),
                      if (m.actors != null)
                        Text('演员：${m.actors}', style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: const Color(AppConstants.colorBg).withOpacity(0.95),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppConstants.colorAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _play,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('立即播放'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white12,
                    ),
                    onPressed: _download,
                    icon: const Icon(Icons.download),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white12,
                    ),
                    onPressed: _toggleFav,
                    icon: Icon(_fav ? Icons.favorite : Icons.favorite_border),
                    color: _fav ? const Color(AppConstants.colorAccent) : null,
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
