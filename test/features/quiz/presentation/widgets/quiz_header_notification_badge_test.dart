import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';
import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_gamified_components.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepo extends Mock
    implements NotificationRepositoryImpl {}

void main() {
  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: const Scaffold(
        appBar: QuizGamifiedHeader(),
      ),
    );
  }

  Finder findRedDot() {
    return find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFFEF4444) &&
            box.shape == BoxShape.circle;
      }
      return false;
    });
  }

  testWidgets('QuizGamifiedHeader does NOT show red dot when NotificationController is not registered', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify notification bell icon is visible
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // Verify red dot alert is NOT present
    expect(findRedDot(), findsNothing);
  });

  testWidgets('QuizGamifiedHeader does NOT show red dot when unread count is 0', (tester) async {
    final mockRepo = _MockNotificationRepo();
    when(() => mockRepo.getNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        )).thenAnswer((_) async => NotificationPage.empty());

    final notifController = NotificationController(repository: mockRepo);
    notifController.totalUnreadCount.value = 0;
    Get.put<NotificationController>(notifController);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(findRedDot(), findsNothing);
  });

  testWidgets('QuizGamifiedHeader shows red dot when unread count > 0 and hides it when marked read', (tester) async {
    final sampleNotification = NotificationModel(
      id: 'n1',
      type: NotificationType.reply,
      category: NotificationCategory.social,
      title: 'New Reply',
      body: 'Someone replied',
      timeAgo: '1m ago',
      senderName: 'Dara',
      timestamp: DateTime.now(),
      isRead: false,
    );

    final mockRepo = _MockNotificationRepo();
    when(() => mockRepo.getNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        )).thenAnswer((_) async => NotificationPage(
          items: [sampleNotification],
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
          hasNext: false,
        ));
    when(() => mockRepo.markAllAsRead()).thenAnswer((_) async => true);

    final notifController = NotificationController(repository: mockRepo);
    Get.put<NotificationController>(notifController);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Red dot is shown when there is an unread notification
    expect(findRedDot(), findsOneWidget);

    // Now mark all as read
    await notifController.markAllAsRead();
    await tester.pumpAndSettle();

    // Red dot must disappear
    expect(findRedDot(), findsNothing);
  });
}
