import 'dart:async';

import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/back_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 左边缘长按手势
///
/// 参数（写死）：
/// - 触发区域：屏幕左边缘 15px 内
/// - 反馈延迟：按下 0.12 秒后显示指纹柔光特效
/// - 触发时长：按住 0.8 秒触发
/// - 取消条件：手指移动超过 15px
///
/// 行为：
/// - 可返回时 → 触发返回（[handleBack] 自动处理 PopEntry/普通返回）
/// - 不可返回且在首页时 → 触发刷新（首页下拉刷新的逻辑）
class EdgeLongPress extends StatefulWidget {
  const EdgeLongPress({super.key, required this.child});

  final Widget child;

  /// 左边缘触发宽度
  static const double edgeWidth = 15.0;

  /// 按下后显示反馈的延迟（秒）
  static const double feedbackDelay = 0.12;

  /// 触发长按的时长（秒）
  static const double triggerDuration = 0.8;

  /// 取消的最大移动距离（px）
  static const double cancelDistance = 15.0;

  @override
  State<EdgeLongPress> createState() => _EdgeLongPressState();
}

class _EdgeLongPressState extends State<EdgeLongPress> {
  Timer? _feedbackTimer;
  Timer? _triggerTimer;
  Offset? _downPos;
  int? _pointerId;
  bool _showingFeedback = false;
  OverlayEntry? _feedbackEntry;

  @override
  void dispose() {
    _cancelTimers();
    _hideFeedback();
    super.dispose();
  }

  void _cancelTimers() {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _triggerTimer?.cancel();
    _triggerTimer = null;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.position.dx > EdgeLongPress.edgeWidth) return;
    final navigator = Get.key.currentState;
    final canPop = navigator?.canPop() ?? false;
    if (!canPop && !isOnHomeTab()) return;
    _pointerId = event.pointer;
    _downPos = event.position;
    _feedbackTimer = Timer(
      Duration(milliseconds: (EdgeLongPress.feedbackDelay * 1000).round()),
      () {
        if (mounted && _pointerId != null) {
          _showFeedback(event.position);
        }
      },
    );
    _triggerTimer = Timer(
      Duration(milliseconds: (EdgeLongPress.triggerDuration * 1000).round()),
      () {
        if (mounted && _pointerId != null) {
          _hideFeedback();
          _pointerId = null;
          _downPos = null;
          if (canPop) {
            handleBack();
          } else {
            _triggerRefresh();
          }
        }
      },
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerId != event.pointer || _downPos == null) return;
    final dx = (event.position.dx - _downPos!.dx).abs();
    final dy = (event.position.dy - _downPos!.dy).abs();
    if (dx > EdgeLongPress.cancelDistance || dy > EdgeLongPress.cancelDistance) {
      _cancel();
    } else {
      _updateFeedback(event.position);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_pointerId == event.pointer) _cancel();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_pointerId == event.pointer) _cancel();
  }

  void _cancel() {
    _cancelTimers();
    _hideFeedback();
    _pointerId = null;
    _downPos = null;
  }

  void _showFeedback(Offset position) {
    _hideFeedback();
    _showingFeedback = true;
    _feedbackEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 30,
        top: position.dy - 30,
        child: IgnorePointer(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: const Icon(Icons.fingerprint, color: Colors.white70, size: 28),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_feedbackEntry!);
  }

  void _updateFeedback(Offset position) {
    if (!_showingFeedback) return;
    _feedbackEntry?.remove();
    _showFeedback(position);
  }

  void _hideFeedback() {
    _feedbackEntry?.remove();
    _feedbackEntry = null;
    _showingFeedback = false;
  }

  void _triggerRefresh() {
    try {
      final mainController = Get.find<MainController>();
      mainController.homeController.onRefresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
