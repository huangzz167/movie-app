/// 云端同步占位服务：后续可对接账号系统与后端 API。
class SyncService {
  SyncService();

  /// 预留：将本地观看历史上传
  Future<void> uploadWatchHistory() async {
    // TODO: 对接后端
  }

  /// 预留：拉取远端收藏合并
  Future<void> pullFavorites() async {
    // TODO: 对接后端
  }
}
