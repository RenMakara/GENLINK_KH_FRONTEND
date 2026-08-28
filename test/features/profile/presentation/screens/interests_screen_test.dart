import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/interests_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

const _profile = ProfileEntity(
  userId: 'u1',
  fullName: 'Ren Makara',
  username: 'ren',
  email: 'ren@example.com',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 0,
  level: 1,
  preferredLanguage: 'ENGLISH',
);

const _catalog = [
  InterestEntity(
    interestId: 'i1',
    code: 'DESIGN',
    name: 'UX Design',
    category: 'CAREER',
  ),
  InterestEntity(
    interestId: 'i2',
    code: 'FINTECH',
    name: 'FinTech',
    category: 'FINANCE',
  ),
];

void main() {
  late _MockProfileRepository repository;

  setUp(() {
    repository = _MockProfileRepository();
    when(repository.getMyProfile).thenAnswer((_) async => _profile);
    when(repository.getMyInterests).thenAnswer((_) async => [_catalog.first]);
    when(repository.getInterestCatalog).thenAnswer((_) async => _catalog);
    when(repository.getPortfolio).thenAnswer((_) async => []);
    when(repository.getSocialLinks).thenAnswer((_) async => []);
    when(repository.getBadges).thenAnswer((_) async => []);
    when(repository.getSavedItems).thenAnswer((_) async => []);
    when(() => repository.replaceInterests(any())).thenAnswer((
      invocation,
    ) async {
      final ids = invocation.positionalArguments.first as List<String>;
      return _catalog.where((item) => ids.contains(item.interestId)).toList();
    });
    Get.put<ProfileController>(ProfileController(repository: repository));
  });

  tearDown(Get.reset);

  testWidgets('search adds a catalog interest and save replaces ids', (
    tester,
  ) async {
    await Get.find<ProfileController>().load();
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        home: const InterestsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expertise-search')),
      'FinTech',
    );
    await tester.tap(find.byKey(const ValueKey('expertise-add')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('expertise-save')));
    await tester.pumpAndSettle();

    verify(
      () => repository.replaceInterests(
        any(that: containsAll(<String>['i1', 'i2'])),
      ),
    ).called(1);
  });
}
