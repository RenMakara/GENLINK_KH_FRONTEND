import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
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
      overlayState = Overlay.maybeOf(context, rootOverlay: true) ??
          Overlay.maybeOf(context);
    } catch (_) {}

    if (overlayState == null) {
      debugPrint('[AppNotificationBanner] No Overlay found for banner: $title - $message');
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
  State<_NotificationBannerWidget> createState() => _NotificationBannerWidgetState();
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
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

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
        return AppColors.success; // #4ADE80
      case NotificationBannerType.error:
        return AppColors.danger; // #EF6A6A
      case NotificationBannerType.warning:
        return AppColors.warning; // #F5B84B
      case NotificationBannerType.info:
        return AppColors.communityAccent; // #5DADEC
    }
  }

  IconData get _defaultIcon {
    switch (widget.type) {
      case NotificationBannerType.success:
        return Icons.check_circle_rounded;
      case NotificationBannerType.error:
        return Icons.delete_outline_rounded;
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
      top: topPadding + 12,
      left: 16,
      right: 16,
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
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfacePrimary.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon Container
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon ?? _defaultIcon,
                            color: _accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Message Text Column (Expanded to prevent overflow)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: AppColors.darkTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.message.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: AppColors.darkTextSecondary,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Optional Action Button or Close Button
                        if (widget.actionLabel != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              _hide();
                              widget.onAction?.call();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.actionLabel!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.close_rounded, color: AppColors.darkTextMuted, size: 18),
                            onPressed: _hide,
                            tooltip: 'Close',
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
    );
  }
}
