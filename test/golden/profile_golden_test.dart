import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

const _profile = ProfileEntity(
  userId: 'u1',
  fullName: 'Ren Makara',
  username: 'ren_makara',
  email: 'makara.it@email.com',
  bio: 'Digital architect exploring the intersection of Khmer tradition '
      'and future tech.',
  location: 'Phnom Penh',
  universityName: 'Paragon International University',
  workStatus: 'ENTREPRENEUR',
  avatarUrl: null,
  emailVerified: true,
  accountStatus: 'ACTIVE',
  // level must agree with the backend formula: 1 + totalXp / 100
  totalXp: 1250,
  level: 13,
  preferredLanguage: 'ENGLISH',
);

final _badges = <BadgeEntity>[
  const BadgeEntity(badgeId: 'b1', name: 'Early Bird', earned: true),
  const BadgeEntity(badgeId: 'b2', name: 'Verified', earned: true),
  const BadgeEntity(badgeId: 'b3', name: 'Top Skill', earned: true),
  const BadgeEntity(badgeId: 'b4', name: 'Mentor', earned: true),
  const BadgeEntity(badgeId: 'b5', name: 'Locked', earned: false),
];

final _interests = <InterestEntity>[
  const InterestEntity(interestId: 'i1', code: 'UX', name: 'UX Strategy'),
  const InterestEntity(
      interestId: 'i2', code: 'FIN', name: 'Fintech Analysis'),
  const InterestEntity(interestId: 'i3', code: 'VIS', name: 'Visual Design'),
  const InterestEntity(interestId: 'i4', code: 'PM', name: 'Project Mgmt'),
];

final _saved = <SavedItemEntity>[
  const SavedItemEntity(
    savedItemId: 's1',
    itemType: 'LESSON',
    itemId: 'x1',
    available: true,
    title: 'Investment Guide for Beginners',
  ),
  const SavedItemEntity(
    savedItemId: 's2',
    itemType: 'DISCUSSION',
    itemId: 'x2',
    available: true,
    title: 'Design Ethics in Asia',
  ),
];

void main() {
  const phone = Size(390, 900);

  late _MockProfileRepository repository;

  setUp(() {
    repository = _MockProfileRepository();
    when(repository.getMyProfile).thenAnswer((_) async => _profile);
    when(repository.getMyInterests).thenAnswer((_) async => _interests);
    when(repository.getPortfolio).thenAnswer((_) async => []);
    when(repository.getSocialLinks).thenAnswer((_) async => []);
    when(repository.getBadges).thenAnswer((_) async => _badges);
    when(repository.getSavedItems).thenAnswer((_) async => _saved);

    Get
      // Constructing LocalStorage does not touch the platform channel, and
      // these screens never read from it.
      ..put<LocalizationService>(
        LocalizationService(localStorage: LocalStorage()),
      )
      ..put<ProfileController>(ProfileController(repository: repository));
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: AppTheme.lightFor('en'),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('profile', (tester) async {
    await pumpScreen(tester, const ProfileScreen());
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('goldens/profile.png'),
    );
  });

  testWidgets('edit profile', (tester) async {
    await pumpScreen(tester, const EditProfileScreen());
    await expectLater(
      find.byType(EditProfileScreen),
      matchesGoldenFile('goldens/edit_profile.png'),
    );
  });
}
