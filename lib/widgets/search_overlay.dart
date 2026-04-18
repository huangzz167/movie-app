import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 搜索页顶部覆盖条：返回 + 输入（可复用）
class SearchOverlayBar extends StatelessWidget {
  const SearchOverlayBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.go('/home'),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '搜索影片、演员、导演',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => onSubmitted(controller.text),
                  ),
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
