import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/presentation/transitions/genlink_auth_transition.dart';
import '../widgets/splash_central_plate.dart';

class SplashToAuthTransition extends CustomTransition {
  SplashToAuthTransition({this.centerPlateSize = 136.0});

  final double centerPlateSize;

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Check if transition is initiated from splash
    final args = Get.arguments;
    final isFromSplash = args is Map && args['fromSplash'] == true;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (reducedMotion) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    }

    if (!isFromSplash) {
      return GenLinkAuthTransition().buildTransition(
        context,
        curve,
        alignment,
        animation,
        secondaryAnimation,
        child,
      );
    }

    // Coordinated Phase 5 (Logo Zoom Bridge) and Phase 6 (First Auth Screen Reveal)
    Widget content = AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;

        // Phase 6: Auth Screen reveal
        // Starts revealing at progress = 0.12 so it overlaps with the logo zoom!
        final revealProgress = ((progress - 0.12) / 0.88).clamp(0.0, 1.0);
        final revealCurve = Curves.easeOutCubic.transform(revealProgress);

        final authOpacity = revealCurve;
        final authScale = 1.02 - (0.02 * revealCurve); // 1.02 -> 1.0
        final authSlideY = 16.0 * (1.0 - revealCurve); // 16px -> 0px

        // Phase 5: Logo Zoom Bridge
        final zoomCurve = Curves.easeInOutCubic.transform(progress);
        // Starts at 1.04 (matching Splash pulse peak) and expands past viewport (~24.0)
        final logoScale = 1.04 + (23.0 * zoomCurve);

        // Logo dissolve opacity:
        // Stays solid (1.0) while beginning to zoom (0.0 -> 0.18)
        // Then dissolves smoothly (1.0 -> 0.0) from 0.18 to 0.65 as user moves through it!
        final dissolveProgress = ((progress - 0.18) / 0.47).clamp(0.0, 1.0);
        final logoOpacity = (1.0 - Curves.easeIn.transform(dissolveProgress))
            .clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Destination Auth Screen being revealed
            Opacity(
              opacity: authOpacity,
              child: Transform.translate(
                offset: Offset(0, authSlideY),
                child: Transform.scale(scale: authScale, child: child),
              ),
            ),

            // Layer 2: Zooming Logo Plate acting as the visual bridge
            if (logoOpacity > 0.0)
              IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: logoOpacity,
                    child: Transform.scale(
                      scale: logoScale,
                      child: RepaintBoundary(
                        child: SplashCentralPlate(
                          breathingAnimation: const AlwaysStoppedAnimation(0.5),
                          size: centerPlateSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

    final curvedSec = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curvedSec,
      builder: (context, currentChild) {
        final t = curvedSec.value;
        if (t <= 0.0) return currentChild!;

        final opacity = (1.0 - (0.12 * t)).clamp(0.0, 1.0); // 1.0 -> 0.88
        final scale = 1.0 - (0.01 * t); // 1.0 -> 0.99

        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: currentChild),
        );
      },
      child: content,
    );
  }
}
