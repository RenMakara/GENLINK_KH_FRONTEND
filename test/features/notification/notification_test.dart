import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/utils/date_formatter.dart';
import 'package:genlink_frontend/design_system/widgets/headers/app_screen_header.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/home_header_actions.dart';
import 'package:genlink_frontend/features/community/presentation/screens/friend_requests_screen.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';
import 'package:genlink_frontend/features/notification/presentation/screens/notification_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepo extends Mock
    implements NotificationRepositoryImpl {}

List<NotificationModel> _createComprehensiveSampleNotifications() {
  final now = DateTime.now();

  return [
    NotificationModel(
      id: 'n1',
      type: NotificationType.reply,
      category: NotificationCategory.social,
      title: 'Dara replied to your comment',
      body: '“Great idea!”',
      contextText: '“Great idea!”',
      senderName: 'Dara',
      senderAvatar: 'assets/images/user_profile.png',
      timeAgo: '2m ago',
      timestamp: now.subtract(const Duration(minutes: 2)),
      isRead: false,
      targetId: 'post_1',
      targetType: 'post',
    ),
    NotificationModel(
      id: 'n2',
      type: NotificationType.budgetWarning,
      category: NotificationCategory.finance,
      title: "You've used 80% of your budget",
      body: 'Food · \$80 of \$100',
      contextText: 'Food · \$80 of \$100',
      senderName: 'GenLink Finance',
      timeAgo: '15m ago',
      timestamp: now.subtract(const Duration(minutes: 15)),
      isRead: false,
      targetId: 'budget_1',
      targetType: 'budget',
    ),
    NotificationModel(
      id: 'n3',
      type: NotificationType.eventReminder,
      category: NotificationCategory.events,
      title: 'Flutter Workshop is tomorrow',
      body: '9:00 AM · ACLEDA University',
      contextText: '9:00 AM · ACLEDA University',
      senderName: 'Tech Club',
      timeAgo: '1h ago',
      timestamp: now.subtract(const Duration(hours: 1)),
      isRead: false,
      targetId: 'ev_1',
      targetType: 'event',
    ),
    NotificationModel(
      id: 'n4',
      type: NotificationType.habitReminder,
      category: NotificationCategory.reminders,
      title: 'Time to complete Morning Reading',
      body: 'Keep your streak going!',
      contextText: 'Keep your streak going!',
      senderName: 'GenLink Productivity',
      timeAgo: '2h ago',
      timestamp: now.subtract(const Duration(hours: 2)),
      isRead: false,
      targetId: 'habit_1',
      targetType: 'habit',
    ),
    NotificationModel(
      id: 'n5',
      type: NotificationType.friendRequest,
      category: NotificationCategory.social,
      title: 'Lina sent you a friend request',
      body: '2 mutual friends',
      contextText: '2 mutual friends',
      senderName: 'Lina',
      senderAvatar: 'assets/images/user_profile.png',
      timeAgo: '2h ago',
      timestamp: now.subtract(const Duration(hours: 2, minutes: 5)),
      isRead: false,
      targetId: 'user_lina',
      targetType: 'friend_request',
    ),

    NotificationModel(
      id: 'n6',
      type: NotificationType.like,
      category: NotificationCategory.social,
      title: 'Sokchea liked your post',
      body: 'Sokchea liked your post',
      senderName: 'Sokchea',
      senderAvatar: 'assets/images/user_profile.png',
      timeAgo: 'Yesterday',
      timestamp: now.subtract(const Duration(hours: 26)),
      isRead: true,
      targetId: 'post_2',
      targetType: 'post',
    ),
    NotificationModel(
      id: 'n7',
      type: NotificationType.quizResult,
      category: NotificationCategory.updates,
      title: 'Quiz result is ready!',
      body: 'You scored 85%',
      contextText: 'You scored 85%',
      senderName: 'Quiz Center',
      timeAgo: 'Yesterday',
      timestamp: now.subtract(const Duration(hours: 28)),
      isRead: true,
      targetId: 'quiz_1',
      targetType: 'quiz',
    ),
    NotificationModel(
      id: 'n8',
      type: NotificationType.savingGoal,
      category: NotificationCategory.finance,
      title: "You're 70% closer to your saving goal",
      body: 'Laptop Saving Goal',
      contextText: 'Laptop Saving Goal',
      senderName: 'GenLink Finance',
      timeAgo: 'Yesterday',
      timestamp: now.subtract(const Duration(hours: 30)),
      isRead: true,
      targetId: 'goal_1',
      targetType: 'saving_goal',
    ),

    NotificationModel(
      id: 'n9',
      type: NotificationType.achievement,
      category: NotificationCategory.updates,
      title: 'Achievement Unlocked: 7-Day Habit Streak',
      body: 'You completed all habits for 7 days',
      contextText: 'You completed all habits for 7 days',
      senderName: 'Rewards',
      timeAgo: '3d ago',
      timestamp: now.subtract(const Duration(days: 3)),
      isRead: true,
      targetId: 'ach_1',
      targetType: 'achievement',
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockNotificationRepo mockRepo;
  late NotificationController controller;

  setUp(() {
    Get.reset();
    mockRepo = _MockNotificationRepo();
    when(() => mockRepo.getNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        )).thenAnswer((_) async => NotificationPage(
          items: _createComprehensiveSampleNotifications(),
          page: 0,
          size: 20,
          totalElements: 9,
          totalPages: 1,
          hasNext: false,
        ));
    when(() => mockRepo.getUnreadCount()).thenAnswer((_) async => 5);
    when(() => mockRepo.markAsRead(any())).thenAnswer((_) async => true);
    when(() => mockRepo.markAllAsRead()).thenAnswer((_) async => true);
    when(() => mockRepo.deleteNotification(any())).thenAnswer((_) async => true);

    controller = NotificationController(repository: mockRepo);
    Get.put<NotificationController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  group('Unified NotificationController Unit Tests', () {
    test('initial fetch loads notifications and counts unread accurately', () async {
      await controller.fetchNotifications();
      expect(controller.notifications.length, 9);
      expect(controller.unreadCount, 5);
    });

    test('category filtering partitions into All, Social, Finance, Events, Reminders, Updates', () async {
      await controller.fetchNotifications();

      controller.selectCategory('All');
      expect(controller.filteredNotifications.length, 9);

      controller.selectCategory('Social');
      expect(controller.filteredNotifications.length, 3);
      expect(
        controller.filteredNotifications
            .every((n) => n.category == NotificationCategory.social),
        isTrue,
      );

      controller.selectCategory('Finance');
      expect(controller.filteredNotifications.length, 2);
      expect(
        controller.filteredNotifications
            .every((n) => n.category == NotificationCategory.finance),
        isTrue,
      );

      controller.selectCategory('Events');
      expect(controller.filteredNotifications.length, 1);
      expect(
        controller.filteredNotifications.first.type,
        NotificationType.eventReminder,
      );

      controller.selectCategory('Reminders');
      expect(controller.filteredNotifications.length, 1);
      expect(
        controller.filteredNotifications.first.type,
        NotificationType.habitReminder,
      );

      controller.selectCategory('Updates');
      expect(controller.filteredNotifications.length, 2);
      expect(
        controller.filteredNotifications
            .every((n) => n.category == NotificationCategory.updates),
        isTrue,
      );
    });

    test('category unread counts correctly calculate for each category', () async {
      await controller.fetchNotifications();

      expect(controller.unreadCountForCategory('All'), 5);
      expect(controller.unreadCountForCategory('Social'), 2);
      expect(controller.unreadCountForCategory('Finance'), 1);
      expect(controller.unreadCountForCategory('Events'), 1);
      expect(controller.unreadCountForCategory('Reminders'), 1);
      expect(controller.unreadCountForCategory('Updates'), 0);
    });

    test('markAsRead updates isRead state and decreases unreadCount', () async {
      await controller.fetchNotifications();
      expect(controller.unreadCount, 5);

      await controller.markAsRead('n1');
      expect(controller.unreadCount, 4);
      expect(controller.notifications.firstWhere((n) => n.id == 'n1').isRead, isTrue);
    });

    test('markAllAsRead marks all notifications as read', () async {
      await controller.fetchNotifications();
      expect(controller.unreadCount, 5);

      await controller.markAllAsRead();
      expect(controller.unreadCount, 0);
      expect(controller.notifications.every((n) => n.isRead), isTrue);
    });

    test('deleteNotification removes item from list', () async {
      await controller.fetchNotifications();
      expect(controller.notifications.length, 9);

      await controller.deleteNotification('n1');
      expect(controller.notifications.length, 8);
      expect(controller.notifications.any((n) => n.id == 'n1'), isFalse);
    });

    test('loadMoreNotifications appends subsequent pages and updates hasMore', () async {
      when(() => mockRepo.getNotifications(
            page: 1,
            size: any(named: 'size'),
            unreadOnly: any(named: 'unreadOnly'),
          )).thenAnswer((_) async => NotificationPage(
            items: [
              NotificationModel(
                id: 'n10',
                type: NotificationType.chat,
                category: NotificationCategory.social,
                title: 'Vanna sent you a message',
                body: 'Are you available today?',
                senderName: 'Vanna',
                timeAgo: '1m ago',
                timestamp: DateTime.now(),
                targetId: 'room-1',
                targetType: 'CHAT_ROOM',
              ),
            ],
            page: 1,
            size: 20,
            totalElements: 10,
            totalPages: 2,
            hasNext: false,
          ));

      await controller.fetchNotifications();
      expect(controller.notifications.length, 9);
      expect(controller.hasMore.value, false);

      controller.hasMore.value = true;
      await controller.loadMoreNotifications();

      expect(controller.notifications.length, 10);
      expect(controller.notifications.any((n) => n.id == 'n10'), isTrue);
      expect(controller.hasMore.value, false);
      expect(controller.currentPage.value, 1);
    });

    test('fetchNotifications sets isError and errorMessage on failure when list is empty', () async {
      when(() => mockRepo.getNotifications(
            page: any(named: 'page'),
            size: any(named: 'size'),
            unreadOnly: any(named: 'unreadOnly'),
          )).thenThrow(Exception('Network connection failed'));

      controller.notifications.clear();
      await controller.fetchNotifications();

      expect(controller.isError.value, isTrue);
      expect(controller.notifications.isEmpty, isTrue);
    });
  });

  Widget buildTestScreen({
    ThemeMode themeMode = ThemeMode.dark,
    Locale locale = const Locale('en', 'US'),
    Size size = const Size(390, 844),
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const NotificationScreen(),
      ),
    );
  }

  group('Unified NotificationScreen Widget Tests', () {
    testWidgets('renders simple header "Notifications" with iOS back button and without unread tabs',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      expect(find.text('Unread'), findsNothing);
    });

    testWidgets('renders Telegram-style compact horizontal category navigation bar',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Updates'), findsOneWidget);
    });

    testWidgets('renders time groups (TODAY, YESTERDAY, Earlier) and unified cards',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Earlier', skipOffstage: false), findsOneWidget);

      expect(find.text('Dara replied to your comment'), findsOneWidget);
      expect(find.text("You've used 80% of your budget"), findsOneWidget);
      expect(find.text('Flutter Workshop is tomorrow'), findsOneWidget);
      expect(find.text('Time to complete Morning Reading'), findsOneWidget);
      expect(find.text('Lina sent you a friend request'), findsOneWidget);

      expect(find.text('“Great idea!”'), findsOneWidget);
      expect(find.text('Food · \$80 of \$100'), findsOneWidget);
      expect(find.text('9:00 AM · ACLEDA University'), findsOneWidget);
      expect(find.text('Keep your streak going!'), findsOneWidget);
      expect(find.text('2 mutual friends'), findsOneWidget);

      expect(find.text('Accept'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('category selection switches feed content cleanly',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finance'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, 'Finance');
      expect(find.text("You've used 80% of your budget"), findsOneWidget);
      expect(find.text("You're 70% closer to your saving goal"), findsOneWidget);
      expect(find.text('Dara replied to your comment'), findsNothing);
      expect(find.text('Flutter Workshop is tomorrow'), findsNothing);

      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, 'Events');
      expect(find.text('Flutter Workshop is tomorrow'), findsOneWidget);
      expect(find.text("You've used 80% of your budget"), findsNothing);

      await tester.tap(find.text('Reminders'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, 'Reminders');
      expect(find.text('Time to complete Morning Reading'), findsOneWidget);

      await tester.tap(find.text('Updates'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, 'Updates');
      expect(find.text('Quiz result is ready!'), findsOneWidget);
      expect(find.text('Achievement Unlocked: 7-Day Habit Streak'), findsOneWidget);
    });

    testWidgets('tapping a friend request notification navigates to FriendRequestsScreen',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lina sent you a friend request'));
      await tester.pumpAndSettle();

      expect(find.byType(FriendRequestsScreen), findsOneWidget);
      expect(find.text('Friend Requests'), findsOneWidget);
      expect(find.text('Accept'), findsWidgets);
      expect(find.text('Decline'), findsWidgets);
    });

    testWidgets('tapping a notification marks it as read', (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(controller.unreadCount, 5);

      await tester.tap(find.text("You've used 80% of your budget"));
      await tester.pumpAndSettle();

      expect(controller.unreadCount, 4);
      expect(controller.notifications.firstWhere((n) => n.id == 'n2').isRead, isTrue);
    });

    testWidgets('swiping a notification dismisses it', (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Dara replied to your comment'), findsOneWidget);

      await tester.drag(find.text('Dara replied to your comment'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(controller.notifications.any((n) => n.id == 'n1'), isFalse);
      expect(find.text('Dara replied to your comment'), findsNothing);
    });

    testWidgets('renders contextual empty state when category has no notifications',
        (tester) async {
      when(() => mockRepo.getNotifications(
            page: any(named: 'page'),
            size: any(named: 'size'),
            unreadOnly: any(named: 'unreadOnly'),
          )).thenAnswer((_) async => NotificationPage(
            items: [
              NotificationModel(
                id: 'n1',
                type: NotificationType.reply,
                category: NotificationCategory.social,
                title: 'Dara replied to your comment',
                body: '“Great idea!”',
                senderName: 'Dara',
                timeAgo: '2m ago',
                timestamp: DateTime.now(),
              ),
            ],
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
            hasNext: false,
          ));
      await controller.fetchNotifications();

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finance'));
      await tester.pumpAndSettle();

      expect(find.text('No Finance notifications'), findsOneWidget);
      expect(find.text("You're all caught up."), findsOneWidget);
    });

    testWidgets('works properly in Light Mode without styling errors', (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Dara replied to your comment'), findsOneWidget);
    });

    testWidgets('works properly in Khmer locale with localized category pills and headers',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(
        buildTestScreen(locale: const Locale('km', 'KH')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ការជូនដំណឹង'), findsOneWidget);

      expect(find.text('ទាំងអស់'), findsOneWidget);
      expect(find.text('សង្គម'), findsOneWidget);
      expect(find.text('ហិរញ្ញវត្ថុ'), findsOneWidget);
      expect(find.text('ព្រឹត្តិការណ៍'), findsOneWidget);

      await tester.drag(find.text('សង្គម'), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(find.text('បច្ចុប្បន្នភាព'), findsOneWidget);

      await tester.drag(
        find.text('បច្ចុប្បន្នភាព'),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('ថ្ងៃនេះ'), findsOneWidget);
      expect(find.text('ម្សិលមិញ'), findsOneWidget);
      expect(find.text('មុននេះ', skipOffstage: false), findsOneWidget);
    });

    testWidgets('renders gracefully on small screen width (320px) without overflow',
        (tester) async {
      await controller.fetchNotifications();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen(size: const Size(320, 568)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
    });
  });

  group('NotificationModel backend response parsing', () {
    test('parses backend NotificationResponse JSON with PageResponse fields', () {
      final json = {
        'id': 'b1234567-0000-0000-0000-000000000001',
        'notificationType': 'COMMUNITY_POST_COMMENT',
        'category': 'COMMUNITY',
        'title': 'New comment on your post',
        'message': 'Dara commented: "Great insight!"',
        'referenceType': 'POST',
        'referenceId': 'c1234567-0000-0000-0000-000000000002',
        'readStatus': false,
        'createdAt': '2026-09-17T05:30:00Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'b1234567-0000-0000-0000-000000000001');
      expect(model.type, NotificationType.comment);
      expect(model.category, NotificationCategory.social);
      expect(model.title, 'New comment on your post');
      expect(model.body, 'Dara commented: "Great insight!"');
      expect(model.targetType, 'POST');
      expect(model.targetId, 'c1234567-0000-0000-0000-000000000002');
      expect(model.isRead, false);
      expect(model.timestamp, DateTime.parse('2026-09-17T05:30:00Z').toLocal());
    });

    test('parses readStatus true and SECURITY category', () {
      final json = {
        'id': 'b1234567-0000-0000-0000-000000000003',
        'notificationType': 'SECURITY_SUSPICIOUS_LOGIN',
        'category': 'SECURITY',
        'title': 'Suspicious login detected',
        'message': 'A new sign-in was detected',
        'readStatus': true,
        'createdAt': '2026-09-17T05:31:00Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.category, NotificationCategory.updates);
      expect(model.isRead, true);
    });

    test('parses CHAT_NEW_MESSAGE type correctly and maps to social category', () {
      final json = {
        'notificationId': 'chat-notif-uuid',
        'type': 'CHAT_NEW_MESSAGE',
        'title': 'New message from Vanna',
        'message': 'Hello there!',
        'referenceType': 'CHAT_ROOM',
        'referenceId': 'chat-room-uuid',
        'readStatus': false,
        'createdAt': '2026-09-17T06:00:00Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'chat-notif-uuid');
      expect(model.type, NotificationType.chat);
      expect(model.category, NotificationCategory.social);
      expect(model.targetType, 'CHAT_ROOM');
      expect(model.targetId, 'chat-room-uuid');
      expect(model.isRead, false);
    });

    test('parses notificationId fallback when id is absent', () {
      final json = {
        'notificationId': 'backend-id-999',
        'type': 'COMMUNITY_POST_LIKE',
        'title': 'Post liked',
        'message': 'Someone liked your post',
        'readStatus': false,
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, 'backend-id-999');
      expect(model.type, NotificationType.like);
    });

    test('parses COMMUNITY_NEW_FOLLOWER and COMMUNITY_FOLLOW_ACCEPTED', () {
      final jsonFollower = {
        'notificationId': 'follow-1',
        'type': 'COMMUNITY_NEW_FOLLOWER',
        'title': 'New follower',
        'message': 'Dara started following you',
        'referenceType': 'USER',
        'referenceId': 'user-1',
        'readStatus': false,
      };

      final modelFollower = NotificationModel.fromJson(jsonFollower);
      expect(modelFollower.type, NotificationType.follow);
      expect(modelFollower.category, NotificationCategory.social);

      final jsonAccepted = {
        'notificationId': 'follow-2',
        'type': 'COMMUNITY_FOLLOW_ACCEPTED',
        'title': 'Follow request accepted',
        'message': 'Lina accepted your follow request',
        'referenceType': 'USER',
        'referenceId': 'user-2',
        'readStatus': true,
      };

      final modelAccepted = NotificationModel.fromJson(jsonAccepted);
      expect(modelAccepted.type, NotificationType.follow);
      expect(modelAccepted.isRead, true);
    });

    test('parses COMMUNITY_POST_LIKE and COMMUNITY_COMMENT_REPLY', () {
      final jsonLike = {
        'notificationId': 'like-1',
        'type': 'COMMUNITY_POST_LIKE',
        'title': 'Someone liked your post',
        'message': 'Sokchea liked your post',
        'referenceType': 'POST',
        'referenceId': 'post-1',
        'readStatus': false,
      };

      final modelLike = NotificationModel.fromJson(jsonLike);
      expect(modelLike.type, NotificationType.like);

      final jsonReply = {
        'notificationId': 'reply-1',
        'type': 'COMMUNITY_COMMENT_REPLY',
        'title': 'Reply on your comment',
        'message': 'Dara replied to you',
        'referenceType': 'POST',
        'referenceId': 'post-1',
        'readStatus': false,
      };

      final modelReply = NotificationModel.fromJson(jsonReply);
      expect(modelReply.type, NotificationType.reply);
    });
  });

  group('NotificationScreen Header Actions & Error Handling', () {
    testWidgets('tapping Mark all read button marks all notifications as read',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(controller.unreadCount, 5);
      expect(find.text('Mark all read'), findsOneWidget);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(controller.unreadCount, 0);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('shows ErrorState with Retry button when loading fails',
        (tester) async {
      when(() => mockRepo.getNotifications(
            page: any(named: 'page'),
            size: any(named: 'size'),
            unreadOnly: any(named: 'unreadOnly'),
          )).thenThrow(Exception('Server error'));

      controller.notifications.clear();
      await controller.fetchNotifications();

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Notification Relative-Time Formatting Tests', () {
    test('formats relative time for English correctly across intervals', () {
      final now = DateTime.now();

      final justNow = formatCommunityTimestamp(
        now.subtract(const Duration(seconds: 15)),
        locale: const Locale('en', 'US'),
      );
      expect(justNow, 'Just now');

      final fiveMin = formatCommunityTimestamp(
        now.subtract(const Duration(minutes: 5)),
        locale: const Locale('en', 'US'),
      );
      expect(fiveMin, '5m');

      final twoHours = formatCommunityTimestamp(
        now.subtract(const Duration(hours: 2)),
        locale: const Locale('en', 'US'),
      );
      expect(twoHours, '2h');

      final threeDays = formatCommunityTimestamp(
        now.subtract(const Duration(days: 3)),
        locale: const Locale('en', 'US'),
      );
      expect(threeDays, '3d');
    });

    test('formats relative time for Khmer correctly across intervals', () {
      final now = DateTime.now();

      final justNow = formatCommunityTimestamp(
        now.subtract(const Duration(seconds: 20)),
        locale: const Locale('km', 'KH'),
      );
      expect(justNow, 'ទើបតែឥឡូវ');

      final fiveMin = formatCommunityTimestamp(
        now.subtract(const Duration(minutes: 5)),
        locale: const Locale('km', 'KH'),
      );
      expect(fiveMin, '5 នាទី');

      final twoHours = formatCommunityTimestamp(
        now.subtract(const Duration(hours: 2)),
        locale: const Locale('km', 'KH'),
      );
      expect(twoHours, '2 ម៉ោង');

      final threeDays = formatCommunityTimestamp(
        now.subtract(const Duration(days: 3)),
        locale: const Locale('km', 'KH'),
      );
      expect(threeDays, '3 ថ្ងៃ');
    });
  });

  group('Header Badges & State Synchronization Tests', () {
    testWidgets('AppHeaderActionButton displays count and caps at 99+',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppHeaderActionButton(
                icon: Icons.notifications_none_rounded,
                badgeCount: 0,
                onTap: () {},
                tooltip: 'Notifications',
              ),
              AppHeaderActionButton(
                icon: Icons.notifications_none_rounded,
                badgeCount: 5,
                onTap: () {},
                tooltip: 'Notifications',
              ),
              AppHeaderActionButton(
                icon: Icons.notifications_none_rounded,
                badgeCount: 150,
                onTap: () {},
                tooltip: 'Notifications',
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNothing);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('AppHeaderNotificationButton synchronizes live with controller',
        (tester) async {
      await controller.fetchNotifications();
      expect(controller.unreadCount, 5);

      await tester.pumpWidget(GetMaterialApp(
        home: const Scaffold(
          appBar: AppScreenHeader(
            title: 'Test Header',
            actions: [AppHeaderNotificationButton()],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);

      await controller.markAsRead('n1');
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);

      await controller.markAllAsRead();
      await tester.pumpAndSettle();
      expect(find.text('4'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('NotificationScreen back button pops or navigates safely',
        (tester) async {
      await controller.fetchNotifications();
      bool popped = false;

      await tester.pumpWidget(GetMaterialApp(
        home: Navigator(
          // ignore: deprecated_member_use
          onPopPage: (route, result) {
            popped = true;
            return route.didPop(result);
          },
          pages: const [
            MaterialPage(child: Scaffold(body: Text('Home Root'))),
            MaterialPage(child: NotificationScreen()),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AppBackButton), findsOneWidget);
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    test('NotificationModel.fromJson parses actor name from social notification titles', () {
      final json1 = {
        'id': 'test-1',
        'type': 'LIKE',
        'title': 'Dara liked your post',
        'message': 'Dara liked your post: Check this out',
        'createdAt': '2026-09-17T10:00:00Z',
      };
      final notif1 = NotificationModel.fromJson(json1);
      expect(notif1.senderName, 'Dara');
      expect(notif1.type, NotificationType.like);
      expect(notif1.category, NotificationCategory.social);

      final json2 = {
        'id': 'test-2',
        'type': 'COMMENT',
        'title': 'Sokchea commented on your post',
        'message': 'Nice shot!',
        'createdAt': '2026-09-17T10:05:00Z',
      };
      final notif2 = NotificationModel.fromJson(json2);
      expect(notif2.senderName, 'Sokchea');
      expect(notif2.type, NotificationType.comment);

      final json3 = {
        'id': 'test-3',
        'type': 'FOLLOW',
        'title': 'Lina started following you',
        'message': 'Lina started following you',
        'createdAt': '2026-09-17T10:10:00Z',
      };
      final notif3 = NotificationModel.fromJson(json3);
      expect(notif3.senderName, 'Lina');
      expect(notif3.type, NotificationType.follow);
    });

    testWidgets('NotificationScreen renders AppAvatar for social notifications and category icons for system notifications',
        (tester) async {
      await controller.fetchNotifications();

      await tester.pumpWidget(GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const NotificationScreen(),
      ));
      await tester.pumpAndSettle();

      // Social notifications should render CircleAvatar (used inside AppAvatar)
      expect(find.byType(CircleAvatar), findsWidgets);

      // Social notification micro badges (favorite icon for like, etc.)
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

      // System notification icons (account balance for finance, calendar for events)
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsWidgets);
      expect(find.byIcon(Icons.calendar_month_rounded), findsWidgets);
    });
  });
}

