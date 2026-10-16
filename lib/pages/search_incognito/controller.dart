import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:get/get.dart';

class SearchIncognitoController extends GetxController {
  final textController = TextEditingController();
  final RxList<String> history = <String>[].obs;
  final RxList<String> suggestions = <String>[].obs;
  static const String _historyKey = 'incognito_search_history';

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    textController.addListener(_onTextChanged);
  }

  void _loadHistory() {
    try {
      final list = GStorage.localCache.get(_historyKey);
      if (list is List) {
        history.value = list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }

  void _saveHistory() {
    try {
      GStorage.localCache.put(_historyKey, history.toList());
    } catch (_) {}
  }

  void _onTextChanged() {
    final text = textController.text.trim();
    if (text.isEmpty) {
      suggestions.clear();
      return;
    }
    _fetchSuggestions(text);
  }

  Future<void> _fetchSuggestions(String keyword) async {
    try {
      final res = await SearchHttp.searchSuggest(keyword: keyword);
      if (res['code'] == 0) {
        final list = res['data']?['result']?['tag'] as List?;
        if (list != null) {
          suggestions.value = list.map((e) => (e['value'] ?? '').toString()).toList();
        }
      }
    } catch (_) {}
  }

  void search([String? keyword]) {
    final kw = (keyword ?? textController.text).trim();
    if (kw.isEmpty) return;
    history.remove(kw);
    history.insert(0, kw);
    if (history.length > 20) history.removeRange(20, history.length);
    _saveHistory();
    Get.toNamed('/searchResult', parameters: {'keyword': kw, 'incognito': '1'});
  }

  void clearHistory() {
    history.clear();
    _saveHistory();
  }

  void deleteHistoryItem(String item) {
    history.remove(item);
    _saveHistory();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
