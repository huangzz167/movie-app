import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../utils/constants.dart';
import '../widgets/movie_card.dart';

/// 首页：磨砂顶栏、巨幅推荐、横向分类列表
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RefreshController _rc = RefreshController();

  @override
  void dispose() {
    _rc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieProvider>(
      builder: (context, mp, _) {
        final hero = mp.pickHero();
        return SmartRefresher(
          controller: _rc,
          enablePullDown: true,
          onRefresh: () async {
            await mp.loadHome();
            _rc.refreshCompleted();
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            const Text(
                              '极光影视',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.search, color: Colors.white),
                              onPressed: () => context.go('/search'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded, color: Colors.white),
                              onPressed: () => context.go('/downloads'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (mp.loading && mp.feed.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (mp.error != null && mp.feed.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(mp.error!, style: const TextStyle(color: Colors.white54)),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _HeroBanner(movie: hero, movies: mp.feed),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: _SectionTitle(title: '热门电影'),
                ),
                SliverToBoxAdapter(
                  child: _HorizontalList(movies: mp.hotMovies),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const SliverToBoxAdapter(
                  child: _SectionTitle(title: '最新剧集'),
                ),
                SliverToBoxAdapter(
                  child: _HorizontalList(movies: mp.latestShows),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HorizontalList extends StatelessWidget {
  const _HorizontalList({required this.movies});
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('暂无数据', style: TextStyle(color: Colors.white38)),
        ),
      );
    }
    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (c, i) {
          final m = movies[i];
          return MovieCard(
            movie: m,
            onTap: () => context.push('/detail', extra: m),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: movies.length,
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.movie, required this.movies});

  final Movie? movie;
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    final list = movies.isNotEmpty ? movies : (movie != null ? [movie!] : <Movie>[]);
    if (list.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('暂无推荐')));
    }
    return CarouselSlider(
      options: CarouselOptions(
        height: 220,
        viewportFraction: 0.92,
        enlargeCenterPage: true,
        autoPlay: true,
      ),
      items: list.take(5).map((m) {
        final url = m.backdropUrl ?? m.posterUrl;
        return GestureDetector(
          onTap: () => context.push('/detail', extra: m),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null && url.isNotEmpty)
                  CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                else
                  Container(color: const Color(AppConstants.colorCard)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(AppConstants.colorAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => context.push('/detail', extra: m),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('立即播放'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
