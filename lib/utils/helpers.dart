import 'package:intl/intl.dart';

/// 通用工具：时间格式化、时长字符串等。
class AppHelpers {
  AppHelpers._();

  static String formatDurationSeconds(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime t) {
    return DateFormat('yyyy-MM-dd HH:mm').format(t);
  }

  static String formatDateOnly(DateTime t) {
    return DateFormat('yyyy-MM-dd').format(t);
  }

  /// 历史分组标签：今天 / 昨天 / 更早
  static String historyGroupLabel(DateTime lastWatched) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(
      lastWatched.year,
      lastWatched.month,
      lastWatched.day,
    );
    if (d == today) return '今天';
    if (d == today.subtract(const Duration(days: 1))) return '昨天';
    return '更早';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
