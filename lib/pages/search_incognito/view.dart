import 'package:PiliPlus/pages/search_incognito/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchIncognitoPage extends StatefulWidget {
  const SearchIncognitoPage({super.key});

  @override
  State<SearchIncognitoPage> createState() => _SearchIncognitoPageState();
}

class _SearchIncognitoPageState extends State<SearchIncognitoPage> {
  late final _controller = Get.put(SearchIncognitoController());

  @override
  void dispose() {
    Get.delete<SearchIncognitoController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller.textController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _controller.search(),
          decoration: InputDecoration(
            hintText: '隐身搜索',
            hintStyle: TextStyle(color: theme.hintColor),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () => _controller.textController.clear(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _controller.search(),
            child: const Text('搜索'),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.textController.text.isNotEmpty && _controller.suggestions.isNotEmpty) {
          return ListView.builder(
            itemCount: _controller.suggestions.length,
            itemBuilder: (context, index) {
              final item = _controller.suggestions[index];
              return ListTile(
                leading: const Icon(Icons.search, size: 18),
                title: Text(item),
                onTap: () => _controller.search(item),
              );
            },
          );
        }
        if (_controller.history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('隐身模式\n搜索记录仅保存在本地', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('隐身搜索历史', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: _controller.clearHistory, child: const Text('清空')),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.history.length,
                itemBuilder: (context, index) {
                  final item = _controller.history[index];
                  return ListTile(
                    leading: const Icon(Icons.history, size: 18),
                    title: Text(item),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _controller.deleteHistoryItem(item),
                    ),
                    onTap: () => _controller.search(item),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
