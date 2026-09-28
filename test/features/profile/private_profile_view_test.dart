import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:genlink_frontend/features/profile/presentation/widgets/private_profile_view.dart';

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
    return super.noSuchMethod(invocation);
  }
}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _FakeChatController extends GetxController implements ChatController {
  @override
  final Rxn<ChatConversationModel> activeConversation =
      Rxn<ChatConversationModel>();
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
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  tearDown(() {
    Get.reset();
  });

  group('PrivateProfileView Widget Tests', () {
    testWidgets('renders Soft 3D lock, headline, subtitle, and Got it button', (
      tester,
    ) async {
      var gotItPressed = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PrivateProfileView(
              displayName: 'Makara Thapa',
              onGotIt: () {
                gotItPressed = true;
              },
            ),
          ),
        ),
      );

      // Verify Soft 3D Lock Widget is present
      expect(find.byType(Soft3DPrivateLockWidget), findsOneWidget);

      // Verify Headline
      expect(find.text('This profile is private'), findsOneWidget);

      // Verify Subtitle contains user name and exact notice text
      expect(
        find.text(
          "Makara Thapa has chosen to keep their profile open only to themselves, so their content isn't visible to others.",
        ),
        findsOneWidget,
      );

      // Verify "Got it" button
      expect(find.text('Got it'), findsOneWidget);

      // Tap "Got it" button
      await tester.tap(find.text('Got it'));
      await tester.pump();

      expect(gotItPressed, isTrue);
    });

    testWidgets('renders friends-only notice when isFriendsOnly is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: PrivateProfileView(
              displayName: 'Sok Kha',
              isFriendsOnly: true,
            ),
          ),
        ),
      );

      expect(find.text('This profile is private'), findsOneWidget);
      expect(
        find.text(
          "Sok Kha has chosen to make their profile visible to friends only, so their content isn't visible to others.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Khmer translations properly', (tester) async {
      Get.locale = const Locale('km', 'KH');

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const Scaffold(
            body: PrivateProfileView(
              displayName: 'មករា',
            ),
          ),
        ),
      );

      // Verify Khmer Headline
      expect(find.text('គណនីនេះត្រូវបានកំណត់ជាឯកជន'), findsOneWidget);

      // Verify Khmer "Got it"
      expect(find.text('យល់ព្រម'), findsOneWidget);
    });
  });

  group('ProfileScreen Private Profile Integration', () {
    late _MockProfileRepository mockProfileRepo;
    late _FakeChatController fakeChatController;

    setUp(() {
      mockProfileRepo = _MockProfileRepository();
      fakeChatController = _FakeChatController();
      Get.put<ChatController>(fakeChatController);
    });

    testWidgets(
      'ProfileScreen displays PrivateProfileView when profile throws PROFILE_PRIVATE',
      (tester) async {
        when(() => mockProfileRepo.getPublicProfile('makara_thapa')).thenThrow(
          const AppError(
            message: 'This profile is private',
            errorCode: 'PROFILE_PRIVATE',
            statusCode: 400,
          ),
        );

        final controller = ProfileController(
          repository: mockProfileRepo,
          viewingUsername: 'makara_thapa',
        );
        Get.put<ProfileController>(
          controller,
          tag: ProfileController.publicTag('makara_thapa'),
        );

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const ProfileScreen(viewingUsername: 'makara_thapa'),
          ),
        );

        await tester.pump();

        // Verify that controller detected isPrivate
        expect(controller.isPrivate.value, isTrue);

        // Verify PrivateProfileView is rendered instead of generic AppEmptyState
        expect(find.byType(PrivateProfileView), findsOneWidget);
        expect(find.text('This profile is private'), findsOneWidget);
        expect(find.text('Got it'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      },
    );
  });
}
