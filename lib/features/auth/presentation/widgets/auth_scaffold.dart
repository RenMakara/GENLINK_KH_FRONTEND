import 'package:flutter/material.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';

/// Shared frame for every auth screen: floating back button, an optional
/// title/subtitle block, a scrollable body that survives the keyboard, and
/// a pinned footer.
///
/// Pass [title] for the standard header. Screens that need a custom header
/// (an icon badge, a rich subtitle) leave it null and render their own as
/// the first entry in [children].
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.children,
    this.footer,
    this.showBack = true,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
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
                    // The back control floats over the page instead of
                    // living in an app bar, as in the design.
                    if (showBack) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AppBackButton(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    if (title != null) ...[
                      Text(title!, style: theme.textTheme.displayMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    ...children,
                  ],
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Circular badge holding a single icon, used above a screen's title.
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

/// "or" separator between the primary action and the social sign-in.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
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

/// Inline error banner for a failed auth request.
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
