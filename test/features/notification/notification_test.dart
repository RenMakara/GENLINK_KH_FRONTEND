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

List<NotificationModel> _createComprehensiveSampleNotifications() {
  final now = DateTime.now();

  return [
    // ── TODAY ──
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

    // ── YESTERDAY ──
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

    // ── EARLIER ──
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
        .thenAnswer((_) async => _createComprehensiveSampleNotifications());
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
      expect(controller.unreadCountForCategory('Social'), 2); // n1, n5
      expect(controller.unreadCountForCategory('Finance'), 1); // n2
      expect(controller.unreadCountForCategory('Events'), 1); // n3
      expect(controller.unreadCountForCategory('Reminders'), 1); // n4
      expect(controller.unreadCountForCategory('Updates'), 0); // n7, n9 are read
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

      // Simple header title "Notifications"
      expect(find.text('Notifications'), findsOneWidget);

      // Verify NO back button
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // Verify NO settings button
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      // Verify NO "All / Unread" tabs
      expect(find.text('Unread'), findsNothing);
    });

    testWidgets('renders Telegram-style compact horizontal category navigation bar',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // All categories from specification must be rendered in category bar
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

      // Group section labels
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);

      // Notifications in TODAY
      expect(find.text('Dara replied to your comment'), findsOneWidget);
      expect(find.text("You've used 80% of your budget"), findsOneWidget);
      expect(find.text('Flutter Workshop is tomorrow'), findsOneWidget);
      expect(find.text('Time to complete Morning Reading'), findsOneWidget);
      expect(find.text('Lina sent you a friend request'), findsOneWidget);

      // Short context lines
      expect(find.text('“Great idea!”'), findsOneWidget);
      expect(find.text('Food · \$80 of \$100'), findsOneWidget);
      expect(find.text('9:00 AM · ACLEDA University'), findsOneWidget);
      expect(find.text('Keep your streak going!'), findsOneWidget);
      expect(find.text('2 mutual friends'), findsOneWidget);

      // Verify NO big accept/decline buttons directly inside notification feed
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('category selection switches feed content cleanly',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Tap on Finance category pill
      await tester.tap(find.text('Finance'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, 'Finance');
      // Finance items present
      expect(find.text("You've used 80% of your budget"), findsOneWidget);
      expect(find.text("You're 70% closer to your saving goal"), findsOneWidget);
      // Non-finance items absent
      expect(find.text('Dara replied to your comment'), findsNothing);
      expect(find.text('Flutter Workshop is tomorrow'), findsNothing);

      // Tap on Events category pill
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, 'Events');
      expect(find.text('Flutter Workshop is tomorrow'), findsOneWidget);
      expect(find.text("You've used 80% of your budget"), findsNothing);

      // Tap on Reminders category pill
      await tester.tap(find.text('Reminders'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, 'Reminders');
      expect(find.text('Time to complete Morning Reading'), findsOneWidget);

      // Tap on Updates category pill
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

      // Tap the friend request item
      await tester.tap(find.text('Lina sent you a friend request'));
      await tester.pumpAndSettle();

      // Verify Friend Requests screen opened with Accept and Decline buttons
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

      // Tap the budget notification
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

      // Dismiss the item
      await tester.drag(find.text('Dara replied to your comment'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(controller.notifications.any((n) => n.id == 'n1'), isFalse);
      expect(find.text('Dara replied to your comment'), findsNothing);
    });

    testWidgets('renders contextual empty state when category has no notifications',
        (tester) async {
      // Mock notifications with only Social items
      when(() => mockRepo.getNotifications()).thenAnswer((_) async => [
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
          ]);
      await controller.fetchNotifications();

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Tap on Finance category (which has 0 items)
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

      // Title in Khmer: ការជូនដំណឹង
      expect(find.text('ការជូនដំណឹង'), findsOneWidget);

      // Categories in Khmer
      expect(find.text('ទាំងអស់'), findsOneWidget); // All
      expect(find.text('សង្គម'), findsOneWidget); // Social
      expect(find.text('ហិរញ្ញវត្ថុ'), findsOneWidget); // Finance
      expect(find.text('ព្រឹត្តិការណ៍'), findsOneWidget); // Events

      // Scroll horizontal category bar to reveal 'Updates' (បច្ចុប្បន្នភាព)
      await tester.drag(find.text('សង្គម'), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(find.text('បច្ចុប្បន្នភាព'), findsOneWidget); // Updates

      // Scroll back
      await tester.drag(
        find.text('បច្ចុប្បន្នភាព'),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Section labels in Khmer
      expect(find.text('ថ្ងៃនេះ'), findsOneWidget); // TODAY
      expect(find.text('ម្សិលមិញ'), findsOneWidget); // YESTERDAY
      expect(find.text('មុននេះ'), findsOneWidget); // Earlier
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

