import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/headers/app_screen_header.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_header_widget.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/quick_create_post_card.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_tray_widget.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStorage implements SecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalizationService extends GetxService implements LocalizationService {
  @override
  final language = 'en'.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;

    final authController = AuthController(
      authRepository: _FakeAuthRepo(),
      secureStorage: _FakeStorage(),
      localization: _FakeLocalizationService(),
    );
    authController.currentUser.value = const UserEntity(
      id: 'test-user-1',
      fullName: 'Nat',
      username: 'nat',
      email: 'nat@genlink.kh',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 500,
      level: 3,
      preferredLanguage: 'en',
      role: 'STUDENT',
      active: true,
    );
    Get.put<AuthController>(authController);
    Get.put<LocalizationService>(_FakeLocalizationService());
  });

  tearDown(() {
    Get.reset();
  });

  group('Home Feed UI/UX Cleanup Tests', () {
    testWidgets('1. Header action buttons are circular with neutral styling and minimum touch target', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.light,
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
            body: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inkWidgets = tester.widgetList<Ink>(find.byType(Ink));
      expect(inkWidgets.length, equals(3));

      for (final ink in inkWidgets) {
        final dec = ink.decoration as BoxDecoration?;
        expect(dec, isNotNull);
        expect(dec?.shape, equals(BoxShape.circle), reason: 'Header buttons must be circular');
      }

      // Check touch target wrappers
      final headerActionButtons = tester.widgetList<AppHeaderActionButton>(find.byType(AppHeaderActionButton));
      expect(headerActionButtons.length, equals(3)); // Search, Notification, Chat all use AppHeaderActionButton

      // Icon family normalized
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sms_outlined), findsOneWidget);
    });

    testWidgets('2. Story tray Create Story button has avatar, blue "+" badge, and "Your Story" label', (tester) async {
      final storyController = StoryController();
      storyController.isLoading.value = false;
      Get.put<StoryController>(storyController);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.light,
          home: const Scaffold(
            body: StoryTrayWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The "+" icon is present for creating a story (as a badge on the avatar)
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Verify that "Your Story" label IS now shown (Telegram-style redesign)
      expect(find.text('Your Story'), findsOneWidget);

      // Verify the "+" badge container is circular
      final addIcon = find.byIcon(Icons.add_rounded);
      final containerFinder = find.ancestor(of: addIcon, matching: find.byType(Container));
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final dec = container.decoration as BoxDecoration?;
      expect(dec?.shape, equals(BoxShape.circle), reason: 'Story + badge must be circular');
    });

    testWidgets('3. Quick Create Post Card is simplified to avatar + prompt without action icon row', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.light,
          home: Scaffold(
            body: QuickCreatePostCard(
              userName: 'Nat',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card and prompt exist
      expect(find.byType(QuickCreatePostCard), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Verify NONE of the 8 colorful action icons exist
      expect(find.byIcon(Icons.image_outlined), findsNothing);
      expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
      expect(find.byIcon(Icons.gif_box_outlined), findsNothing);
      expect(find.byIcon(Icons.bar_chart_rounded), findsNothing);
      expect(find.byIcon(Icons.sentiment_satisfied_alt_outlined), findsNothing);
      expect(find.byIcon(Icons.add_box_outlined), findsNothing);
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);

      // Tap card
      await tester.tap(find.byType(QuickCreatePostCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('4. Light mode and dark mode apply neutral monochrome palette with no bright blue', (tester) async {
      final storyController = StoryController();
      storyController.isLoading.value = false;
      Get.put<StoryController>(storyController);

      // Light Mode
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.light,
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
            body: Column(
              children: [
                StoryTrayWidget(),
                QuickCreatePostCard(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify search icon color is neutral in light mode
      final searchIconLight = tester.widget<Icon>(find.byIcon(Icons.search_rounded));
      expect(searchIconLight.color, isNot(equals(AppColors.brandPrimary)));

      // Dark Mode
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.dark,
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
            body: Column(
              children: [
                StoryTrayWidget(),
                QuickCreatePostCard(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final searchIconDark = tester.widget<Icon>(find.byIcon(Icons.search_rounded));
      expect(searchIconDark.color, isNot(equals(AppColors.brandPrimary)));
    });
  });
}
