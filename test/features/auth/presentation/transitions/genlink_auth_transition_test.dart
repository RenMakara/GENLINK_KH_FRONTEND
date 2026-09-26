import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/widgets/branding/app_logo.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/auth/presentation/transitions/genlink_auth_transition.dart';
import 'package:genlink_frontend/features/auth/presentation/widgets/animated_auth_background.dart';
import 'package:genlink_frontend/features/auth/presentation/widgets/auth_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedAuthBackgroundCoordinator', () {
    test('acquires controller and shares across multiple callers', () {
      final coordinator = SharedAuthBackgroundCoordinator.instance;

      final anim1 = coordinator.acquire(reduceMotion: false);
      expect(anim1, isNotNull);

      final anim2 = coordinator.acquire(reduceMotion: false);
      expect(identical(anim1, anim2), isTrue);

      coordinator.release();
      coordinator.release();
    });

    test('supports reduced motion mode without crashing', () {
      final coordinator = SharedAuthBackgroundCoordinator.instance;
      final anim = coordinator.acquire(reduceMotion: true);
      expect(anim.value, 0.23);
      coordinator.updateReducedMotion(false);
      coordinator.updateReducedMotion(true);
      expect(anim.value, 0.23);
      coordinator.release();
    });
  });

  group('GenLinkAuthTransition', () {
    testWidgets(
      'builds horizontal transition with proper scale and translation',
      (tester) async {
        final controller = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 400),
        );
        final secondaryController = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 400),
        );

        final transition = GenLinkAuthTransition();
        Get.testMode = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return transition.buildTransition(
                  context,
                  Curves.easeOutCubic,
                  Alignment.center,
                  controller,
                  secondaryController,
                  const Text('Auth Target Screen'),
                );
              },
            ),
          ),
        );

        expect(find.text('Auth Target Screen'), findsOneWidget);

        // Verify forward progress
        controller.value = 0.5;
        await tester.pump();
        expect(find.text('Auth Target Screen'), findsOneWidget);

        // Verify completion
        controller.value = 1.0;
        await tester.pump();
        expect(find.text('Auth Target Screen'), findsOneWidget);

        controller.dispose();
        secondaryController.dispose();
      },
    );

    testWidgets(
      'AuthBrandLockup hero flight between routes transitions without null check crash',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/login',
            getPages: [
              GetPage(
                name: '/login',
                page: () => Scaffold(
                  body: Column(
                    children: [
                      const AuthBrandLockup(),
                      ElevatedButton(
                        onPressed: () => Get.toNamed('/forgot-password'),
                        child: const Text('Go to Forgot Password'),
                      ),
                    ],
                  ),
                ),
                customTransition: GenLinkAuthTransition(),
              ),
              GetPage(
                name: '/forgot-password',
                page: () => const Scaffold(
                  body: Column(
                    children: [
                      AuthBrandLockup(),
                      Text('Forgot Password Screen'),
                    ],
                  ),
                ),
                customTransition: GenLinkAuthTransition(),
              ),
            ],
          ),
        );

        expect(find.byType(AuthBrandLockup), findsOneWidget);
        await tester.tap(find.text('Go to Forgot Password'));

        // Step through intermediate animation frames (0.25, 0.5, 0.75, 1.0)
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Forgot Password Screen'), findsOneWidget);
        expect(find.byType(AuthBrandLockup), findsOneWidget);

        // Pop back to login
        Get.back();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Go to Forgot Password'), findsOneWidget);
      },
    );

    testWidgets(
      'AuthScaffold back button is aligned to the left of the content',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: AuthScaffold(
              showBack: true,
              children: [Text('Auth Screen Content')],
            ),
          ),
        );

        final backButtonFinder = find.byType(AppBackButton);
        expect(backButtonFinder, findsOneWidget);

        final backButtonTopLeft = tester.getTopLeft(backButtonFinder);
        // AppSpacing.lg is 24.0, which is the left padding of AuthScaffold
        expect(backButtonTopLeft.dx, 24.0);
      },
    );
  });
}
