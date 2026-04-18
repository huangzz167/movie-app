import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'database/database_helper.dart';
import 'providers/download_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/history_provider.dart';
import 'providers/movie_provider.dart';
import 'services/api/source_manager.dart';
import 'services/download_service.dart';
import 'services/favorite_service.dart';
import 'services/search_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/watch_history_service.dart';
import 'utils/themes.dart';

/// 应用入口。
///
/// **Android 清单要点（请在 `android/app/src/main/AndroidManifest.xml` 配置）**
/// - `INTERNET`：网络访问。
/// - `WRITE_EXTERNAL_STORAGE` / `READ_EXTERNAL_STORAGE`：旧版外置存储（按需）。
/// - `POST_NOTIFICATIONS`：Android 13+ 下载通知。
/// - `android:usesCleartextTraffic="true"`：若需访问 http 明文接口（仅调试建议）。
/// - `flutter_downloader` 需注册 `DownloadedFileProvider` 与 `FlutterDownloaderInitializer`（见官方文档）。
///
/// **iOS Info.plist 要点**
/// - `NSAppTransportSecurity`：允许特定 http 域或调试例外。
/// - 相册/文件访问描述按需添加（下载导出场景）。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await FlutterDownloader.initialize(debug: true);
  await DatabaseHelper.instance.database;

  final sourceManager = SourceManager();
  try {
    await sourceManager.warmupAndSort();
  } catch (_) {
    // 测速失败不阻塞启动，后续请求仍可按内置顺序重试
  }

  runApp(JiguangApp(sourceManager: sourceManager));
}

class JiguangApp extends StatelessWidget {
  const JiguangApp({super.key, required this.sourceManager});

  final SourceManager sourceManager;

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper.instance;
    final watch = WatchHistoryService(db);
    final fav = FavoriteService(db);
    final dl = DownloadService(db);
    final storage = StorageService(db);

    return MultiProvider(
      providers: [
        Provider<SourceManager>.value(value: sourceManager),
        Provider<SearchService>(
          create: (c) => SearchService(c.read<SourceManager>()),
        ),
        Provider<WatchHistoryService>.value(value: watch),
        Provider<FavoriteService>.value(value: fav),
        Provider<DownloadService>.value(value: dl),
        Provider<StorageService>.value(value: storage),
        Provider<SyncService>(create: (_) => SyncService()),
        ChangeNotifierProvider(
          create: (c) => MovieProvider(c.read<SourceManager>())..loadHome(),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(watch),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(fav),
        ),
        ChangeNotifierProvider(
          create: (_) => DownloadProvider(dl),
        ),
      ],
      child: MaterialApp.router(
        title: '极光影视',
        theme: buildDarkTheme(),
        routerConfig: buildRouter(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}
