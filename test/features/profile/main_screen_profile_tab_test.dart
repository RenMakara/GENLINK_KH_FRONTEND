import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/home/data/home_repository.dart';
import 'package:genlink_frontend/features/home/domain/entities/home_entity.dart';
import 'package:genlink_frontend/features/home/presentation/controllers/home_controller.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:genlink_frontend/main_controller.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}
class _MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late _MockProfileRepository mockProfileRepository;
  late _MockHomeRepository mockHomeRepository;

  final testProfile = ProfileEntity(
    userId: 'user-me-123',
    fullName: 'Test Owner',
    username: 'testowner',
    email: 'test@example.com',
    emailVerified: true,
    accountStatus: 'ACTIVE',
    totalXp: 120,
    level: 2,
    preferredLanguage: 'en',
  );

  final testHome = const HomeEntity(
    user: HomeUser(
      userId: 'user-me-123',
      fullName: 'Test Owner',
      level: 2,
      totalXp: 120,
    ),
    todayProgress: TodayProgress(
      habitsCompletedToday: 0,
      habitsTotal: 0,
      tasksCompleted: 0,
      tasksTotal: 0,
    ),
    dailyChallenge: ChallengePreview(
      challengeId: 'ch-1',
      title: 'Daily Challenge',
      description: 'Description',
      xpReward: 10,
    ),
  );

  setUp(() {
    Get.reset();
    mockProfileRepository = _MockProfileRepository();
    mockHomeRepository = _MockHomeRepository();
    Get.put<ProfileRepository>(mockProfileRepository);
    Get.put<HomeRepository>(mockHomeRepository);
    Get.put<HomeController>(HomeController(repository: mockHomeRepository));
    Get.put<MainController>(MainController());
    Get.put<CommunityController>(CommunityController());

    when(() => mockHomeRepository.getHome()).thenAnswer((_) async => testHome);
    when(() => mockProfileRepository.getMyProfile()).thenAnswer((_) async => testProfile);
    when(() => mockProfileRepository.getMyInterests()).thenAnswer((_) async => []);
    when(() => mockProfileRepository.getPortfolio()).thenAnswer((_) async => []);
    when(() => mockProfileRepository.getSocialLinks()).thenAnswer((_) async => []);
    when(() => mockProfileRepository.getBadges()).thenAnswer((_) async => []);
    when(() => mockProfileRepository.getSavedItems()).thenAnswer((_) async => []);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'ProfileScreen builds in embedded stack without "ProfileController not found" exception',
    (tester) async {
      // Ensure ProfileController is not pre-registered
      expect(Get.isRegistered<ProfileController>(), isFalse);

      // Simulate stale route parameters in Get.parameters
      Get.parameters = {'username': 'stale_other_user'};

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: LocalizationService.englishLocale,
          theme: AppTheme.light,
          home: const Scaffold(
            body: ProfileScreen(),
          ),
        ),
      );

      // Settle frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Test Owner'), findsWidgets);
      expect(find.text('@testowner'), findsOneWidget);

      Get.parameters = {};
    },
  );
}
