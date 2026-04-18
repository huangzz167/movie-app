import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/download_provider.dart';
import '../providers/favorite_provider.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

/// 个人中心：统计、入口、清理缓存
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _watchMinutes = 128;
  int _imgBytes = 0;
  int _dlBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _reloadSizes();
      if (mounted) {
        await context.read<DownloadProvider>().load();
      }
    });
  }

  Future<void> _reloadSizes() async {
    final st = context.read<StorageService>();
    final a = await st.imageCacheBytes();
    final b = await st.downloadedVideosBytes();
    if (mounted) {
      setState(() {
        _imgBytes = a;
        _dlBytes = b;
      });
    }
  }

  Future<void> _showClearDialog() async {
    await _reloadSizes();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('清理缓存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('图片缓存：${AppHelpers.formatBytes(_imgBytes)}'),
            const SizedBox(height: 8),
            Text('已下载视频：${AppHelpers.formatBytes(_dlBytes)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<StorageService>().clearImageCache();
              await _reloadSizes();
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('清理图片'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<StorageService>().clearDownloadedVideos();
              await _reloadSizes();
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('清理下载'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>().count;
    final dp = context.watch<DownloadProvider>();
    return Scaffold(
      backgroundColor: const Color(AppConstants.colorBg),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                child: Icon(Icons.person, size: 36),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '影视爱好者',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '累计观看约 $_watchMinutes 分钟（演示）',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _tile(
            icon: Icons.favorite,
            title: '我的收藏',
            badge: '$fav',
            onTap: () => context.push('/favorites'),
          ),
          _tile(
            icon: Icons.download,
            title: '我的下载',
            badge: '${dp.done.length} · ${AppHelpers.formatBytes(_dlBytes)}',
            onTap: () => context.go('/downloads'),
          ),
          _tile(
            icon: Icons.history,
            title: '观看历史',
            onTap: () => context.go('/history'),
          ),
          _tile(
            icon: Icons.cleaning_services,
            title: '清理缓存',
            subtitle: '图片 ${AppHelpers.formatBytes(_imgBytes)} / 下载 ${AppHelpers.formatBytes(_dlBytes)}',
            onTap: _showClearDialog,
          ),
          const Divider(height: 32),
          _tile(
            icon: Icons.api,
            title: '接口配置',
            subtitle: '查看/添加 TVBox 源（演示）',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '极光影视',
                applicationVersion: '1.0.0',
                children: const [
                  Text('内置源见 SourceConfig，可在代码中扩展。'),
                ],
              );
            },
          ),
          _tile(
            icon: Icons.settings,
            title: '播放设置',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('演示：暂无额外播放设置项')),
              );
            },
          ),
          _tile(
            icon: Icons.info_outline,
            title: '关于',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '极光影视',
                applicationVersion: '1.0.0',
                children: const [
                  Text('本项目为 Flutter 演示工程，聚合与播放请遵守当地法律法规。'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(badge, style: const TextStyle(color: Colors.white54)),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
