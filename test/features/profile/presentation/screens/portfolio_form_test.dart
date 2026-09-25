import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/portfolio_form_screen.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) return null;
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final _kTransparentPng = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  late _MockProfileRepository repository;
  late ProfileController controller;

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');

    repository = _MockProfileRepository();
    when(() => repository.getMyProfile()).thenAnswer(
      (_) async => const ProfileEntity(
        userId: 'user-1',
        fullName: 'Test User',
        username: 'testuser',
        email: 'test@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
      ),
    );
    when(() => repository.getFollowStats(any())).thenAnswer(
      (_) async => const FollowStatsEntity(
        followers: 0,
        following: 0,
        friend: false,
      ),
    );
    when(() => repository.getMyInterests()).thenAnswer((_) async => []);
    when(() => repository.getPortfolio()).thenAnswer((_) async => []);
    when(() => repository.getSocialLinks()).thenAnswer((_) async => []);
    when(() => repository.getBadges()).thenAnswer((_) async => []);
    when(() => repository.getSavedItems()).thenAnswer((_) async => []);

    controller = ProfileController(repository: repository);
    Get.put<ProfileController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('PortfolioFormScreen displays Add item title and empty fields in create mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const PortfolioFormScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add item'), findsOneWidget);
    expect(find.text('Create Project'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4)); // cover URL, title, link, description
  });

  testWidgets('Save with empty title shows inline error and does not call repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const PortfolioFormScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Save button in AppBar
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    verifyNever(() => repository.createPortfolioItem(
          title: any(named: 'title'),
          description: any(named: 'description'),
          link: any(named: 'link'),
          imageUrl: any(named: 'imageUrl'),
        ));
  });

  testWidgets('Save with valid title calls createPortfolioItem and pops screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const created = PortfolioItemEntity(
      portfolioId: 'proj-123',
      title: 'GenLink Platform',
      description: 'A social learning network',
      link: 'https://github.com/test/genlink',
      imageUrl: null,
    );

    when(
      () => repository.createPortfolioItem(
        title: 'GenLink Platform',
        description: any(named: 'description'),
        link: any(named: 'link'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).thenAnswer((_) async => created);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const PortfolioFormScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter title
    final titleFinder = find.widgetWithText(TextField, 'e.g. GenLink Mobile Platform');
    await tester.enterText(titleFinder, 'GenLink Platform');
    await tester.pumpAndSettle();

    // Tap Save in AppBar
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => repository.createPortfolioItem(
        title: 'GenLink Platform',
        description: any(named: 'description'),
        link: any(named: 'link'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).called(1);

    expect(controller.portfolio.length, 1);
    expect(controller.portfolio.first.title, 'GenLink Platform');
  });

  testWidgets('Prepopulates fields in edit mode and calls updatePortfolioItem', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const existing = PortfolioItemEntity(
      portfolioId: 'proj-456',
      title: 'Existing App',
      description: 'Initial description',
      link: 'https://example.com',
      imageUrl: 'https://example.com/cover.png',
    );

    const updated = PortfolioItemEntity(
      portfolioId: 'proj-456',
      title: 'Updated App',
      description: 'Initial description',
      link: 'https://example.com',
      imageUrl: 'https://example.com/cover.png',
    );

    when(
      () => repository.updatePortfolioItem(
        portfolioId: 'proj-456',
        title: 'Updated App',
        description: any(named: 'description'),
        link: any(named: 'link'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).thenAnswer((_) async => updated);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const PortfolioFormScreen(item: existing),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit item'), findsOneWidget);
    expect(find.text('Update Project'), findsOneWidget);
    expect(find.text('Existing App'), findsOneWidget);

    // Change title
    final titleFinder = find.widgetWithText(TextField, 'Existing App');
    await tester.enterText(titleFinder, 'Updated App');
    await tester.pumpAndSettle();

    // Tap Save in AppBar
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => repository.updatePortfolioItem(
        portfolioId: 'proj-456',
        title: 'Updated App',
        description: any(named: 'description'),
        link: any(named: 'link'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).called(1);
  });
}
