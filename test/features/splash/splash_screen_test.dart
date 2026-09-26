import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/splash_screen.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_background.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_central_plate.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_feature_tile.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_loading_indicator.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_orbit_system.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_tagline.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_wordmark.dart';
import 'package:genlink_frontend/features/splash/presentation/transitions/splash_to_auth_transition.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  testWidgets('SplashScreen renders gracefully on standard viewport', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(SplashBackground), findsOneWidget);
    expect(find.byType(SplashWordmark), findsOneWidget);
    expect(find.byType(SplashOrbitSystem), findsOneWidget);
    expect(find.byType(SplashCentralPlate), findsOneWidget);
    expect(find.byType(SplashFeatureTile), findsNWidgets(4));
    expect(find.byType(SplashTagline), findsOneWidget);
    expect(find.byType(SplashLoadingIndicator), findsOneWidget);

    // Verify tagline texts
    expect(find.text('Connect '), findsOneWidget);
    expect(find.text('Grow'), findsOneWidget);
    expect(find.text(' Thrive'), findsOneWidget);
    expect(find.text('GenLink  KH'), findsOneWidget);
    expect(find.text('MORE OPPORTUNITIES AHEAD'), findsOneWidget);

    // Verify all 4 feature tiles exist
    for (final feature in SplashFeature.values) {
      expect(
        find.byWidgetPredicate(
          (w) => w is SplashFeatureTile && w.feature == feature,
        ),
        findsOneWidget,
      );
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashScreen handles small mobile viewport without overflow', (
    tester,
  ) async {
    // iPhone SE / small Android viewport: 320 x 568
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(SplashOrbitSystem), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Advance animation by 1 second through entrance phases
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashScreen handles zero or very small height without assertion error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: SizedBox(
          width: 300,
          height: 0,
          child: SplashScreen(),
        ),
      ),
    );
    await tester.pump();

    // Must not throw "BoxConstraints has a negative minimum height"
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashScreen supports Dark Mode', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.dark(),
        home: const SplashScreen(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashScreen supports reduced motion accessibility', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: GetMaterialApp(
          home: SplashScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(SplashOrbitSystem), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Pump frames to verify no unexpected animation throws
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Continuous orbital motion updates smoothly over time', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pump();

    // Advance 5 seconds into the 22-second orbit loop
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);

    // Advance another 10 seconds
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashOrbitSystem handles exitAnimation phases cleanly', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final orbitController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 22),
    );
    final breathingController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 4500),
    );
    final exitController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1400),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: SplashOrbitSystem(
              orbitAnimation: orbitController,
              breathingAnimation: breathingController,
              exitAnimation: exitController,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashOrbitSystem), findsOneWidget);
    expect(find.byType(SplashFeatureTile), findsNWidgets(4));

    // Phase 2: Orbit Acceleration (t: 0.0 -> 0.18)
    exitController.value = 0.10;
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Phase 3: Fly-out (t: 0.18 -> 0.52)
    exitController.value = 0.35;
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Phase 4: Logo pulse (t: 0.45 -> 0.55)
    exitController.value = 0.50;
    await tester.pump();
    expect(tester.takeException(), isNull);

    orbitController.dispose();
    breathingController.dispose();
    exitController.dispose();
  });

  testWidgets('SplashToAuthTransition provides zooming logo bridge and reveals auth screen', (
    tester,
  ) async {
    final animationController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 650),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) {
            return SplashToAuthTransition().buildTransition(
              context,
              null,
              null,
              animationController,
              const AlwaysStoppedAnimation(0.0),
              const Scaffold(body: Text('Welcome Screen Content')),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome Screen Content'), findsOneWidget);

    animationController.value = 0.5;
    await tester.pump();
    expect(tester.takeException(), isNull);

    animationController.value = 1.0;
    await tester.pump();
    expect(tester.takeException(), isNull);

    animationController.dispose();
  });
}
