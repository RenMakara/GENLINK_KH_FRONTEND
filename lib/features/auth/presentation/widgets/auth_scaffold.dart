import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import 'animated_auth_background.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.children,
    this.footer,
    this.showBack = true,
    this.backBottomSpacing = AppSpacing.xl,
    this.overlay,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final bool showBack;
  final double backBottomSpacing;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeAnimation = ModalRoute.of(context)?.animation;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shouldAnimate = routeAnimation != null && !reducedMotion;

    return Scaffold(
      body: AuthBackgroundShell(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showBack || title != null)
                            _StaggeredSection(
                              animation: shouldAnimate ? routeAnimation : null,
                              interval: const Interval(
                                0.0,
                                0.85,
                                curve: Curves.easeOutCubic,
                              ),
                              offsetY: 10.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showBack) ...[
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: AppBackButton(),
                                    ),
                                    SizedBox(height: backBottomSpacing),
                                  ],
                                  if (title != null) ...[
                                    Text(
                                      title!,
                                      style: theme.textTheme.displayMedium,
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        subtitle!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.65),
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.xl),
                                  ],
                                ],
                              ),
                            ),
                          _StaggeredSection(
                            animation: shouldAnimate ? routeAnimation : null,
                            interval: const Interval(
                              0.08,
                              0.92,
                              curve: Curves.easeOutCubic,
                            ),
                            offsetY: 14.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: children,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (footer != null)
                    _StaggeredSection(
                      animation: shouldAnimate ? routeAnimation : null,
                      interval: const Interval(
                        0.15,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                      offsetY: 12.0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: footer,
                      ),
                    ),
                ],
              ),
            ),
            if (overlay != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(bottom: false, child: overlay!),
              ),
          ],
        ),
      ),
    );
  }
}

class AuthBadgeIcon extends StatelessWidget {
  const AuthBadgeIcon({super.key, required this.icon, this.size = 72});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(icon, size: size * 0.4, color: scheme.onSurface),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label ?? 'auth.orDivider'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 18, color: scheme.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredSection extends StatelessWidget {
  const _StaggeredSection({
    required this.animation,
    required this.interval,
    required this.offsetY,
    required this.child,
  });

  final Animation<double>? animation;
  final Interval interval;
  final double offsetY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anim = animation;
    if (anim == null ||
        anim.isCompleted ||
        anim.status == AnimationStatus.reverse) {
      return child;
    }

    final curved = CurvedAnimation(parent: anim, curve: interval);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, staticChild) {
        final t = curved.value;
        if (t >= 1.0) return staticChild!;
        final opacity = t.clamp(0.0, 1.0);
        final dy = offsetY * (1.0 - t);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(0, dy), child: staticChild),
        );
      },
      child: child,
    );
  }
}
