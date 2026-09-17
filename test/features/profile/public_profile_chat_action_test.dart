import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
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
  String? openedUserId;
  String? openedName;
  String? openedAvatar;
  ChatConversationModel? resultToReturn;

  @override
  Future<ChatConversationModel?> openPrivateChat(
    String targetUserId, {
    String? name,
    String? avatar,
  }) async {
    openedUserId = targetUserId;
    openedName = name;
    openedAvatar = avatar;
    return resultToReturn;
  }

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

  group('Public Profile Action Row - Chat Integration & Height 44', () {
    late _MockProfileRepository mockProfileRepo;
    late _FakeChatController fakeChatController;
    late ProfileController profileController;

    setUp(() {
      mockProfileRepo = _MockProfileRepository();
      fakeChatController = _FakeChatController();
      Get.put<ChatController>(fakeChatController);
    });

    testWidgets('Renders Follow button and Chat button with height 44 and correct icons', (tester) async {
      const publicProfile = PublicProfileEntity(
        userId: 'user-other-456',
        fullName: 'Dara Chan',
        username: 'darachan',
        avatarUrl: 'https://example.com/dara.jpg',
        totalXp: 120,
        level: 3,
      );

      when(() => mockProfileRepo.getPublicProfile('darachan'))
          .thenAnswer((_) async => publicProfile);
      when(() => mockProfileRepo.getFollowStats('user-other-456'))
          .thenAnswer((_) async => const FollowStatsEntity(
                followers: 42,
                following: 18,
                friend: false,
              ));

      profileController = ProfileController(
        repository: mockProfileRepo,
        viewingUsername: 'darachan',
      );
      Get.put<ProfileController>(
        profileController,
        tag: ProfileController.publicTag('darachan'),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const ProfileScreen(viewingUsername: 'darachan'),
        ),
      );

      await tester.pumpAndSettle();

      // Find the buttons
      final buttons = tester.widgetList<AppButton>(find.byType(AppButton)).toList();
      expect(buttons.length, greaterThanOrEqualTo(2));

      // Check Follow button
      final followButton = buttons.firstWhere((b) => b.label == 'Follow' || b.label == 'profile.follow'.tr);
      expect(followButton.height, 44);

      // Check Chat button
      final chatButton = buttons.firstWhere((b) => b.label == 'Chat' || b.label == 'profile.chat'.tr);
      expect(chatButton.height, 44);
      expect(chatButton.icon, Icons.chat_bubble_outline_rounded);
    });

    testWidgets('Tapping Chat button triggers openPrivateChat and navigates to chatDetail', (tester) async {
      const publicProfile = PublicProfileEntity(
        userId: 'user-other-456',
        fullName: 'Dara Chan',
        username: 'darachan',
        avatarUrl: 'https://example.com/dara.jpg',
        totalXp: 120,
        level: 3,
      );

      when(() => mockProfileRepo.getPublicProfile('darachan'))
          .thenAnswer((_) async => publicProfile);
      when(() => mockProfileRepo.getFollowStats('user-other-456'))
          .thenAnswer((_) async => const FollowStatsEntity(
                followers: 42,
                following: 18,
                friend: false,
              ));

      fakeChatController.resultToReturn = ChatConversationModel(
        id: 'room-dara-123',
        name: 'Dara Chan',
        avatar: 'https://example.com/dara.jpg',
        lastMessage: 'Hello',
        lastMessageTime: 'Just now',
      );

      profileController = ProfileController(
        repository: mockProfileRepo,
        viewingUsername: 'darachan',
      );
      Get.put<ProfileController>(
        profileController,
        tag: ProfileController.publicTag('darachan'),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/profile',
          getPages: [
            GetPage(name: '/profile', page: () => const ProfileScreen(viewingUsername: 'darachan')),
            GetPage(name: AppRoutes.chatDetail, page: () => const Scaffold(body: Text('Chat Detail Screen'))),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find Chat button and tap it
      final chatButtonFinder = find.widgetWithText(AppButton, 'Chat');
      expect(chatButtonFinder, findsOneWidget);

      await tester.tap(chatButtonFinder);
      await tester.pumpAndSettle();

      // Verify openPrivateChat was called with correct parameters
      expect(fakeChatController.openedUserId, 'user-other-456');
      expect(fakeChatController.openedName, 'Dara Chan');
      expect(fakeChatController.openedAvatar, 'https://example.com/dara.jpg');

      // Verify navigation to chatDetail
      expect(find.text('Chat Detail Screen'), findsOneWidget);
    });
  });
}
