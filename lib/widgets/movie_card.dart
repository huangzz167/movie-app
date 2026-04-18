import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../utils/constants.dart';

/// 海报卡片：120x180，圆角 12，点击缩放动画
class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.width = 120,
    this.height = 180,
  });

  final Movie movie;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const accent = Color(AppConstants.colorRating);
    return _ScaleTap(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'poster_${movie.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.posterUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(AppConstants.colorCard),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(AppConstants.colorCard),
                            alignment: Alignment.center,
                            child: const Icon(Icons.movie, color: Colors.white24),
                          ),
                        )
                      : Container(
                          color: const Color(AppConstants.colorCard),
                          alignment: Alignment.center,
                          child: const Icon(Icons.movie, color: Colors.white24),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                if (movie.year != null)
                  Text(
                    movie.year!,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                if (movie.rating != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.star, size: 14, color: accent),
                  Text(
                    movie.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, color: accent),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 点击轻微放大（200ms ease）
class _ScaleTap extends StatefulWidget {
  const _ScaleTap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  double _s = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _s = AppConstants.tapScale),
      onTapCancel: () => setState(() => _s = 1),
      onTapUp: (_) => setState(() => _s = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _s,
        duration: AppConstants.tapScaleDuration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
