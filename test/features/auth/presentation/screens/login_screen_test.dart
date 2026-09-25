import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/features/auth/domain/entities/auth_session.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository repository;
  late _MockSecureStorage secureStorage;
  late AuthController controller;

  setUp(() {
    repository = _MockAuthRepository();
    secureStorage = _MockSecureStorage();
    controller = AuthController(
      authRepository: repository,
      secureStorage: secureStorage,
      localization: LocalizationService(localStorage: LocalStorage()),
    );
    Get
      ..testMode = true
      ..put<AuthController>(controller);
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en', 'US'),
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        getPages: [
          GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(body: Text('home destination')),
          ),
          GetPage(
            name: AppRoutes.register,
            page: () => const Scaffold(body: Text('register destination')),
          ),
          GetPage(
            name: AppRoutes.forgotPassword,
            page: () =>
                const Scaffold(body: Text('forgot password destination')),
          ),
        ],
        translations: AppTranslations(),
        locale: locale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: theme ?? AppTheme.lightFor(locale.languageCode),
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder findLoginButton() => find.widgetWithText(AppButton, 'Log in');

  testWidgets('renders login screen without inline error banner initially', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(AuthErrorBanner), findsNothing);
    expect(find.byKey(const ValueKey('login-error-popup')), findsNothing);
    expect(findLoginButton(), findsOneWidget);
  });

  testWidgets(
    'shows floating error popup on failed login without inline error banner',
    (tester) async {
      when(
        () => repository.login(
          email: 'makara00814@gmail.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(
        const AppError(
          message: 'Invalid email or password',
          errorCode: 'AUTH_INVALID_CREDENTIALS',
        ),
      );

      await pumpScreen(tester);

      // Enter credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'example@email.com'),
        'makara00814@gmail.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter password'),
        'wrongpassword',
      );

      // Tap Login
      await tester.tap(findLoginButton());
      await tester.pump(); // Start submission
      await tester.pump(const Duration(milliseconds: 300)); // Finish submission & show entrance animation

      // Floating popup is visible
      expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);
      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(
        find.text('Please check your credentials and try again.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('login-error-close-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('login-error-progress')),
        findsOneWidget,
      );

      // Inline error banner must NOT exist
      expect(find.byType(AuthErrorBanner), findsNothing);

      // Login button must NOT be disabled by cooldown
      final loginBtn = tester.widget<AppButton>(findLoginButton());
      expect(loginBtn.onPressed, isNotNull);
    },
  );

  testWidgets('close (X) button immediately dismisses the floating error popup', (
    tester,
  ) async {
    when(
      () => repository.login(
        email: 'makara00814@gmail.com',
        password: 'wrongpassword',
      ),
    ).thenThrow(
      const AppError(
        message: 'Invalid email or password',
        errorCode: 'AUTH_INVALID_CREDENTIALS',
      ),
    );

    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'example@email.com'),
      'makara00814@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter password'),
      'wrongpassword',
    );

    await tester.tap(findLoginButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);

    // Tap close button
    await tester.tap(find.byKey(const ValueKey('login-error-close-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Popup is dismissed
    expect(find.byKey(const ValueKey('login-error-popup')), findsNothing);
  });

  testWidgets('floating error popup automatically dismisses after ~3 seconds', (
    tester,
  ) async {
    when(
      () => repository.login(
        email: 'makara00814@gmail.com',
        password: 'wrongpassword',
      ),
    ).thenThrow(
      const AppError(
        message: 'Invalid email or password',
        errorCode: 'AUTH_INVALID_CREDENTIALS',
      ),
    );

    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'example@email.com'),
      'makara00814@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter password'),
      'wrongpassword',
    );

    await tester.tap(findLoginButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Entrance animation

    expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);

    // Advance 1.5 seconds (halfway through auto-dismiss)
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);

    // Advance remaining 1.5 seconds + fade out
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));

    // Popup has disappeared automatically
    expect(find.byKey(const ValueKey('login-error-popup')), findsNothing);
  });

  testWidgets('allows immediate retry and resets timer on repeated failure', (
    tester,
  ) async {
    when(
      () => repository.login(
        email: 'makara00814@gmail.com',
        password: 'wrongpassword',
      ),
    ).thenThrow(
      const AppError(
        message: 'Invalid email or password',
        errorCode: 'AUTH_INVALID_CREDENTIALS',
      ),
    );

    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'example@email.com'),
      'makara00814@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter password'),
      'wrongpassword',
    );

    // First login failure
    await tester.tap(findLoginButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);
    verify(
      () => repository.login(
        email: 'makara00814@gmail.com',
        password: 'wrongpassword',
      ),
    ).called(1);

    // Tap login again immediately (should NOT be blocked)
    await tester.tap(findLoginButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(
      () => repository.login(
        email: 'makara00814@gmail.com',
        password: 'wrongpassword',
      ),
    ).called(1);

    // Popup is still visible with restarted timer
    expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);
  });

  testWidgets('navigates to home on successful login', (tester) async {
    when(
      () => repository.login(
        email: 'makara00814@gmail.com',
        password: 'correctpassword',
      ),
    ).thenAnswer(
      (_) async => const AuthSession(
        accessToken: 'access-token-123',
        refreshToken: 'refresh-token-123',
        tokenType: 'Bearer',
        user: UserEntity(
          id: 'user-1',
          fullName: 'Makara Ren',
          username: 'makara',
          email: 'makara00814@gmail.com',
          emailVerified: true,
          accountStatus: 'ACTIVE',
          totalXp: 100,
          level: 1,
          preferredLanguage: 'en',
          role: 'USER',
          active: true,
        ),
      ),
    );
    when(() => secureStorage.readAccessToken()).thenAnswer(
      (_) async => 'access-token-123',
    );
    when(() => secureStorage.saveTokenPair(
      accessToken: any(named: 'accessToken'),
      refreshToken: any(named: 'refreshToken'),
    )).thenAnswer((_) async {});
    when(() => secureStorage.saveUserEmail(any())).thenAnswer((_) async {});
    when(() => secureStorage.saveUserId(any())).thenAnswer((_) async {});

    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'example@email.com'),
      'makara00814@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter password'),
      'correctpassword',
    );

    await tester.tap(findLoginButton());
    await tester.pumpAndSettle();

    expect(find.text('home destination'), findsOneWidget);
  });

  testWidgets(
    'error popup renders with solid high-contrast card styling, 40px icon, and 40px close button',
    (tester) async {
      when(
        () => repository.login(
          email: 'makara00814@gmail.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(
        const AppError(
          message: 'Invalid email or password',
          errorCode: 'AUTH_INVALID_CREDENTIALS',
        ),
      );

      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'example@email.com'),
        'makara00814@gmail.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter password'),
        'wrongpassword',
      );

      await tester.tap(findLoginButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Solid opaque container decoration check
      final containerFinder = find.byKey(const ValueKey('login-error-popup'));
      expect(containerFinder, findsOneWidget);
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFF1F2));
      expect(decoration.borderRadius, BorderRadius.circular(18));
      expect(decoration.border?.top.color, const Color(0xFFFECDD3));
      expect(decoration.boxShadow, isNotEmpty);

      // 2. High-contrast typography check
      final titleText = tester.widget<Text>(
        find.byKey(const ValueKey('login-error-title')),
      );
      expect(titleText.style?.fontWeight, FontWeight.w700);
      expect(titleText.style?.color, const Color(0xFF881337));

      final descText = tester.widget<Text>(
        find.byKey(const ValueKey('login-error-description')),
      );
      expect(descText.style?.fontWeight, FontWeight.w500);
      expect(descText.style?.color, const Color(0xFF5A1E24));
      expect(descText.style?.height, 1.45);

      // 3. Error icon container size check (40x40)
      final iconContainerFinder =
          find.byKey(const ValueKey('login-error-icon-container'));
      expect(iconContainerFinder, findsOneWidget);
      final iconSize = tester.getSize(iconContainerFinder);
      expect(iconSize.width, 40.0);
      expect(iconSize.height, 40.0);

      // 4. Close button touch target size check (40x40)
      final closeButtonFinder =
          find.byKey(const ValueKey('login-error-close-button'));
      expect(closeButtonFinder, findsOneWidget);
      final closeSize = tester.getSize(closeButtonFinder);
      expect(closeSize.width, greaterThanOrEqualTo(40.0));
      expect(closeSize.height, greaterThanOrEqualTo(40.0));
    },
  );

  testWidgets(
    'shows rate limiting error message correctly with high contrast styling',
    (tester) async {
      when(
        () => repository.login(
          email: 'makara00814@gmail.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(
        const AppError(
          message: 'Too many requests. Please try again later.',
          errorCode: 'RATE_LIMIT_EXCEEDED',
        ),
      );

      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'example@email.com'),
        'makara00814@gmail.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter password'),
        'wrongpassword',
      );

      await tester.tap(findLoginButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Too many requests. Please try again later.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-error-close-button')), findsOneWidget);
    },
  );

  testWidgets(
    'renders error popup properly in Khmer locale with KantumruyPro font fallback',
    (tester) async {
      when(
        () => repository.login(
          email: 'makara00814@gmail.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(
        const AppError(
          message: 'អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ',
          errorCode: 'AUTH_INVALID_CREDENTIALS',
        ),
      );

      await pumpScreen(tester, locale: const Locale('km', 'KH'));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'example@email.com'),
        'makara00814@gmail.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'បញ្ចូលពាក្យសម្ងាត់'),
        'wrongpassword',
      );

      final loginBtn = find.widgetWithText(AppButton, 'ចូលគណនី');
      expect(loginBtn, findsOneWidget);
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ'),
        findsOneWidget,
      );
      expect(
        find.text('សូមពិនិត្យមើលព័ត៌មានរបស់អ្នក ហើយព្យាយាមម្តងទៀត។'),
        findsOneWidget,
      );

      final titleText = tester.widget<Text>(
        find.byKey(const ValueKey('login-error-title')),
      );
      expect(titleText.style?.fontFamily, 'KantumruyPro');
    },
  );
}
