import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../services/search_service.dart';
import '../utils/constants.dart';
import '../widgets/movie_card.dart';
import '../widgets/search_overlay.dart';

/// 搜索页：全屏感布局、历史、热门、网格结果与加载更多
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Movie> _results = [];
  List<String> _history = [];
  bool _loading = false;
  String? _error;
  int _page = 0;
  final ScrollController _scroll = ScrollController();

  static const _hot = ['三体', '流浪地球', '奥本海默', '沙丘', '复仇者联盟'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scroll.addListener(_onScroll);
  }

  Future<void> _loadHistory() async {
    final s = context.read<SearchService>();
    final h = await s.loadHistory();
    setState(() => _history = h);
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    // 演示：本地分页切片
    if (_loading || _controller.text.trim().isEmpty) return;
    setState(() => _page++);
  }

  Future<void> _doSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
    });
    try {
      final s = context.read<SearchService>();
      final list = await s.searchDebounced(
        query,
        onNormalized: (_) {},
      );
      setState(() {
        _results = list;
        _loading = false;
      });
      await _loadHistory();
    } catch (e) {
      setState(() {
        _error = '搜索失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showEmpty = _controller.text.isEmpty && _results.isEmpty && !_loading;
    return Scaffold(
      backgroundColor: const Color(AppConstants.colorBg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchOverlayBar(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            onSubmitted: _doSearch,
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: showEmpty
                ? _buildHints()
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white54)))
                    : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHints() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('搜索历史', style: TextStyle(color: Colors.white, fontSize: 16)),
            TextButton(
              onPressed: () async {
                await context.read<SearchService>().clearHistory();
                await _loadHistory();
                setState(() {});
              },
              child: const Text('清空'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _history
              .map(
                (t) => ActionChip(
                  label: Text(t),
                  onPressed: () {
                    _controller.text = t;
                    _doSearch(t);
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        const Text('热门搜索', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _hot
              .map(
                (t) => ActionChip(
                  label: Text(t),
                  onPressed: () {
                    _controller.text = t;
                    _doSearch(t);
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_outlined),
          label: const Text('返回首页'),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final slice = _results.take((_page + 1) * AppConstants.pageSize).toList();
    if (slice.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: Colors.white24),
            SizedBox(height: 12),
            Text('未找到相关影片', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, cons) {
        final w = (cons.maxWidth - 36) / 2;
        return GridView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: (w / (w * 1.5 + 40)),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: slice.length,
          itemBuilder: (c, i) {
            final m = slice[i];
            return MovieCard(
              movie: m,
              width: w,
              height: w * 1.5,
              onTap: () => context.push('/detail', extra: m),
            );
          },
        );
      },
    );
  }
}
