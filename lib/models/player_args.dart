import 'movie.dart';

/// 播放器路由参数
class PlayerArgs {
  PlayerArgs({
    required this.movie,
    required this.playUrl,
    this.episodeLabel,
  });

  final Movie movie;
  final String playUrl;
  final String? episodeLabel;
}
