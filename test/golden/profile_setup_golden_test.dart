import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_setup_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// Mirrors the seeded catalog in 0017-add-interests-and-social-links.sql.
final _catalog = <InterestEntity>[
  const InterestEntity(
      interestId: '1', code: 'TECHNOLOGY', name: 'Technology',
      category: 'CAREER'),
  const InterestEntity(
      interestId: '2', code: 'DESIGN', name: 'Design', category: 'CAREER'),
  const InterestEntity(
      interestId: '3', code: 'FINANCE', name: 'Finance', category: 'FINANCE'),
  const InterestEntity(
      interestId: '4', code: 'EDUCATION', name: 'Education',
      category: 'EDUCATION'),
  const InterestEntity(
      interestId: '5', code: 'HEALTH', name: 'Health', category: 'LIFESTYLE'),
  const InterestEntity(
      interestId: '6', code: 'MUSIC', name: 'Music',
      category: 'ENTERTAINMENT'),
  const InterestEntity(
      interestId: '7', code: 'VOLUNTEERING', name: 'Volunteering',
      category: 'COMMUNITY'),
];

void main() {
  const phone = Size(390, 844);

  setUp(() {
    final repository = _MockProfileRepository();
    when(repository.getInterestCatalog).thenAnswer((_) async => _catalog);

    Get.put<ProfileSetupController>(
      ProfileSetupController(repository: repository),
    );
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: AppTheme.lightFor('en'),
        home: const ProfileSetupScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final step in [1, 2, 3]) {
    testWidgets('profile setup step $step', (tester) async {
      Get.find<ProfileSetupController>().goToStep(step);
      await pumpScreen(tester);
      await expectLater(
        find.byType(ProfileSetupScreen),
        matchesGoldenFile('goldens/profile_setup_$step.png'),
      );
    });
  }
}
