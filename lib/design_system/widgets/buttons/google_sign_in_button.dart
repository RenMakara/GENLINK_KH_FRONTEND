import 'package:flutter/material.dart';

import '../../radius/app_radius.dart';

/// "Continue with Google" button.
///
/// The artwork ships the whole button — pill, soft shadow, G mark and
/// label — so this widget only makes it tappable and holds its aspect
/// ratio. The asset is designed to read on both light and dark
/// backgrounds, so there is no per-theme variant.
///
/// [semanticLabel] is passed in already translated; the design system
/// stays free of GetX.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.height = 60,
    this.semanticLabel,
  });

  static const asset = 'assets/backgrounds/auth/GBtn-light.png';

  /// Intrinsic size of the artwork, so it keeps its proportions at any
  /// width instead of stretching.
  static const _aspectRatio = 561 / 90;

  final VoidCallback? onPressed;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Center(
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
