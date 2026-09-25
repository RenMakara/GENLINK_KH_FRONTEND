import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/app.dart';
import 'package:genlink_frontend/app/bindings/initial_binding.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/app/startup_route_resolver.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:genlink_frontend/features/onboarding/presentation/controllers/language_select_controller.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/completion_screen.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/language_select_screen.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/splash_screen.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/welcome_screen.dart';
import 'package:get/get.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  late Map<String, String> storedValues;

  setUp(() {
    storedValues = <String, String>{};
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (call) async {
        final arguments = (call.arguments as Map?)?.cast<String, dynamic>();
        final key = arguments?['key'] as String?;

        return switch (call.method) {
          'read' => storedValues[key],
          'readAll' => Map<String, String>.of(storedValues),
          'write' => () {
            if (key != null) {
              storedValues[key] = arguments?['value'] as String;
            }
          }(),
          'delete' => storedValues.remove(key),
          'deleteAll' => storedValues.clear(),
          'containsKey' => storedValues.containsKey(key),
          _ => null,
        };
      },
    );

    InitialBinding().dependencies();
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      null,
    );
    Get.reset();
  });

  testWidgets('clean install opens welcome before preferences', (tester) async {
    final initialRoute = await StartupRouteResolver(
      localStorage: Get.find<LocalStorage>(),
    ).resolve();

    expect(initialRoute, AppRoutes.welcome);

    await tester.pumpWidget(GenLinkKhApp(initialRoute: initialRoute));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(LanguageSelectScreen), findsNothing);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('theme choice persists and continues through completion', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const GenLinkKhApp(initialRoute: AppRoutes.languageSelect),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    final darkThemeOption = find.text('Dark');
    await tester.ensureVisible(darkThemeOption);
    await tester.pumpAndSettle();
    await tester.tap(darkThemeOption);
    await tester.pumpAndSettle();

    expect(Get.find<ThemeController>().themeMode.value, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(LanguageSelectScreen))).brightness,
      Brightness.dark,
    );

    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    await tester.runAsync(
      () => Get.find<LanguageSelectController>().continueToSplash(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(
      await Get.find<LocalStorage>().readInitialPreferencesSeen(),
      isFalse,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Go to GenLink'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await Get.find<LocalStorage>().readInitialPreferencesSeen(), isTrue);
    expect(find.byType(LanguageSelectScreen), findsNothing);
  });

  testWidgets('opens on splash', (tester) async {
    await tester.pumpWidget(const GenLinkKhApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('splash fallback redirects to preferences on a first run', (
    tester,
  ) async {
    await tester.pumpWidget(const GenLinkKhApp());

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(LanguageSelectScreen), findsNothing);
  });
}
