import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../providers/favorite_provider.dart';
import '../utils/constants.dart';

/// 收藏页：双列网格、空状态、编辑多选删除
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _edit = false;
  final Set<String> _sel = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, fp, _) {
        return Scaffold(
          backgroundColor: const Color(AppConstants.colorBg),
          appBar: AppBar(
            title: const Text('我的收藏'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _edit = !_edit;
                    _sel.clear();
                  });
                },
                child: Text(_edit ? '完成' : '编辑'),
              ),
              if (_edit && _sel.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await fp.deleteMany(_sel.toList());
                    setState(() {
                      _sel.clear();
                      _edit = false;
                    });
                  },
                  child: const Text('删除'),
                ),
            ],
          ),
          body: fp.loading && fp.items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : fp.items.isEmpty
                  ? const _EmptyFav()
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: fp.items.length,
                      itemBuilder: (c, i) {
                        final it = fp.items[i];
                        final selected = _sel.contains(it.videoId);
                        return GestureDetector(
                          onTap: () {
                            if (_edit) {
                              setState(() {
                                if (selected) {
                                  _sel.remove(it.videoId);
                                } else {
                                  _sel.add(it.videoId);
                                }
                              });
                            } else {
                              final m = Movie(
                                id: it.videoId,
                                title: it.videoTitle,
                                posterUrl: it.posterUrl,
                                year: it.year,
                                rating: it.rating,
                                type: it.videoType,
                                sourceName: it.sourceName,
                                playUrl: AppConstants.demoHlsUrl,
                              );
                              context.push('/detail', extra: m);
                            }
                          },
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: it.posterUrl != null &&
                                        it.posterUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: it.posterUrl!,
                                        height: 220,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 220,
                                        color: const Color(AppConstants.colorCard),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.movie,
                                            color: Colors.white24),
                                      ),
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it.videoTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (it.rating != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              size: 14,
                                              color: Color(AppConstants.colorRating)),
                                          Text(
                                            it.rating!.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Color(AppConstants.colorRating),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (_edit)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      selected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _EmptyFav extends StatelessWidget {
  const _EmptyFav();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          const Text('还没有收藏', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('去发现好片'),
          ),
        ],
      ),
    );
  }
}
