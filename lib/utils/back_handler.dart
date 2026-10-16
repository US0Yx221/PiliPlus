import 'package:PiliPlus/pages/main/controller.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

/// 全局统一的返回逻辑
/// 处理三种情况：
/// 1. 有 SmartDialog 弹窗 → 关闭弹窗
/// 2. 当前路由被 PopEntry 拦截（如视频全屏）→ 触发 onPopInvokedWithResult（退出全屏）
/// 3. 普通情况 → navigator.pop()
void handleBack() {
  if (SmartDialog.checkExist()) {
    SmartDialog.dismiss();
    return;
  }

  final route = Get.routing.route;
  if (route is GetPageRoute) {
    if (route.popDisposition == PopDisposition.doNotPop) {
      route.onPopInvokedWithResult(false, null);
      return;
    }
  }

  final navigator = Get.key.currentState;
  if (navigator?.canPop() == true) {
    navigator!.pop();
  }
}

/// 当前是否在首页的第一个 tab（用于手势排除，避免与抽屉手势冲突）
bool isOnHomeTab() {
  try {
    final route = Get.currentRoute;
    if (route != '/' && route != '/home' && route.isNotEmpty) return false;
    return Get.find<MainController>().selectedIndex.value == 0;
  } catch (_) {
    return false;
  }
}
