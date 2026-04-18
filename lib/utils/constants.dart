/// 全局常量：颜色、动画时长、分页大小等。
class AppConstants {
  AppConstants._();

  /// 主背景
  static const int colorBg = 0xFF0A0A0A;
  /// 卡片背景
  static const int colorCard = 0xFF1A1A1A;
  /// Netflix 风格强调色
  static const int colorAccent = 0xFFE50914;
  /// 评分金色
  static const int colorRating = 0xFFF5C518;

  static const Duration tapScaleDuration = Duration(milliseconds: 200);
  static const double tapScale = 1.02;

  static const int pageSize = 20;
  static const Duration networkTimeout = Duration(seconds: 10);
  static const int maxRetry = 2;

  /// 搜索内存/DB 缓存有效期
  static const Duration searchCacheTtl = Duration(minutes: 30);

  /// 搜索历史最大条数
  static const int searchHistoryMax = 10;

  /// 4K 测试流（播放器默认演示）
  static const String demoHlsUrl =
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
}
