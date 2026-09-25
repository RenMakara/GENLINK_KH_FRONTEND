import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:genlink_frontend/design_system/widgets/branding/app_logo.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/register_screen.dart';
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
          GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
          GetPage(
            name: AppRoutes.verifyEmail,
            page: () => const Scaffold(body: Text('verify email destination')),
          ),
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('login destination')),
          ),
        ],
        translations: AppTranslations(),
        locale: locale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: theme ?? AppTheme.lightFor(locale.languageCode),
        home: const RegisterScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder findCreateAccountButton() =>
      find.widgetWithText(AppButton, 'Create Account');

  testWidgets(
    'renders register screen without inline error banner initially',
    (tester) async {
      await pumpScreen(tester);

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.byType(AuthErrorBanner), findsNothing);
      expect(find.byKey(const ValueKey('login-error-popup')), findsNothing);
      expect(findCreateAccountButton(), findsOneWidget);
    },
  );

  testWidgets('validates required fields and formats before submitting', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.ensureVisible(findCreateAccountButton());
    await tester.tap(findCreateAccountButton());
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);
    verifyNever(
      () => repository.register(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets(
    'shows floating error popup on failed registration without inline error banner',
    (tester) async {
      when(
        () => repository.register(
          fullName: 'Ren Sopheak',
          username: 'rensopheak',
          email: 'renmakara.official@gmail.com',
          password: 'Password123!',
          phoneNumber: any(named: 'phoneNumber'),
          universityName: any(named: 'universityName'),
          workStatus: any(named: 'workStatus'),
          preferredLanguage: any(named: 'preferredLanguage'),
        ),
      ).thenThrow(
        const AppError(
          message: 'Email already registered',
          errorCode: 'AUTH_EMAIL_EXISTS',
        ),
      );

      await pumpScreen(tester);

      // Fill in valid fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sok Kha'),
        'Ren Sopheak',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'username123'),
        'rensopheak',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'example@email.com'),
        'renmakara.official@gmail.com',
      );
      final passwordFields = find.widgetWithText(TextFormField, 'Enter password');
      await tester.enterText(passwordFields.at(0), 'Password123!');
      await tester.enterText(passwordFields.at(1), 'Password123!');

      // Tap Create Account
      await tester.ensureVisible(findCreateAccountButton());
    await tester.tap(findCreateAccountButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // Finish submission & show entrance animation

      // Floating popup is visible with exact server message and description
      expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);
      expect(find.text('Email already registered'), findsOneWidget);
      expect(
        find.text('Please check your information and try again.'),
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
    },
  );

  testWidgets('close (X) button dismisses floating error popup on register', (
    tester,
  ) async {
    when(
      () => repository.register(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phoneNumber: any(named: 'phoneNumber'),
        universityName: any(named: 'universityName'),
        workStatus: any(named: 'workStatus'),
        preferredLanguage: any(named: 'preferredLanguage'),
      ),
    ).thenThrow(
      const AppError(
        message: 'Email already registered',
        errorCode: 'AUTH_EMAIL_EXISTS',
      ),
    );

    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sok Kha'),
      'Ren Sopheak',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'username123'),
      'rensopheak',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'example@email.com'),
      'renmakara.official@gmail.com',
    );
    final passwordFields = find.widgetWithText(TextFormField, 'Enter password');
    await tester.enterText(passwordFields.at(0), 'Password123!');
    await tester.enterText(passwordFields.at(1), 'Password123!');

    await tester.ensureVisible(findCreateAccountButton());
    await tester.tap(findCreateAccountButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);

    // Tap close button
    await tester.tap(find.byKey(const ValueKey('login-error-close-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('login-error-popup')), findsNothing);
  });

  testWidgets('floating error popup automatically dismisses after ~3 seconds', (
    tester,
  ) async {
    when(
      () => repository.register(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phoneNumber: any(named: 'phoneNumber'),
        universityName: any(named: 'universityName'),
        workStatus: any(named: 'workStatus'),
        preferredLanguage: any(named: 'preferredLanguage'),
      ),
    ).thenThrow(
      const AppError(
        message: 'Email already registered',
        errorCode: 'AUTH_EMAIL_EXISTS',
      ),
    );

    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sok Kha'),
      'Ren Sopheak',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'username123'),
      'rensopheak',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'example@email.com'),
      'renmakara.official@gmail.com',
    );
    final passwordFields = find.widgetWithText(TextFormField, 'Enter password');
    await tester.enterText(passwordFields.at(0), 'Password123!');
    await tester.enterText(passwordFields.at(1), 'Password123!');

    await tester.ensureVisible(findCreateAccountButton());
    await tester.tap(findCreateAccountButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('login-error-popup')), findsOneWidget);

    // Advance 3.3 seconds (auto-dismiss + fade out)
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('login-error-popup')), findsNothing);
  });

  testWidgets('navigates to verify email on successful registration', (
    tester,
  ) async {
    when(
      () => repository.register(
        fullName: 'Ren Sopheak',
        username: 'rensopheak',
        email: 'renmakara.official@gmail.com',
        password: 'Password123!',
        phoneNumber: any(named: 'phoneNumber'),
        universityName: any(named: 'universityName'),
        workStatus: any(named: 'workStatus'),
        preferredLanguage: any(named: 'preferredLanguage'),
      ),
    ).thenAnswer((_) async {});

    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sok Kha'),
      'Ren Sopheak',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'username123'),
      'rensopheak',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'example@email.com'),
      'renmakara.official@gmail.com',
    );
    final passwordFields = find.widgetWithText(TextFormField, 'Enter password');
    await tester.enterText(passwordFields.at(0), 'Password123!');
    await tester.enterText(passwordFields.at(1), 'Password123!');

    await tester.ensureVisible(findCreateAccountButton());
    await tester.tap(findCreateAccountButton());
    await tester.pumpAndSettle();

    expect(find.text('verify email destination'), findsOneWidget);
    controller.onClose();
  });

  testWidgets(
    'renders error popup properly in Khmer locale with fallback font',
    (tester) async {
      when(
        () => repository.register(
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          phoneNumber: any(named: 'phoneNumber'),
          universityName: any(named: 'universityName'),
          workStatus: any(named: 'workStatus'),
          preferredLanguage: any(named: 'preferredLanguage'),
        ),
      ).thenThrow(
        const AppError(
          message: 'អ៊ីមែលនេះត្រូវបានចុះឈ្មោះរួចហើយ',
          errorCode: 'AUTH_EMAIL_EXISTS',
        ),
      );

      await pumpScreen(tester, locale: const Locale('km', 'KH'));

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'រ៉េន សុភ័ក្ត្រ');
      await tester.enterText(textFields.at(1), 'rensopheak');
      await tester.enterText(textFields.at(2), 'renmakara.official@gmail.com');
      await tester.enterText(textFields.at(3), 'Password123!');
      await tester.enterText(textFields.at(4), 'Password123!');

      final createBtn = find.widgetWithText(AppButton, 'បង្កើតគណនី');
      expect(createBtn, findsOneWidget);
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('អ៊ីមែលនេះត្រូវបានចុះឈ្មោះរួចហើយ'),
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
      controller.onClose();
    },
  );

  testWidgets('renders GenLink logo mark and wordmark in light and dark mode', (
    tester,
  ) async {
    // Light Mode
    await pumpScreen(
      tester,
      theme: AppTheme.lightFor('en'),
    );
    expect(find.byType(AuthBrandLockup), findsOneWidget);
    var svgWidgets = tester.widgetList<SvgPicture>(find.descendant(
      of: find.byType(AuthBrandLockup),
      matching: find.byType(SvgPicture),
    )).toList();
    expect(svgWidgets.length, 2);
    expect(
      (svgWidgets[0].bytesLoader as SvgAssetLoader).assetName,
      AppLogoAssets.glLight,
    );
    expect(
      (svgWidgets[1].bytesLoader as SvgAssetLoader).assetName,
      AppLogoAssets.wordmarkLight,
    );

    // Dark Mode
    await pumpScreen(
      tester,
      theme: AppTheme.darkFor('en'),
    );
    expect(find.byType(AuthBrandLockup), findsOneWidget);
    svgWidgets = tester.widgetList<SvgPicture>(find.descendant(
      of: find.byType(AuthBrandLockup),
      matching: find.byType(SvgPicture),
    )).toList();
    expect(svgWidgets.length, 2);
    expect(
      (svgWidgets[0].bytesLoader as SvgAssetLoader).assetName,
      AppLogoAssets.glDark,
    );
    expect(
      (svgWidgets[1].bytesLoader as SvgAssetLoader).assetName,
      AppLogoAssets.wordmarkDark,
    );
  });
}
