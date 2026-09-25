import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/headers/app_screen_header.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:mocktail/mocktail.dart';

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

class _FakeChatController extends GetxController implements ChatController {
  @override
  final Rxn<ChatConversationModel> activeConversation = Rxn<ChatConversationModel>();
  @override
  final RxnString activeRoomId = RxnString();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  tearDown(() {
    Get.reset();
  });

  group('Public Profile Header Title & Back Button Spacing', () {
    late _MockProfileRepository mockProfileRepo;
    late _FakeChatController fakeChatController;

    setUp(() {
      mockProfileRepo = _MockProfileRepository();
      fakeChatController = _FakeChatController();
      Get.put<ChatController>(fakeChatController);
    });

    testWidgets('Header displays profile fullName instead of Public Profile', (tester) async {
      const publicProfile = PublicProfileEntity(
        userId: 'user-sokha-789',
        fullName: 'Sokha Meng',
        username: 'sokhameng',
        avatarUrl: 'https://example.com/sokha.jpg',
        totalXp: 500,
        level: 5,
      );

      when(() => mockProfileRepo.getPublicProfile('sokhameng'))
          .thenAnswer((_) async => publicProfile);
      when(() => mockProfileRepo.getFollowStats('user-sokha-789'))
          .thenAnswer((_) async => const FollowStatsEntity(
                followers: 120,
                following: 85,
                friend: true,
              ));

      final profileController = ProfileController(
        repository: mockProfileRepo,
        viewingUsername: 'sokhameng',
      );
      Get.put<ProfileController>(
        profileController,
        tag: ProfileController.publicTag('sokhameng'),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const ProfileScreen(viewingUsername: 'sokhameng'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that "Public Profile" is NOT displayed as the title
      expect(find.text('Public Profile'), findsNothing);

      // Verify that the user's name is displayed in the header
      expect(find.text('Sokha Meng'), findsWidgets);

      // Verify AppScreenHeader configuration has 16px leadingGap
      final headerFinder = find.byType(AppScreenHeader);
      expect(headerFinder, findsOneWidget);
      final header = tester.widget<AppScreenHeader>(headerFinder);
      expect(header.leadingGap, AppSpacing.md);
      expect(header.leading, isA<AppBackButton>());
    });

    testWidgets('Header falls back to @username when fullName is empty', (tester) async {
      const publicProfile = PublicProfileEntity(
        userId: 'user-noname-123',
        fullName: '   ',
        username: 'anonymous_user',
        totalXp: 10,
        level: 1,
      );

      when(() => mockProfileRepo.getPublicProfile('anonymous_user'))
          .thenAnswer((_) async => publicProfile);
      when(() => mockProfileRepo.getFollowStats('user-noname-123'))
          .thenAnswer((_) async => const FollowStatsEntity(
                followers: 0,
                following: 0,
                friend: false,
              ));

      final profileController = ProfileController(
        repository: mockProfileRepo,
        viewingUsername: 'anonymous_user',
      );
      Get.put<ProfileController>(
        profileController,
        tag: ProfileController.publicTag('anonymous_user'),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const ProfileScreen(viewingUsername: 'anonymous_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('@anonymous_user'), findsWidgets);
    });

    testWidgets('Header displays @resolvedUsername while profile data is loading', (tester) async {
      final completer = Completer<PublicProfileEntity>();

      when(() => mockProfileRepo.getPublicProfile('pending_user'))
          .thenAnswer((_) => completer.future);
      when(() => mockProfileRepo.getFollowStats(any()))
          .thenAnswer((_) async => const FollowStatsEntity(
                followers: 0,
                following: 0,
                friend: false,
              ));

      final profileController = ProfileController(
        repository: mockProfileRepo,
        viewingUsername: 'pending_user',
      );
      Get.put<ProfileController>(
        profileController,
        tag: ProfileController.publicTag('pending_user'),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const ProfileScreen(viewingUsername: 'pending_user'),
        ),
      );

      // Pump 1 frame without settling (loading state)
      await tester.pump();

      expect(find.text('@pending_user'), findsOneWidget);

      // Now complete data load
      completer.complete(const PublicProfileEntity(
        userId: 'user-loaded-1',
        fullName: 'Loaded User',
        username: 'pending_user',
        totalXp: 50,
        level: 2,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Loaded User'), findsWidgets);
    });
  });
}
