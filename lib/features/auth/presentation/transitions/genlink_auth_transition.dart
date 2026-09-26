import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';

/// Reusable transition system for the GenLink KH authentication flow.
///
/// Features:
/// 1. Welcome / AuthChoice -> Login / Register:
///    - Vertical entrance: Incoming screen fades 0 -> 1, scales 0.98 -> 1.0,
///      and slides 18px upward into position (Curves.easeOutCubic, ~420ms).
///    - Outgoing screen: Fades slightly (1.0 -> 0.88) and scales subtly (1.0 -> 0.99).
/// 2. Login <-> Forgot Password / Register / OTP screens:
///    - Subtle horizontal slide: Incoming screen enters from right (+28px -> 0),
///      fades 0 -> 1, and scales 0.985 -> 1.0 (~380ms, Curves.easeOutCubic).
///    - Outgoing screen drifts slightly to the left (0 -> -24px), fades 1.0 -> 0.88,
///      and scales 1.0 -> 0.99.
/// 3. Back Navigation:
///    - Perfectly reverses forward navigation: Outgoing screen moves right (+28px)
///      and fades out; returning screen returns from the left (-24px -> 0) and fades in.
/// 4. Accessibility:
///    - Reduced motion fallback: Simple, gentle cross-fade without translation or scaling.
class GenLinkAuthTransition extends CustomTransition {
  GenLinkAuthTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Accessibility fallback: gentle cross-fade
    if (reducedMotion) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    }

    final prevRoute = Get.previousRoute;
    final args = Get.arguments;
    final isEntryFromWelcome =
        prevRoute == AppRoutes.welcome ||
        prevRoute == AppRoutes.authChoice ||
        prevRoute == AppRoutes.languageSelect ||
        prevRoute == AppRoutes.onboarding ||
        prevRoute == AppRoutes.completion ||
        (args is Map && args['entryFromWelcome'] == true);

    // ─────────────────────────────────────────────────────────────────────────
    // Secondary exit: When this screen is pushed underneath by a deeper screen
    // ─────────────────────────────────────────────────────────────────────────
    final curvedSec = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final Widget result = AnimatedBuilder(
      animation: curvedSec,
      builder: (context, currentChild) {
        final t = curvedSec.value;
        if (t <= 0.0) return currentChild!;

        final opacity = (1.0 - (0.12 * t)).clamp(0.0, 1.0); // 1.0 -> 0.88
        final scale = 1.0 - (0.01 * t); // 1.0 -> 0.99
        final offsetX = -24.0 * t; // 0 -> -24px left

        return Transform.translate(
          offset: Offset(offsetX, 0.0),
          child: Transform.scale(
            scale: scale,
            child: Opacity(opacity: opacity, child: currentChild),
          ),
        );
      },
      child: child,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Primary entrance / pop: When this screen enters (push) or leaves (pop)
    // ─────────────────────────────────────────────────────────────────────────
    final curvedAnim = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    if (isEntryFromWelcome) {
      // 1. Vertical entrance from Welcome / AuthChoice into auth flow
      return AnimatedBuilder(
        animation: curvedAnim,
        builder: (context, currentChild) {
          final t = curvedAnim.value;
          if (t >= 1.0) return currentChild!;

          final opacity = t.clamp(0.0, 1.0);
          final scale = 0.98 + (0.02 * t); // 0.98 -> 1.0
          final offsetY = 18.0 * (1.0 - t); // 18px -> 0px upward

          return Transform.translate(
            offset: Offset(0.0, offsetY),
            child: Transform.scale(
              scale: scale,
              child: Opacity(opacity: opacity, child: currentChild),
            ),
          );
        },
        child: result,
      );
    } else {
      // 2. Subtle horizontal transition between internal auth screens
      return AnimatedBuilder(
        animation: curvedAnim,
        builder: (context, currentChild) {
          final t = curvedAnim.value;
          if (t >= 1.0) return currentChild!;

          final opacity = t.clamp(0.0, 1.0);
          final scale = 0.985 + (0.015 * t); // 0.985 -> 1.0
          final offsetX = 28.0 * (1.0 - t); // 28px -> 0px from right

          return Transform.translate(
            offset: Offset(offsetX, 0.0),
            child: Transform.scale(
              scale: scale,
              child: Opacity(opacity: opacity, child: currentChild),
            ),
          );
        },
        child: result,
      );
    }
  }
}
