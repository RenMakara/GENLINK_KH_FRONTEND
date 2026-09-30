import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/settings/presentation/screens/account_settings_screen.dart';
import 'package:genlink_frontend/features/settings/presentation/screens/security_settings_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository authRepository;
  late _MockSecureStorage secureStorage;
  late AuthController authController;

  setUp(() {
    Get.reset();
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');

    authRepository = _MockAuthRepository();
    secureStorage = _MockSecureStorage();
    authController = AuthController(
      authRepository: authRepository,
      secureStorage: secureStorage,
      localization: LocalizationService(localStorage: LocalStorage()),
    );
    Get.put<AuthController>(authController);
  });

  tearDown(Get.reset);

  group('SecuritySettingsScreen', () {
    testWidgets('shows Change Password for Local account with password', (tester) async {
      authController.currentUser.value = const UserEntity(
        id: 'u1',
        fullName: 'Local User',
        username: 'local_user',
        email: 'local@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
        hasPassword: true,
        authProvider: 'LOCAL',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightFor('en'),
          home: const SecuritySettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsNWidgets(2)); // Card title & Button
      expect(find.text('Password not set'), findsNothing);
      expect(find.text('Set up your password'), findsNothing);
    });

    testWidgets('shows Change Password for Local account even if hasPassword is false', (tester) async {
      authController.currentUser.value = const UserEntity(
        id: 'u1_fallback',
        fullName: 'Local User Fallback',
        username: 'local_user_fallback',
        email: 'local_fb@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
        hasPassword: false,
        authProvider: 'LOCAL',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightFor('en'),
          home: const SecuritySettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsNWidgets(2));
      expect(find.text('Password not set'), findsNothing);
      expect(find.text('Set up your password'), findsNothing);
    });

    testWidgets('shows Password not set & Set up your password for Google account without password', (tester) async {
      authController.currentUser.value = const UserEntity(
        id: 'u2',
        fullName: 'Google User',
        username: 'google_user',
        email: 'google@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
        hasPassword: false,
        authProvider: 'GOOGLE',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightFor('en'),
          home: const SecuritySettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Password not set'), findsOneWidget);
      expect(find.text('Set up your password'), findsOneWidget); // Button
      expect(find.text('Change Password'), findsNothing);
    });

    testWidgets('shows Change Password for Google account after password has been set', (tester) async {
      authController.currentUser.value = const UserEntity(
        id: 'u3',
        fullName: 'Google User With Password',
        username: 'google_user_pw',
        email: 'google_pw@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
        hasPassword: true,
        authProvider: 'GOOGLE',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightFor('en'),
          home: const SecuritySettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsNWidgets(2)); // Card title & Button
      expect(find.text('Password not set'), findsNothing);
      expect(find.text('Set up your password'), findsNothing);
    });
  });

  group('AccountSettingsScreen', () {
    testWidgets('shows Change Password for account with password', (tester) async {
      authController.currentUser.value = const UserEntity(
        id: 'u1',
        fullName: 'Local User',
        username: 'local_user',
        email: 'local@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
        hasPassword: true,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightFor('en'),
          home: const AccountSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Password not set'), findsNothing);
    });

    testWidgets('shows Password and Password not set for Google account without password', (tester) async {
      authController.currentUser.value = const UserEntity(
        id: 'u2',
        fullName: 'Google User',
        username: 'google_user',
        email: 'google@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
        hasPassword: false,
        authProvider: 'GOOGLE',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightFor('en'),
          home: const AccountSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Password not set'), findsOneWidget);
      expect(find.text('Change Password'), findsNothing);
    });
  });
}
