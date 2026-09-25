import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../colors/app_colors.dart';

enum NotificationBannerType { success, error, warning, info }

class AppNotificationBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: NotificationBannerType.success,
      icon: icon,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showDanger({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.delete_outline_rounded,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: NotificationBannerType.error,
      icon: icon,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.error_outline_rounded,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: NotificationBannerType.error,
      icon: icon,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.warning_amber_rounded,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: NotificationBannerType.warning,
      icon: icon,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.bookmark_border_rounded,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: NotificationBannerType.info,
      icon: icon,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    NotificationBannerType type = NotificationBannerType.info,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3000),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    dismiss();

    OverlayState? overlayState;
    try {
      overlayState =
          Overlay.maybeOf(context, rootOverlay: true) ??
          Overlay.maybeOf(context);
    } catch (_) {}

    if (overlayState == null && Get.overlayContext != null) {
      try {
        overlayState =
            Overlay.maybeOf(Get.overlayContext!, rootOverlay: true) ??
            Overlay.maybeOf(Get.overlayContext!);
      } catch (_) {}
    }

    if (overlayState == null && Get.key.currentState?.overlay != null) {
      overlayState = Get.key.currentState?.overlay;
    }

    if (overlayState == null) {
      debugPrint(
        '[AppNotificationBanner] No Overlay found for banner: $title - $message',
      );
      Get.rawSnackbar(
        title: title,
        message: message,
        backgroundColor: AppColors.darkSurfacePrimary.withValues(alpha: 0.95),
        borderRadius: 20,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        snackPosition: SnackPosition.TOP,
        duration: duration,
        icon: Icon(
          icon ?? (type == NotificationBannerType.success ? Icons.check_circle_rounded : Icons.info_outline_rounded),
          color: type == NotificationBannerType.success ? AppColors.success : AppColors.danger,
        ),
      );
      return;
    }

    _currentEntry = OverlayEntry(
      builder: (ctx) => _NotificationBannerWidget(
        title: title,
        message: message,
        type: type,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: dismiss,
      ),
    );

    overlayState.insert(_currentEntry!);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
  }
}

class _NotificationBannerWidget extends StatefulWidget {
  final String title;
  final String message;
  final NotificationBannerType type;
  final IconData? icon;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _NotificationBannerWidget({
    required this.title,
    required this.message,
    required this.type,
    this.icon,
    required this.duration,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_NotificationBannerWidget> createState() =>
      _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();

    _timer = Timer(widget.duration, _hide);
  }

  void _hide() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case NotificationBannerType.success:
        return const Color(0xFF4ADE80);
      case NotificationBannerType.error:
        return const Color(0xFFEF6A6A);
      case NotificationBannerType.warning:
        return const Color(0xFFF5B84B);
      case NotificationBannerType.info:
        return const Color(0xFF5DADEC);
    }
  }

  IconData get _defaultIcon {
    switch (widget.type) {
      case NotificationBannerType.success:
        return Icons.check_rounded;
      case NotificationBannerType.error:
        return Icons.close_rounded;
      case NotificationBannerType.warning:
        return Icons.warning_amber_rounded;
      case NotificationBannerType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 6,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.up,
                  onDismissed: (_) => widget.onDismiss(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14161A).withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                widget.icon ?? _defaultIcon,
                                color: _accentColor,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                      letterSpacing: -0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.message.isNotEmpty) ...[
                                    const SizedBox(height: 1.5),
                                    Text(
                                      widget.message,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.65),
                                        fontSize: 11,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            if (widget.actionLabel != null) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  _hide();
                                  widget.onAction?.call();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accentColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.actionLabel!,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _hide,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
