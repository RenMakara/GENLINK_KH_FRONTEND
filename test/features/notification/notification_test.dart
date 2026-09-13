import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/screens/friend_requests_screen.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';
import 'package:genlink_frontend/features/notification/presentation/screens/notification_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepo extends Mock
    implements NotificationRepositoryImpl {}

List<NotificationModel> _createSampleNotifications() {
  final now = DateTime.now();

  return [
    NotificationModel(
      id: 'n1',
      type: NotificationType.reply,
      category: NotificationCategory.social,
      title: 'New reply to your comment',
      body: '“Great idea!”',
      contextText: '“Great idea!”',
      senderName: 'Campus User',
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
      title: 'Campus Workshop is tomorrow',
      body: '9:00 AM · ACLEDA University',
      contextText: '9:00 AM · ACLEDA University',
      senderName: 'Event Desk',
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
      title: 'New friend request received',
      body: '2 mutual friends',
      contextText: '2 mutual friends',
      senderName: 'Student',
      senderAvatar: 'assets/images/user_profile.png',
      timeAgo: '2h ago',
      timestamp: now.subtract(const Duration(hours: 2, minutes: 5)),
      isRead: false,
      targetId: 'user_1',
      targetType: 'friend_request',
    ),
    NotificationModel(
      id: 'n6',
      type: NotificationType.like,
      category: NotificationCategory.social,
      title: 'Someone liked your post',
      body: 'Someone liked your post',
      senderName: 'Student User',
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
    when(() => mockRepo.getNotifications())
        .thenAnswer((_) async => _createSampleNotifications());
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
      expect(controller.hasError, isFalse);
    });

    test('error state is captured when repository throws', () async {
      when(() => mockRepo.getNotifications())
          .thenThrow(Exception('Server unreachable'));
      await controller.fetchNotifications();

      expect(controller.notifications.isEmpty, isTrue);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage.value, contains('Server unreachable'));
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
    testWidgets('renders simple header "Notifications" without back button or unread tabs',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.text('Unread'), findsNothing);
    });

    testWidgets('renders compact horizontal category navigation bar',
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

    testWidgets('renders clean EMPTY state when no notifications exist',
        (tester) async {
      when(() => mockRepo.getNotifications())
          .thenAnswer((_) async => <NotificationModel>[]);
      await controller.fetchNotifications();

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(
        find.text(
          "When you have activity, updates, or reminders,\nthey'll appear here.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders ERROR state with Retry button when fetch fails',
        (tester) async {
      when(() => mockRepo.getNotifications())
          .thenThrow(Exception('Network connection error'));
      await controller.fetchNotifications();

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Unable to load notifications'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Verify tapping retry triggers another fetch
      when(() => mockRepo.getNotifications())
          .thenAnswer((_) async => _createSampleNotifications());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(controller.notifications.length, 9);
      expect(find.text('New reply to your comment'), findsOneWidget);
    });

    testWidgets('renders loading skeleton while loading', (tester) async {
      controller.isLoading.value = true;
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Verify that list of notifications is not rendered while loading
      expect(find.text('New reply to your comment'), findsNothing);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    });

    testWidgets('renders time groups (TODAY, YESTERDAY, Earlier) with sample notifications',
        (tester) async {
      final now = DateTime.now();
      when(() => mockRepo.getNotifications()).thenAnswer((_) async => [
            NotificationModel(
              id: 'today_1',
              type: NotificationType.reply,
              category: NotificationCategory.social,
              title: 'Today notification',
              body: 'Activity today',
              senderName: 'User A',
              timeAgo: '10m ago',
              timestamp: now.subtract(const Duration(minutes: 10)),
            ),
            NotificationModel(
              id: 'yesterday_1',
              type: NotificationType.eventReminder,
              category: NotificationCategory.events,
              title: 'Yesterday notification',
              body: 'Activity yesterday',
              senderName: 'Event Desk',
              timeAgo: '1d ago',
              timestamp: now.subtract(const Duration(hours: 26)),
            ),
            NotificationModel(
              id: 'earlier_1',
              type: NotificationType.achievement,
              category: NotificationCategory.updates,
              title: 'Earlier notification',
              body: 'Activity earlier',
              senderName: 'Rewards',
              timeAgo: '4d ago',
              timestamp: now.subtract(const Duration(days: 4)),
            ),
          ]);

      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);

      expect(find.text('Today notification'), findsOneWidget);
      expect(find.text('Yesterday notification'), findsOneWidget);
      expect(find.text('Earlier notification'), findsOneWidget);
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
      expect(find.text('New reply to your comment'), findsNothing);
      expect(find.text('Campus Workshop is tomorrow'), findsNothing);

      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, 'Events');
      expect(find.text('Campus Workshop is tomorrow'), findsOneWidget);
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

      await tester.tap(find.text('New friend request received'));
      await tester.pumpAndSettle();

      expect(find.byType(FriendRequestsScreen), findsOneWidget);
      expect(find.text('Friend Requests'), findsOneWidget);
    });

    testWidgets('tapping a notification marks it as read', (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(controller.unreadCount, 5);

      await tester.tap(find.text('New reply to your comment'));
      await tester.pumpAndSettle();

      expect(controller.unreadCount, 4);
      expect(controller.notifications.firstWhere((n) => n.id == 'n1').isRead, isTrue);
    });

    testWidgets('renders contextual empty state when category has no notifications',
        (tester) async {
      when(() => mockRepo.getNotifications()).thenAnswer((_) async => [
            NotificationModel(
              id: 'n1',
              type: NotificationType.reply,
              category: NotificationCategory.social,
              title: 'Social notification',
              body: 'Some reply',
              senderName: 'User',
              timeAgo: '2m ago',
              timestamp: DateTime.now(),
            ),
          ]);
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
      expect(find.text('New reply to your comment'), findsOneWidget);
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
}
