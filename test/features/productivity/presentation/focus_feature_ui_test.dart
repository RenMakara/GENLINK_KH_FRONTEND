import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/domain/repositories/productivity_repository.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/screens/focus_history_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_circular_timer.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_complete_dialog.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_home_view.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_leave_dialog.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_paused_view.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_running_view.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_session_summary_dialog.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductivityRepository extends Mock
    implements ProductivityRepository {}

void main() {
  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  Widget buildTestableWidget(
    Widget child, {
    Locale locale = const Locale('en', 'US'),
  }) {
    Get.locale = locale;
    return GetMaterialApp(
      locale: locale,
      translations: AppTranslations(),
      home: child,
    );
  }

  testWidgets(
    'FocusCircularTimer formats countdown and renders labels correctly',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: FocusCircularTimer(
              progress: 0.5,
              remainingSeconds: 1481, // 24:41
              isPaused: false,
              modeTitle: 'Pomodoro',
              durationMinutes: 25,
            ),
          ),
        ),
      );

      expect(find.text('24:41'), findsOneWidget);
      expect(find.text('Pomodoro'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
    },
  );

  testWidgets('FocusHomeView renders today stats, duration selector, and CTA', (
    tester,
  ) async {
    final repo = _MockProductivityRepository();
    when(() => repo.getDashboard()).thenAnswer(
      (_) async => const ProductivityDashboard(
        habits: ProductivityHabitsToday(total: 0, checkedInToday: 0),
        tasks: ProductivityTasksSummary(
          total: 0,
          completed: 0,
          dueToday: 0,
          overdue: 0,
        ),
        goals: [],
        focus: ProductivityFocusSummary(
          todaySessions: 4,
          todayMinutes: 100,
          totalXp: 120,
        ),
      ),
    );
    when(() => repo.getFocusStats()).thenAnswer(
      (_) async => const ProductivityFocusStats(
        todaySessions: 4,
        todayMinutes: 100,
        totalSessions: 10,
        totalMinutes: 250,
        totalXp: 120,
      ),
    );
    when(() => repo.getFocusHistory()).thenAnswer(
      (_) async => const ProductivityPage(
        content: <ProductivityFocusSession>[],
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
        hasNext: false,
      ),
    );

    final controller = ProductivityController(repository: repo);
    await controller.refreshFocusStats();

    int selectedDuration = 25;
    await tester.pumpWidget(
      buildTestableWidget(
        FocusHomeView(
          controller: controller,
          selectedDuration: selectedDuration,
          isLoading: false,
          onDurationChanged: (d) => selectedDuration = d,
          onStart: () async {},
          onBack: () {},
        ),
      ),
    );

    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Small steps\nBig progress'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('1h 40m'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    expect(find.text('Start Focus Session'), findsOneWidget);

    // Tap 50 min
    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();
    expect(selectedDuration, 50);
  });

  testWidgets(
    'FocusRunningView displays countdown hero, quote, pause, and leave controls',
    (tester) async {
      final session = ProductivityFocusSession(
        sessionId: 'session-1',
        durationMinutes: 25,
        mode: 'POMODORO',
        startedAt: DateTime.now().subtract(const Duration(seconds: 19)),
      );

      bool paused = false;
      bool left = false;

      await tester.pumpWidget(
        buildTestableWidget(
          FocusRunningView(
            session: session,
            remainingSeconds: 1481, // 24:41
            actionLoading: false,
            onBack: () async => left = true,
            onPause: () async => paused = true,
            onLeave: () async => left = true,
          ),
        ),
      );

      expect(find.text('24:41'), findsOneWidget);
      expect(find.text('Pomodoro'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
      expect(find.text('Current Session'), findsOneWidget);

      await tester.tap(find.text('Pause'));
      expect(paused, isTrue);

      await tester.tap(find.text('Leave'));
      expect(left, isTrue);
    },
  );

  testWidgets(
    'FocusPausedView displays paused status, resume, and leave controls',
    (tester) async {
      final session = ProductivityFocusSession(
        sessionId: 'session-2',
        durationMinutes: 25,
        mode: 'POMODORO',
        status: 'PAUSED',
        pausedAt: DateTime.now(),
      );

      bool resumed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          FocusPausedView(
            session: session,
            remainingSeconds: 1122, // 18:42
            actionLoading: false,
            onBack: () async {},
            onResume: () async => resumed = true,
            onLeave: () async {},
          ),
        ),
      );

      expect(find.text('18:42'), findsOneWidget);
      expect(find.text('Paused'), findsWidgets);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      expect(resumed, isTrue);
    },
  );

  testWidgets(
    'FocusLeaveDialog displays cancellation and confirmation buttons',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FocusLeaveDialog()));

      expect(find.text('Leave focus session?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
    },
  );

  testWidgets('FocusCompleteDialog displays celebration, duration, and XP', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const FocusCompleteDialog(focusedSeconds: 1500, xpEarned: 25),
      ),
    );

    expect(find.text('Great Job!'), findsOneWidget);
    expect(find.text('You stayed focused'), findsOneWidget);
    expect(find.text('25 min 0 sec'), findsOneWidget);
    expect(find.text('+25 XP'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets(
    'FocusSessionSummaryDialog displays focused time, XP, and status',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const FocusSessionSummaryDialog(
            focusedMinutes: 0,
            xpEarned: 0,
            isAbandoned: true,
          ),
        ),
      );

      expect(find.text('Session Summary'), findsOneWidget);
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('+0 XP'), findsOneWidget);
      expect(find.text('Abandoned'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    },
  );

  testWidgets('FocusHistoryScreen displays completed focus history items', (
    tester,
  ) async {
    final repo = _MockProductivityRepository();
    when(() => repo.getDashboard()).thenAnswer(
      (_) async => const ProductivityDashboard(
        habits: ProductivityHabitsToday(total: 0, checkedInToday: 0),
        tasks: ProductivityTasksSummary(
          total: 0,
          completed: 0,
          dueToday: 0,
          overdue: 0,
        ),
        goals: [],
        focus: ProductivityFocusSummary(
          todaySessions: 1,
          todayMinutes: 25,
          totalXp: 25,
        ),
      ),
    );
    when(() => repo.getFocusHistory()).thenAnswer(
      (_) async => ProductivityPage(
        content: [
          ProductivityFocusSession(
            sessionId: 'h-1',
            mode: 'POMODORO',
            durationMinutes: 25,
            focusedSeconds: 1500,
            xpEarned: 25,
            status: 'COMPLETED',
            endedAt: DateTime.now(),
          ),
        ],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        hasNext: false,
      ),
    );

    final controller = ProductivityController(repository: repo);
    await controller.loadFocusHistory();

    await tester.pumpWidget(
      buildTestableWidget(FocusHistoryScreen(controller: controller)),
    );

    expect(find.text('Recent Sessions'), findsOneWidget);
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('+25 XP'), findsOneWidget);
    expect(find.text('25 min 0 sec'), findsOneWidget);
  });

  testWidgets('Khmer localization renders correctly on Focus components', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const Scaffold(
          body: FocusCircularTimer(
            progress: 0.5,
            remainingSeconds: 1481,
            isPaused: false,
            modeTitle: 'Pomodoro',
            durationMinutes: 25,
          ),
        ),
        locale: const Locale('km', 'KH'),
      ),
    );

    expect(find.text('24:41'), findsOneWidget);
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('25 នាទី'), findsOneWidget);
  });
}
