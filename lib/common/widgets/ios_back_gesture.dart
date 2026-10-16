import 'package:PiliPlus/utils/back_handler.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// iOS 风格的左边缘右滑返回手势
///
/// 从屏幕左边缘（15px 内）开始向右滑动时触发返回。
/// 基础逻辑：
/// - 只在首页（第一个 tab）时不参与，避免与抽屉手势冲突
/// - 其他页面一律参与，触发后调用 [handleBack]，
///   由其自动处理 PopEntry（如退出视频全屏）或普通路由返回
class IosBackGesture extends StatelessWidget {
  const IosBackGesture({super.key, required this.child});

  final Widget child;

  /// 左边缘触发宽度
  static const double edgeWidth = 15.0;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _EdgeBackGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_EdgeBackGestureRecognizer>(
          () => _EdgeBackGestureRecognizer(),
          (instance) {
            instance.onEnd = (_) => handleBack();
          },
        ),
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// 自定义手势识别器：只在左边缘按下、向右滑动时参与手势竞技
class _EdgeBackGestureRecognizer extends HorizontalDragGestureRecognizer {
  _EdgeBackGestureRecognizer({super.kind});

  Offset? _downPos;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (event.position.dx > IosBackGesture.edgeWidth) return;
    if (isOnHomeTab()) return;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _downPos = event.position;
    }
    super.handleEvent(event);
  }

  @override
  String get debugDescription => 'EdgeBackGesture';
}
