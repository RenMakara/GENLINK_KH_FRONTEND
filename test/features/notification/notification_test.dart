import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';
import 'package:genlink_frontend/features/notification/presentation/screens/notification_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepo extends Mock
    implements NotificationRepositoryImpl {}

List<NotificationModel> _createSampleNotifications() => [
      NotificationModel(
        id: 'n1',
        type: NotificationType.like,
        title: 'Post Reaction',
        body: 'Ren Makara liked your post.',
        senderName: 'Ren Makara',
        senderAvatar: 'assets/images/ren_makara_profile.png',
        timeAgo: '10m ago',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: false,
        targetId: 'post_1',
        targetType: 'post',
      ),
      NotificationModel(
        id: 'n2',
        type: NotificationType.mention,
        title: 'Mentioned You',
        body: 'Heng Chansela mentioned you in a comment.',
        senderName: 'Heng Chansela',
        senderAvatar: 'assets/images/heng_chansela_profile.png',
        timeAgo: '2h ago',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        targetId: 'post_2',
        targetType: 'post',
      ),
      NotificationModel(
        id: 'n3',
        type: NotificationType.system,
        title: 'Welcome to GenLink KH',
        body: 'Your profile setup is complete!',
        senderName: 'GenLink KH Team',
        senderAvatar: 'assets/logos/genlink_logo.png',
        timeAgo: '2d ago',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        targetId: 'welcome',
        targetType: 'system',
      ),
    ];

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

  group('NotificationController Unit Tests', () {
    test('initial fetch loads notifications and counts unread', () async {
      await controller.fetchNotifications();
      expect(controller.notifications.length, 3);
      expect(controller.unreadCount, 2);
    });

    test('filtering partitions correctly', () async {
      await controller.fetchNotifications();

      controller.selectTab('All');
      expect(controller.filteredNotifications.length, 3);

      controller.selectTab('Mentions');
      expect(controller.filteredNotifications.length, 1);
      expect(controller.filteredNotifications.first.type, NotificationType.mention);

      controller.selectTab('Activity');
      expect(controller.filteredNotifications.length, 1);
      expect(controller.filteredNotifications.first.type, NotificationType.like);

      controller.selectTab('System');
      expect(controller.filteredNotifications.length, 1);
      expect(controller.filteredNotifications.first.type, NotificationType.system);
    });

    test('markAsRead updates isRead state and unreadCount', () async {
      await controller.fetchNotifications();
      expect(controller.unreadCount, 2);

      await controller.markAsRead('n1');
      expect(controller.unreadCount, 1);
      expect(controller.notifications.firstWhere((n) => n.id == 'n1').isRead, isTrue);
    });

    test('markAllAsRead marks all notifications as read', () async {
      await controller.fetchNotifications();
      expect(controller.unreadCount, 2);

      await controller.markAllAsRead();
      expect(controller.unreadCount, 0);
      expect(controller.notifications.every((n) => n.isRead), isTrue);
    });

    test('deleteNotification removes item from list', () async {
      await controller.fetchNotifications();
      expect(controller.notifications.length, 3);

      await controller.deleteNotification('n1');
      expect(controller.notifications.length, 2);
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

  group('NotificationScreen Widget Tests', () {
    testWidgets('renders primary header (title + unread count), right-aligned compact filter button, and notification list',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Header: Page title "Notifications"
      expect(find.text('Notifications'), findsOneWidget);

      // Header: Unread badge "2"
      expect(find.text('2'), findsOneWidget);

      // Right-aligned compact filter button
      expect(find.text('Filter'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Verify "Mark all read" and "All notifications" are REMOVED
      expect(find.text('Mark all read'), findsNothing);
      expect(find.text('All notifications'), findsNothing);

      // Date Grouping Section Labels: "TODAY" and "EARLIER"
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('EARLIER'), findsOneWidget);

      // Notification Items
      expect(find.text('Ren Makara liked your post.'), findsOneWidget);
      expect(find.text('Heng Chansela mentioned you in a comment.'), findsOneWidget);
      expect(find.text('Your profile setup is complete!'), findsOneWidget);
    });

    testWidgets('tapping filter button opens bottom sheet and selects Mentions',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Tap the Filter button
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and options
      expect(find.text('Filter notifications'), findsOneWidget);
      expect(find.text('Mentions'), findsWidgets);
      expect(find.text('Activity'), findsWidgets);
      expect(find.text('System'), findsWidgets);

      // Tap on Mentions in the sheet
      await tester.tap(find.text('Mentions').last);
      await tester.pumpAndSettle();

      // Bottom sheet closed, active filter is now Mentions
      expect(controller.selectedTab.value, 'Mentions');
      expect(find.text('Mentions'), findsOneWidget);
      expect(find.text('Heng Chansela mentioned you in a comment.'), findsOneWidget);
      expect(find.text('Ren Makara liked your post.'), findsNothing);
    });

    testWidgets('tapping filter button opens bottom sheet and selects Activity and System',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Select Activity
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activity').last);
      await tester.pumpAndSettle();

      expect(controller.selectedTab.value, 'Activity');
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Ren Makara liked your post.'), findsOneWidget);
      expect(find.text('Heng Chansela mentioned you in a comment.'), findsNothing);

      // Select System
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('System').last);
      await tester.pumpAndSettle();

      expect(controller.selectedTab.value, 'System');
      expect(find.text('System'), findsWidgets);
      expect(find.text('Your profile setup is complete!'), findsOneWidget);
      expect(find.text('Ren Makara liked your post.'), findsNothing);
    });

    testWidgets('tapping a single notification item marks it as read',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(controller.unreadCount, 2);

      // Tap on the first notification card
      await tester.tap(find.text('Ren Makara liked your post.'));
      await tester.pumpAndSettle();

      expect(controller.unreadCount, 1);
      expect(controller.notifications.firstWhere((n) => n.id == 'n1').isRead, isTrue);
    });

    testWidgets('swiping a notification dismisses it',
        (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Ren Makara liked your post.'), findsOneWidget);

      // Dismiss the item
      await tester.drag(find.text('Ren Makara liked your post.'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(controller.notifications.any((n) => n.id == 'n1'), isFalse);
      expect(find.text('Ren Makara liked your post.'), findsNothing);
    });

    testWidgets('renders contextual empty state when filtered list is empty',
        (tester) async {
      // Empty notifications
      when(() => mockRepo.getNotifications()).thenAnswer((_) async => []);
      await controller.fetchNotifications();

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('No notifications'), findsOneWidget);
    });

    testWidgets('works properly in Light Mode without errors', (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(buildTestScreen(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Ren Makara liked your post.'), findsOneWidget);
    });

    testWidgets('works properly in Khmer locale', (tester) async {
      await controller.fetchNotifications();
      await tester.pumpWidget(
        buildTestScreen(locale: const Locale('km', 'KH')),
      );
      await tester.pumpAndSettle();

      // Title in Khmer: ការជូនដំណឹង
      expect(find.text('ការជូនដំណឹង'), findsOneWidget);
      // Filter button in Khmer: តម្រង
      expect(find.text('តម្រង'), findsOneWidget);
      // Section labels: ថ្ងៃនេះ and មុននេះ
      expect(find.text('ថ្ងៃនេះ'), findsOneWidget);
      expect(find.text('មុននេះ'), findsOneWidget);
    });

    testWidgets('renders gracefully on small screen width (320px) with no overflow',
        (tester) async {
      await controller.fetchNotifications();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen(size: const Size(320, 568)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
    });
  });
}
