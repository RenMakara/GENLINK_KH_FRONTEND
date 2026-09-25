import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/utils/date_formatter.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/presentation/screens/widgets/community_widgets.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('CommunityDateFormatter Unit Tests', () {
    final fixedNow = DateTime(2026, 9, 10, 15, 0, 0); // Sep 10, 2026 15:00:00 local

    // 1. Current post -> Just now
    test('1. Current post (< 1 min) -> Just now', () {
      final nowPost = fixedNow.subtract(const Duration(seconds: 25));
      expect(
        formatCommunityTimestamp(nowPost, now: fixedNow, locale: const Locale('en')),
        'Just now',
      );
    });

    // 2. 5 minutes ago -> 5m
    test('2. 5 minutes ago -> 5m', () {
      final fiveMinPost = fixedNow.subtract(const Duration(minutes: 5));
      expect(
        formatCommunityTimestamp(fiveMinPost, now: fixedNow, locale: const Locale('en')),
        '5m',
      );
    });

    // 3. 30 minutes ago -> 30m
    test('3. 30 minutes ago -> 30m', () {
      final thirtyMinPost = fixedNow.subtract(const Duration(minutes: 30));
      expect(
        formatCommunityTimestamp(thirtyMinPost, now: fixedNow, locale: const Locale('en')),
        '30m',
      );
    });

    // 4. 1 hour ago -> 1h
    test('4. 1 hour ago -> 1h', () {
      final oneHourPost = fixedNow.subtract(const Duration(hours: 1));
      expect(
        formatCommunityTimestamp(oneHourPost, now: fixedNow, locale: const Locale('en')),
        '1h',
      );
    });

    // 5. 2 hours ago -> 2h
    test('5. 2 hours ago -> 2h', () {
      final twoHoursPost = fixedNow.subtract(const Duration(hours: 2));
      expect(
        formatCommunityTimestamp(twoHoursPost, now: fixedNow, locale: const Locale('en')),
        '2h',
      );
    });

    // 6. 23 hours ago -> 23h
    test('6. 23 hours ago -> 23h', () {
      final twentyThreeHoursPost = fixedNow.subtract(const Duration(hours: 23));
      expect(
        formatCommunityTimestamp(twentyThreeHoursPost, now: fixedNow, locale: const Locale('en')),
        '23h',
      );
    });

    // 7. 1 day ago -> 1d
    test('7. 1 day ago -> 1d', () {
      final oneDayPost = fixedNow.subtract(const Duration(days: 1));
      expect(
        formatCommunityTimestamp(oneDayPost, now: fixedNow, locale: const Locale('en')),
        '1d',
      );
    });

    // 8. 3 days ago -> 3d
    test('8. 3 days ago -> 3d', () {
      final threeDaysPost = fixedNow.subtract(const Duration(days: 3));
      expect(
        formatCommunityTimestamp(threeDaysPost, now: fixedNow, locale: const Locale('en')),
        '3d',
      );
    });

    // 9. 6 days ago -> 6d
    test('9. 6 days ago -> 6d', () {
      final sixDaysPost = fixedNow.subtract(const Duration(days: 6));
      expect(
        formatCommunityTimestamp(sixDaysPost, now: fixedNow, locale: const Locale('en')),
        '6d',
      );
    });

    // 10. 7+ days in current year -> MMM d (e.g. Sep 3)
    test('10. 7+ days in current year -> Sep 3 / Sep 9', () {
      final sep3Post = DateTime(2026, 9, 3, 10, 0, 0);
      expect(
        formatCommunityTimestamp(sep3Post, now: fixedNow, locale: const Locale('en')),
        'Sep 3',
      );

      final sep9Post = DateTime(2026, 9, 9, 10, 0, 0);
      // If reference date is 10 days later
      final sep19Ref = DateTime(2026, 9, 19, 12, 0, 0);
      expect(
        formatCommunityTimestamp(sep9Post, now: sep19Ref, locale: const Locale('en')),
        'Sep 9',
      );
    });

    // 11. Previous year -> MMM d, yyyy
    test('11. Previous year -> Sep 9, 2025', () {
      final lastYearPost = DateTime(2025, 9, 9, 12, 0, 0);
      expect(
        formatCommunityTimestamp(lastYearPost, now: fixedNow, locale: const Locale('en')),
        'Sep 9, 2025',
      );
    });

    // 12. Future timestamp -> Just now / safe fallback
    test('12. Future timestamp -> Just now', () {
      final futurePost = fixedNow.add(const Duration(minutes: 10));
      expect(
        formatCommunityTimestamp(futurePost, now: fixedNow, locale: const Locale('en')),
        'Just now',
      );
    });

    // 13. Invalid timestamp -> safe fallback (empty string, never crashes, never exposes raw string)
    test('13. Invalid timestamp -> safe fallback', () {
      expect(formatCommunityTimestamp(null), '');
      expect(formatCommunityTimestamp(''), '');
      expect(formatCommunityTimestamp('   '), '');
      expect(formatCommunityTimestamp('invalid-date-string'), '');
      expect(formatCommunityTimestamp(12345), '');
    });

    // 14. UTC timestamp conversion -> correct local date/time calculation
    test('14. UTC timestamp conversion with nanoseconds', () {
      const utcIsoString = '2026-09-09T17:28:27.047050304Z';
      final parsed = CommunityDateFormatter.parseToUtc(utcIsoString);
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
      expect(parsed.year, 2026);
      expect(parsed.month, 9);
      expect(parsed.day, 9);
      expect(parsed.hour, 17);

      // Converted to local time
      final local = parsed.toLocal();
      expect(local, isNotNull);

      // If tested with now set to 2 hours after the UTC post
      final nowUtc = parsed.add(const Duration(hours: 2));
      expect(
        formatCommunityTimestamp(utcIsoString, now: nowUtc.toLocal(), locale: const Locale('en')),
        '2h',
      );
    });

    // 15. English localization
    test('15. English localization verification', () {
      final enLocale = const Locale('en', 'US');
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(seconds: 10)), now: fixedNow, locale: enLocale),
        'Just now',
      );
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(minutes: 5)), now: fixedNow, locale: enLocale),
        '5m',
      );
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(hours: 2)), now: fixedNow, locale: enLocale),
        '2h',
      );
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(days: 1)), now: fixedNow, locale: enLocale),
        '1d',
      );
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(days: 3)), now: fixedNow, locale: enLocale),
        '3d',
      );
      expect(
        formatCommunityTimestamp(DateTime(2026, 9, 1), now: fixedNow, locale: enLocale),
        'Sep 1',
      );
      expect(
        formatCommunityTimestamp(DateTime(2025, 9, 9), now: fixedNow, locale: enLocale),
        'Sep 9, 2025',
      );
    });

    // 16. Khmer localization
    test('16. Khmer localization verification', () {
      final kmLocale = const Locale('km', 'KH');
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(seconds: 10)), now: fixedNow, locale: kmLocale),
        'ទើបតែឥឡូវ',
      );
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(minutes: 5)), now: fixedNow, locale: kmLocale),
        '5 នាទី',
      );
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(hours: 2)), now: fixedNow, locale: kmLocale),
        '2 ម៉ោង',
      );
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(days: 1)), now: fixedNow, locale: kmLocale),
        '1 ថ្ងៃ',
      );
      expect(
        formatCommunityTimestamp(fixedNow.subtract(const Duration(days: 3)), now: fixedNow, locale: kmLocale),
        '3 ថ្ងៃ',
      );
      expect(
        formatCommunityTimestamp(DateTime(2026, 9, 1), now: fixedNow, locale: kmLocale),
        '1 កញ្ញា',
      );
      expect(
        formatCommunityTimestamp(DateTime(2025, 9, 9), now: fixedNow, locale: kmLocale),
        '9 កញ្ញា 2025',
      );
    });

    test('Legacy relative strings formatting', () {
      expect(formatCommunityTimestamp('5m ago', locale: const Locale('en')), '5m');
      expect(formatCommunityTimestamp('2h ago', locale: const Locale('en')), '2h');
      expect(formatCommunityTimestamp('1d ago', locale: const Locale('en')), '1d');
      expect(formatCommunityTimestamp('5m ago', locale: const Locale('km')), '5 នាទី');
      expect(formatCommunityTimestamp('2h ago', locale: const Locale('km')), '2 ម៉ោង');
      expect(formatCommunityTimestamp('1d ago', locale: const Locale('km')), '1 ថ្ងៃ');
    });

    test('Models parse raw backend ISO-8601 strings into formatted social timestamps', () {
      final topicJson = {
        'discussionId': 'd_123',
        'title': 'Test Discussion',
        'authorName': 'enat',
        'category': 'Tech',
        'content': 'Test Content',
        'createdAt': '2026-09-09T17:28:27.047050304Z',
      };

      final topic = ForumTopicModel.fromJson(topicJson);
      expect(topic.createdAt, isNotNull);
      // TimeAgo should be formatted, not raw ISO
      expect(topic.timeAgo.contains('T17:28:27'), isFalse);
      expect(topic.timeAgo.contains('.047050304Z'), isFalse);

      final commentJson = {
        'commentId': 'c_123',
        'discussionId': 'd_123',
        'userName': 'sokha',
        'content': 'Great topic!',
        'createdAt': '2026-09-09T17:28:27.047050304Z',
      };

      final comment = CommentModel.fromJson(commentJson);
      expect(comment.createdAt, isNotNull);
      expect(comment.timeAgo.contains('T17:28:27'), isFalse);
      expect(comment.timeAgo.contains('.047050304Z'), isFalse);
    });
  });

  group('Forum Timestamp UI & Responsive 320px Tests', () {
    testWidgets('ForumThreadCard renders compact username · timestamp and does not show raw ISO', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: ForumThreadCard(
              title: 'Flutter Architecture',
              author: 'enat',
              timeAgo: '2h',
              category: 'Tech',
              replies: 10,
              likes: 25,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('enat'), findsOneWidget);
      expect(find.textContaining('· 2h'), findsOneWidget);
      expect(find.textContaining('2026-09-09'), findsNothing);
      expect(find.textContaining('T17:28:27'), findsNothing);
      expect(find.textContaining('.047050304Z'), findsNothing);
    });

    testWidgets('ForumThreadCard formats raw ISO timestamp cleanly', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: ForumThreadCard(
              title: 'Clean Code',
              author: 'enat',
              timeAgo: '2026-09-09T17:28:27.047050304Z',
              category: 'General',
              replies: 5,
              likes: 12,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2026-09-09T17:28:27.047050304Z'), findsNothing);
      expect(find.textContaining('.047050304Z'), findsNothing);
    });

    testWidgets('ForumThreadCard does not overflow on small 320px mobile screens', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: ForumThreadCard(
                title: 'A very long discussion title that should test responsiveness on narrow width',
                author: 'very_long_author_name_that_could_potentially_cause_overflow',
                timeAgo: '2h',
                category: 'Development & Design',
                replies: 99,
                likes: 150,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no flutter overflow errors occurred
      expect(tester.takeException(), isNull);
    });
  });
}
