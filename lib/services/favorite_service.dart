import '../database/database_helper.dart';
import '../models/favorite.dart';
import '../models/movie.dart';

/// 收藏服务：切换、查询、筛选。
class FavoriteService {
  FavoriteService(this._db);

  final DatabaseHelper _db;

  /// 切换收藏：已存在则删除并返回 false；否则插入并返回 true
  Future<bool> toggleFavorite(Movie m) async {
    final existed = await _db.getFavoriteByVideoId(m.id);
    if (existed != null) {
      await _db.deleteFavoriteByVideoId(m.id);
      return false;
    }
    await _db.insertFavorite({
      'video_id': m.id,
      'video_title': m.title,
      'poster_url': m.posterUrl,
      'video_type': m.type,
      'year': m.year,
      'rating': m.rating,
      'source_name': m.sourceName,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  Future<bool> isFavorite(String videoId) async {
    final r = await _db.getFavoriteByVideoId(videoId);
    return r != null;
  }

  Future<List<FavoriteItem>> getFavorites({String? type, int page = 0}) {
    return _db.queryFavorites(
      videoType: type,
      offset: page * 20,
      limit: 20,
    );
  }

  Future<int> count() => _db.countFavorites();

  Future<void> deleteMany(List<String> videoIds) async {
    if (videoIds.isEmpty) return;
    await _db.batchDeleteFavorites(videoIds);
  }
}
