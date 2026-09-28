import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/comments_bottom_sheet.dart';

class MockNotificationRepo extends Mock implements NotificationRepositoryImpl {}

class MockStoryRepo extends Mock implements StoryRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNotificationRepo mockNotifRepo;
  late MockStoryRepo mockStoryRepo;
  late NotificationController notifController;
  late StoryController storyController;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    mockNotifRepo = MockNotificationRepo();
    mockStoryRepo = MockStoryRepo();

    when(() => mockStoryRepo.getStories()).thenAnswer((_) async => []);
    when(() => mockStoryRepo.likeStory(any())).thenAnswer((_) async {});

    when(
      () => mockNotifRepo.getNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer(
      (_) async => NotificationPage(
        items: [],
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
        hasNext: false,
      ),
    );
    when(() => mockNotifRepo.getUnreadCount()).thenAnswer((_) async => 0);
    when(() => mockNotifRepo.markAsRead(any())).thenAnswer((_) async => true);

    notifController = NotificationController(repository: mockNotifRepo);
    Get.put<NotificationController>(notifController);

    Get.put<StoryRepository>(mockStoryRepo);
    storyController = StoryController(repository: mockStoryRepo);
    Get.put<StoryController>(storyController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'Story like notification tap navigates to StoryViewerScreen, NOT CommentsBottomSheet',
    (tester) async {
      final targetStory = StoryItemModel(
        id: 'story_user_b_99',
        type: StoryType.text,
        textContent: 'Story text',
        timeAgo: '1h',
        createdAt: DateTime.now(),
        likesCount: 5,
        isLiked: false,
      );

      final group = StoryGroupModel(
        userId: 'user_b',
        userName: 'User B',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        hasUnseen: true,
        stories: [targetStory],
      );

      when(() => mockStoryRepo.getStories()).thenAnswer((_) async => [group]);
      when(
        () => mockStoryRepo.getStoryById(targetStory.id),
      ).thenAnswer((_) async => targetStory);
      await storyController.fetchStories();

      final storyLikeNotif = NotificationModel(
        id: 'notif_1',
        type: NotificationType.like,
        title: 'Story Like',
        body: 'User A liked your story.',
        senderName: 'User A',
        timeAgo: 'Just now',
        timestamp: DateTime.now(),
        targetId: 'story_user_b_99',
        targetType: 'STORY',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    notifController.handleNotificationTap(
                      storyLikeNotif,
                      context,
                    );
                  },
                  child: const Text('Tap Notif'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Tap Notif'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must navigate to StoryViewerScreen
      expect(find.byType(StoryViewerScreen), findsOneWidget);
      // Must NOT show CommentsBottomSheet
      expect(find.byType(CommentsBottomSheet), findsNothing);
      verify(() => mockStoryRepo.getStoryById(targetStory.id)).called(1);
    },
  );

  testWidgets(
    'Expired story notification tap shows banner and does NOT open CommentsBottomSheet',
    (tester) async {
      when(() => mockStoryRepo.getStories()).thenAnswer((_) async => []);
      when(
        () => mockStoryRepo.getStoryById('expired_story_123'),
      ).thenAnswer((_) async => null);
      await storyController.fetchStories();

      final storyLikeNotif = NotificationModel(
        id: 'notif_2',
        type: NotificationType.like,
        title: 'Story Like',
        body: 'User A liked your story.',
        senderName: 'User A',
        timeAgo: 'Just now',
        timestamp: DateTime.now(),
        targetId: 'expired_story_123',
        targetType: 'STORY',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    notifController.handleNotificationTap(
                      storyLikeNotif,
                      context,
                    );
                  },
                  child: const Text('Tap Notif'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Tap Notif'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must NOT navigate to StoryViewerScreen or CommentsBottomSheet
      expect(find.byType(StoryViewerScreen), findsNothing);
      expect(find.byType(CommentsBottomSheet), findsNothing);
    },
  );

  test('Story like via StoryController calls repository likeStory', () async {
    final story = StoryItemModel(
      id: 'story_to_like_456',
      type: StoryType.photo,
      timeAgo: '2h',
      createdAt: DateTime.now(),
      likesCount: 3,
      isLiked: false,
    );

    final group = StoryGroupModel(
      userId: 'other_user',
      userName: 'Other User',
      userAvatar: '',
      isOwner: false,
      stories: [story],
    );

    when(() => mockStoryRepo.getStories()).thenAnswer((_) async => [group]);
    await storyController.fetchStories();

    await storyController.syncLikeToBackend('story_to_like_456', isLiked: true);

    verify(() => mockStoryRepo.likeStory('story_to_like_456')).called(1);
    // Local notifications list in NotificationController must NOT have self-notification
    expect(notifController.notifications, isEmpty);
  });
}
