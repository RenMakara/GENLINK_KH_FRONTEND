import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/home_header_actions.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';
import 'package:genlink_frontend/features/notification/presentation/screens/notification_screen.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

class _MockNotificationRepository extends Mock
    implements NotificationRepositoryImpl {}

FinanceDashboardEntity _testDashboard() {
  return FinanceDashboardEntity(
    currency: FinanceCurrency.usd,
    month: const FinanceMonthOverview(
      month: 9,
      year: 2026,
      currency: FinanceCurrency.usd,
      spent: 50.0,
      budgetTotal: 200.0,
      budgetRemaining: 150.0,
      budgetStatus: 'SAFE',
    ),
    topCategories: const [],
    saving: const FinanceSavingProgress(
      currency: FinanceCurrency.usd,
      totalTarget: 500.0,
      totalSaved: 100.0,
      progressPercent: 20,
      activeGoals: 1,
    ),
    recentExpenses: const [],
  );
}

void main() {
  late _MockFinanceRepository mockFinanceRepo;
  late _MockNotificationRepository mockNotifRepo;
  late FinanceController financeController;
  late NotificationController notifController;

  setUpAll(() {
    registerFallbackValue(FinanceCurrency.usd);
  });

  setUp(() {
    Get.reset();
    Get.testMode = true;

    mockFinanceRepo = _MockFinanceRepository();
    mockNotifRepo = _MockNotificationRepository();

    when(() => mockFinanceRepo.getFinanceDashboard(currency: any(named: 'currency')))
        .thenAnswer((_) async => _testDashboard());

    financeController = FinanceController(repository: mockFinanceRepo);
    Get.put<FinanceController>(financeController);

    when(() => mockNotifRepo.getNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        )).thenAnswer(
      (_) async => NotificationPage(
        items: [
          NotificationModel(
            id: 'n1',
            title: 'Budget Alert',
            body: 'You reached 75% of your dining budget',
            type: NotificationType.budgetWarning,
            category: NotificationCategory.finance,
            senderName: 'Finance System',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            timeAgo: '5m',
            isRead: false,
          ),
          NotificationModel(
            id: 'n2',
            title: 'Saving Milestone',
            body: 'You saved \$100 towards Emergency Fund',
            type: NotificationType.savingGoal,
            category: NotificationCategory.finance,
            senderName: 'Finance System',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            timeAgo: '1h',
            isRead: false,
          ),
        ],
        page: 0,
        size: 20,
        totalElements: 2,
        totalPages: 1,
        hasNext: false,
      ),
    );

    when(() => mockNotifRepo.getUnreadCount()).thenAnswer((_) async => 2);
    when(() => mockNotifRepo.markAllAsRead()).thenAnswer((_) async => true);
    when(() => mockNotifRepo.markAsRead(any())).thenAnswer((_) async => true);

    notifController = NotificationController(repository: mockNotifRepo);
    Get.put<NotificationController>(notifController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('FinanceScreen notification icon displays unread count and navigates to NotificationScreen',
      (tester) async {
    await notifController.fetchNotifications();
    expect(notifController.unreadCount, equals(2));

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: '/finance',
        getPages: [
          GetPage(
            name: '/finance',
            page: () => const FinanceScreen(),
          ),
          GetPage(
            name: AppRoutes.notifications,
            page: () => const NotificationScreen(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Verify Notification Button exists on Finance screen
    expect(find.byType(AppHeaderNotificationButton), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Tap notification button
    await tester.tap(find.byType(AppHeaderNotificationButton));
    await tester.pumpAndSettle();

    // Verify Notification Screen is open
    expect(find.byType(NotificationScreen), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Budget Alert'), findsOneWidget);

    // Tap iOS back button on NotificationScreen
    expect(find.byType(AppBackButton), findsOneWidget);
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    // Verify returned to Finance screen
    expect(find.byType(FinanceScreen), findsOneWidget);
    expect(find.byType(NotificationScreen), findsNothing);

    // Synchronize state: mark all read
    await notifController.markAllAsRead();
    await tester.pumpAndSettle();

    // Verify Finance badge disappears when unread count is 0
    expect(find.text('2'), findsNothing);
    expect(notifController.unreadCount, equals(0));
  });
}
