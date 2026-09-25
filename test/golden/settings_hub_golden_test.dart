import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/achievements_screen.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/saved_items_screen.dart';
import 'package:genlink_frontend/features/settings/domain/entities/user_settings_entity.dart';
import 'package:genlink_frontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:genlink_frontend/features/settings/presentation/controllers/settings_controller.dart';
import 'package:genlink_frontend/features/settings/presentation/screens/about_screen.dart';
import 'package:genlink_frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockThemeController extends Mock implements ThemeController {}

class _MockLocalizationService extends Mock implements LocalizationService {}

const _user = UserEntity(
  id: 'u1',
  fullName: 'Sopheap Ren',
  username: 'sopheap.ren',
  email: 'sopheap@genlink.kh',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 1240,
  level: 13,
  preferredLanguage: 'ENGLISH',
  role: 'USER',
  active: true,
);

const _profile = ProfileEntity(
  userId: 'u1',
  fullName: 'Sopheap Ren',
  username: 'sopheap.ren',
  email: 'sopheap@genlink.kh',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 1240,
  level: 13,
  preferredLanguage: 'ENGLISH',
);

void main() {
  const phone = Size(390, 900);

  late _MockProfileRepository profileRepository;
  late _MockSettingsRepository settingsRepository;
  late _MockThemeController themeController;
  late _MockLocalizationService localization;

  setUp(() {
    profileRepository = _MockProfileRepository();
    settingsRepository = _MockSettingsRepository();
    themeController = _MockThemeController();
    localization = _MockLocalizationService();
    when(
      () => themeController.backendTheme,
    ).thenReturn(UserSettingsEntity.themeSystem);
    when(
      () => localization.language,
    ).thenReturn(UserSettingsEntity.languageEnglish.obs);
    when(
      settingsRepository.getSettings,
    ).thenAnswer((_) async => const UserSettingsEntity());
    when(
      () => themeController.applyBackendTheme(any()),
    ).thenAnswer((_) async {});
    when(profileRepository.getMyProfile).thenAnswer((_) async => _profile);
    when(profileRepository.getMyInterests).thenAnswer((_) async => []);
    when(profileRepository.getPortfolio).thenAnswer((_) async => []);
    when(profileRepository.getSocialLinks).thenAnswer((_) async => []);
    when(profileRepository.getBadges).thenAnswer(
      (_) async => const [
        BadgeEntity(badgeId: 'b1', name: 'Early Bird', earned: true),
        BadgeEntity(badgeId: 'b2', name: 'Verified', earned: true),
        BadgeEntity(
          badgeId: 'b3',
          name: 'Mentor',
          earned: false,
          requirement: 'Help 5 members',
        ),
      ],
    );
    when(profileRepository.getSavedItems).thenAnswer(
      (_) async => const [
        SavedItemEntity(
          savedItemId: 's1',
          itemType: 'LESSON',
          itemId: 'x1',
          available: true,
          title: 'Design Guild Weekly Recap',
        ),
        SavedItemEntity(
          savedItemId: 's2',
          itemType: 'EVENT',
          itemId: 'x2',
          available: true,
          title: 'GenLink Community Event',
        ),
      ],
    );

    Get
      ..put<AuthController>(
        AuthController(
          authRepository: _MockAuthRepository(),
          secureStorage: SecureStorage(),
          localization: localization,
        )..currentUser.value = _user,
      )
      ..put<ProfileController>(ProfileController(repository: profileRepository))
      ..put<SettingsController>(
        SettingsController(
          repository: settingsRepository,
          themeController: themeController,
          localization: localization,
        ),
      );
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
  }) async {
    await tester.pump();

    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: theme ?? AppTheme.lightFor('en'),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings hub', (tester) async {
    await pumpScreen(tester, const SettingsScreen());
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_hub.png'),
    );
  });

  testWidgets('settings hub (dark)', (tester) async {
    await pumpScreen(
      tester,
      const SettingsScreen(),
      theme: AppTheme.darkFor('en'),
    );
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_hub_dark.png'),
    );
  });

  testWidgets('about screen', (tester) async {
    await pumpScreen(tester, const AboutScreen());
    await expectLater(
      find.byType(AboutScreen),
      matchesGoldenFile('goldens/about.png'),
    );
  });

  testWidgets('about screen (dark)', (tester) async {
    await pumpScreen(
      tester,
      const AboutScreen(),
      theme: AppTheme.darkFor('en'),
    );
    await expectLater(
      find.byType(AboutScreen),
      matchesGoldenFile('goldens/about_dark.png'),
    );
  });

  testWidgets('about screen opens licenses', (tester) async {
    await pumpScreen(tester, const AboutScreen());
    final licenseAction = find.text('View open-source licenses');
    await tester.scrollUntilVisible(
      licenseAction,
      320,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(licenseAction);
    await tester.pumpAndSettle();

    expect(find.text('Licenses'), findsOneWidget);
  });

  testWidgets('achievements', (tester) async {
    await pumpScreen(tester, const AchievementsScreen());
    await expectLater(
      find.byType(AchievementsScreen),
      matchesGoldenFile('goldens/achievements.png'),
    );
  });

  testWidgets('saved items', (tester) async {
    await pumpScreen(tester, const SavedItemsScreen());
    await expectLater(
      find.byType(SavedItemsScreen),
      matchesGoldenFile('goldens/saved_items.png'),
    );
  });
}
