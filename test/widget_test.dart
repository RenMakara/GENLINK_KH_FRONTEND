import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/app.dart';
import 'package:genlink_frontend/app/bindings/initial_binding.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/language_select_screen.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/splash_screen.dart';
import 'package:get/get.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  /// flutter_secure_storage has no implementation in a widget test, so every
  /// read would throw MissingPluginException. Returning null models a clean
  /// install: no token, no onboarding flag.
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (call) async => call.method == 'readAll' ? <String, String>{} : null,
    );

    // GenLinkKhApp resolves ThemeController and LocalizationService during
    // build, so the bindings must be registered first — the same order
    // `bootstrap()` uses in the real app.
    InitialBinding().dependencies();
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    Get.reset();
  });

  testWidgets('opens on splash', (tester) async {
    await tester.pumpWidget(const GenLinkKhApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // Drain the splash hold timer; leaving it pending fails the test.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('splash redirects to language select on a first run',
      (tester) async {
    await tester.pumpWidget(const GenLinkKhApp());

    // Splash holds for a minimum display window before navigating.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Regression guard: SplashController is registered eagerly. If it is
    // ever made lazy again nothing constructs it, onReady never fires, and
    // the app parks on splash — which is exactly what this asserts against.
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LanguageSelectScreen), findsOneWidget);
  });
}
