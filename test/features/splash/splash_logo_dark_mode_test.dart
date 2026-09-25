import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:genlink_frontend/design_system/widgets/branding/app_logo.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_central_plate.dart';
import 'package:genlink_frontend/features/splash/presentation/widgets/splash_wordmark.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GenLink GL Logo & Wordmark Theme Switching Tests', () {
    testWidgets('Renders all 4 splash SVG logo variants directly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/splash/genlink_gl_light.svg',
                    width: 65,
                    height: 50,
                  ),
                  SvgPicture.asset(
                    'assets/splash/genlink_gl_dark.svg',
                    width: 65,
                    height: 50,
                  ),
                  SvgPicture.asset(
                    'assets/splash/genlink_wordmark_light.svg',
                    height: 24,
                  ),
                  SvgPicture.asset(
                    'assets/splash/genlink_wordmark_dark.svg',
                    height: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsNWidgets(4));
    });

    testWidgets('Light Mode: SplashCentralPlate and SplashWordmark use light assets', (tester) async {
      final animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Column(
              children: [
                SplashCentralPlate(
                  breathingAnimation: animController,
                  size: 140,
                ),
                const SplashWordmark(height: 24),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svgPictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect(svgPictures.length, 2);

      // Verify the picture providers load the correct light asset paths
      final plateSvg = svgPictures[0].bytesLoader as SvgAssetLoader;
      expect(plateSvg.assetName, 'assets/splash/genlink_gl_light.svg');

      final wordmarkSvg = svgPictures[1].bytesLoader as SvgAssetLoader;
      expect(wordmarkSvg.assetName, 'assets/splash/genlink_wordmark_light.svg');

      animController.dispose();
    });

    testWidgets('Dark Mode: SplashCentralPlate and SplashWordmark use dark assets', (tester) async {
      final animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Column(
              children: [
                SplashCentralPlate(
                  breathingAnimation: animController,
                  size: 140,
                ),
                const SplashWordmark(height: 24),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svgPictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect(svgPictures.length, 2);

      // Verify the picture providers load the correct dark asset paths
      final plateSvg = svgPictures[0].bytesLoader as SvgAssetLoader;
      expect(plateSvg.assetName, 'assets/splash/genlink_gl_dark.svg');

      final wordmarkSvg = svgPictures[1].bytesLoader as SvgAssetLoader;
      expect(wordmarkSvg.assetName, 'assets/splash/genlink_wordmark_dark.svg');

      animController.dispose();
    });

    testWidgets('Light & Dark Mode: AppLogoMark and AppWordmark switch correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
          home: const Scaffold(
            body: Column(
              children: [
                AppLogoMark(size: 80),
                AppWordmark(height: 24),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var svgList = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect((svgList[0].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_gl_light.svg');
      expect((svgList[1].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_wordmark_light.svg');

      // Now switch to Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: Column(
              children: [
                AppLogoMark(size: 80),
                AppWordmark(height: 24),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      svgList = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect((svgList[0].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_gl_dark.svg');
      expect((svgList[1].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_wordmark_dark.svg');
    });

    testWidgets('AuthBrandLockup adapts cleanly to both Light and Dark themes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AuthBrandLockup(
              markSize: 52,
              wordmarkHeight: 26,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthBrandLockup), findsOneWidget);
      var svgList = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect((svgList[0].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_gl_light.svg');
      expect((svgList[1].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_wordmark_light.svg');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AuthBrandLockup(
              markSize: 52,
              wordmarkHeight: 26,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      svgList = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect((svgList[0].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_gl_dark.svg');
      expect((svgList[1].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_wordmark_dark.svg');
    });

    testWidgets('SplashScreen renders in Dark Mode without white background behind logo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SplashScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(SplashCentralPlate), findsOneWidget);
      expect(find.byType(SplashWordmark), findsOneWidget);

      final svgList = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect(svgList.length, greaterThanOrEqualTo(2));
      expect((svgList[0].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_wordmark_dark.svg');
      expect((svgList[1].bytesLoader as SvgAssetLoader).assetName, 'assets/splash/genlink_gl_dark.svg');
    });

    testWidgets('genlink_gl_dark.svg and genlink_gl_light.svg compile and render non-empty vector pictures', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('dark-svg-boundary'),
                child: SvgPicture.asset(
                  'assets/splash/genlink_gl_dark.svg',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundaryFinder = find.byKey(const ValueKey('dark-svg-boundary'));
      expect(boundaryFinder, findsOneWidget);

      final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
      ui.Image? image;
      ByteData? byteData;
      await tester.runAsync(() async {
        image = await boundary.toImage();
        byteData = await image!.toByteData(format: ui.ImageByteFormat.rawRgba);
      });
      expect(byteData, isNotNull);

      // Verify that there are visible colored pixels drawn by the vector paths!
      final bytes = byteData!.buffer.asUint8List();
      int nonZeroPixels = 0;
      for (int i = 0; i < bytes.length; i += 4) {
        final a = bytes[i + 3];
        if (a > 30) {
          nonZeroPixels++;
        }
      }
      expect(nonZeroPixels, greaterThan(1000), reason: 'Vector SVG (dark) must render visible non-transparent pixels');

      // Also verify Light Mode SVG paints vector pixels
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('light-svg-boundary'),
                child: SvgPicture.asset(
                  'assets/splash/genlink_gl_light.svg',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightBoundaryFinder = find.byKey(const ValueKey('light-svg-boundary'));
      expect(lightBoundaryFinder, findsOneWidget);

      final lightBoundary = tester.renderObject<RenderRepaintBoundary>(lightBoundaryFinder);
      await tester.runAsync(() async {
        image = await lightBoundary.toImage();
        byteData = await image!.toByteData(format: ui.ImageByteFormat.rawRgba);
      });
      expect(byteData, isNotNull);

      final lightBytes = byteData!.buffer.asUint8List();
      int lightNonZeroPixels = 0;
      for (int i = 0; i < lightBytes.length; i += 4) {
        final a = lightBytes[i + 3];
        if (a > 30) {
          lightNonZeroPixels++;
        }
      }
      expect(lightNonZeroPixels, greaterThan(1000), reason: 'Vector SVG (light) must render visible non-transparent pixels');
    });
  });
}
