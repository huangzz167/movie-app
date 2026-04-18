/// 内置 TVBox 配置源地址与元数据。
class SourceConfig {
  SourceConfig({
    required this.name,
    required this.configUrl,
    this.priority = 0,
  });

  /// 源显示名称
  final String name;
  /// TVBox 风格站点配置（通常为 JSON）
  final String configUrl;
  /// 初始优先级（测速后会动态调整）
  int priority;

  /// 内置源列表（按用户提供的接口）
  static List<SourceConfig> builtin() {
    return [
      SourceConfig(
        name: '饭太硬',
        configUrl: 'http://www.饭太硬.com/tv',
        priority: 100,
      ),
      SourceConfig(
        name: '肥猫',
        configUrl: 'http://肥猫.com',
        priority: 90,
      ),
      SourceConfig(
        name: '毒盒',
        configUrl: 'https://毒盒.com/tv/',
        priority: 80,
      ),
      SourceConfig(
        name: '摸鱼儿',
        configUrl: 'http://我不是.摸鱼儿.com',
        priority: 70,
      ),
    ];
  }
}
