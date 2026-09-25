import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/portfolio_screen.dart';
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

void main() {
  late _MockProfileRepository repository;
  late ProfileController controller;

  setUp(() {
    repository = _MockProfileRepository();
    when(repository.getMyProfile).thenAnswer((_) async => _profile);
    when(repository.getMyInterests).thenAnswer((_) async => []);
    when(repository.getInterestCatalog).thenAnswer((_) async => []);
    when(repository.getPortfolio).thenAnswer((_) async => []);
    when(repository.getSocialLinks).thenAnswer((_) async => []);
    when(repository.getBadges).thenAnswer((_) async => []);
    when(repository.getSavedItems).thenAnswer((_) async => []);
    when(
      () => repository.createPortfolioItem(
        title: any(named: 'title'),
        description: any(named: 'description'),
        link: any(named: 'link'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).thenAnswer(
      (_) async => const PortfolioItemEntity(
        portfolioId: 'p1',
        title: 'New Project',
      ),
    );

    controller = ProfileController(repository: repository);
    Get.put<ProfileController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Open add portfolio dialog and tap cancel without errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    PortfolioScreen.showEditDialog(context, controller),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open the dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed without any assertion error
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Open add portfolio dialog and save item calls addPortfolioItem', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    PortfolioScreen.showEditDialog(context, controller),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Enter title
    await tester.enterText(find.byType(TextField).first, 'My Awesome App');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dialog dismissed and repository called
    expect(find.byType(AlertDialog), findsNothing);
    verify(
      () => repository.createPortfolioItem(
        title: 'My Awesome App',
        description: any(named: 'description'),
        link: any(named: 'link'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).called(1);
  });

  testWidgets('Save with empty title shows validation error and does not call repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    PortfolioScreen.showEditDialog(context, controller),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Tap Save without entering title
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dialog should stay open and show validation error
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);
    verifyNever(
      () => repository.createPortfolioItem(
        title: any(named: 'title'),
        description: any(named: 'description'),
        link: any(named: 'link'),
        imageUrl: any(named: 'imageUrl'),
      ),
    );
  });
}
