import 'dart:ui' show Locale;
import 'package:get/get.dart';

/// Centralized date and timestamp formatting utility for GenLink.
///
/// Converts UTC backend timestamps to device local time and formats them into
/// compact, social-media style relative or calendar timestamps.
///
/// Rules:
/// - Future / < 1 minute: "Just now" / "ទើបតែឥឡូវ"
/// - < 1 hour: "Xm" / "X នាទី"
/// - < 24 hours: "Xh" / "X ម៉ោង"
/// - < 7 days: "Xd" / "X ថ្ងៃ"
/// - 7+ days in the current year: "MMM d" (e.g., "Sep 9") / "d MMM" (e.g., "9 កញ្ញា")
/// - Previous year: "MMM d, yyyy" (e.g., "Sep 9, 2025") / "d MMM yyyy" (e.g., "9 កញ្ញា 2025")
abstract final class CommunityDateFormatter {
  static const List<String> _enMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _kmMonths = [
    'មករា',
    'កុម្ភៈ',
    'មីនា',
    'មេសា',
    'ឧសភា',
    'មិថុនា',
    'កក្កដា',
    'សីហា',
    'កញ្ញា',
    'តុលា',
    'វិច្ឆិកា',
    'ធ្នូ',
  ];

  /// Parses any timestamp input (ISO-8601 String, DateTime, or legacy relative string)
  /// into a UTC-normalized DateTime if possible.
  static DateTime? parseToUtc(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input.isUtc ? input : input.toUtc();
    if (input is! String) return null;

    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. Try standard ISO-8601 parsing
    DateTime? parsed = DateTime.tryParse(trimmed);

    // 2. Handle fractional seconds with > 6 digits (e.g. Java Instant nanoseconds)
    if (parsed == null) {
      final nanoRegex = RegExp(r'(\.\d{1,6})\d+');
      if (nanoRegex.hasMatch(trimmed)) {
        final truncated = trimmed.replaceFirstMapped(nanoRegex, (m) => m.group(1)!);
        parsed = DateTime.tryParse(truncated);
      }
    }

    // 3. If missing timezone offset or 'Z', treat backend ISO string as UTC
    if (parsed == null) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}').hasMatch(trimmed) &&
          !trimmed.endsWith('Z') &&
          !RegExp(r'[+-]\d{2}(?::?\d{2})?$').hasMatch(trimmed)) {
        parsed = DateTime.tryParse('${trimmed}Z');
      }
    }

    if (parsed == null) return null;

    // Ensure it is marked UTC
    if (parsed.isUtc) return parsed;

    // If input had no explicit timezone offset, the backend standard is UTC.
    final hasExplicitOffset = trimmed.endsWith('Z') ||
        RegExp(r'[+-]\d{2}(?::?\d{2})?$').hasMatch(trimmed);

    if (hasExplicitOffset) {
      return parsed.toUtc();
    } else {
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
    }
  }

  /// Formats a timestamp into a compact social media timestamp string.
  ///
  /// Supports:
  /// - [DateTime] objects
  /// - ISO-8601 Strings (including nanosecond precision like 2026-09-09T17:28:27.047050304Z)
  /// - Legacy relative strings ('2h ago', '5m', 'Just now')
  /// - Safe fallback for null or malformed data
  /// - Respects user's active locale (English / Khmer)
  static String format(
    dynamic timestamp, {
    DateTime? now,
    Locale? locale,
  }) {
    if (timestamp == null) return '';

    // Check target language
    final effectiveLocale = locale ?? Get.locale;
    final isKhmer = effectiveLocale?.languageCode.toLowerCase() == 'km';

    // Handle legacy relative strings or non-date strings
    if (timestamp is String) {
      final trimmed = timestamp.trim();
      if (trimmed.isEmpty) return '';

      // Normalize "just now"
      if (trimmed.toLowerCase() == 'just now' ||
          trimmed == 'ទើបតែឥឡូវ' ||
          trimmed == 'ទើបតែបន្តិចមុន') {
        return isKhmer ? 'ទើបតែឥឡូវ' : 'Just now';
      }

      // Check for legacy relative patterns: e.g. "5m ago", "2h ago", "1d ago", "5m", "2h", "1d"
      final relativeMatch = RegExp(r'^(\d+)\s*([mhd])(?:\s*ago)?$', caseSensitive: false)
          .firstMatch(trimmed);
      if (relativeMatch != null) {
        final count = relativeMatch.group(1)!;
        final unit = relativeMatch.group(2)!.toLowerCase();
        if (isKhmer) {
          switch (unit) {
            case 'm':
              return '$count នាទី';
            case 'h':
              return '$count ម៉ោង';
            case 'd':
              return '$count ថ្ងៃ';
          }
        } else {
          return '$count$unit';
        }
      }
    }

    // Parse DateTime as UTC
    final parsedUtc = parseToUtc(timestamp);
    if (parsedUtc == null) {
      // If it's a legacy calendar string (e.g. "Sep 9" or "Sep 9, 2025"), handle or fallback safely
      if (timestamp is String) {
        final trimmed = timestamp.trim();
        if (_isAlreadyFormattedDate(trimmed)) {
          return trimmed;
        }
      }
      // Never expose raw ISO or malformed strings
      return '';
    }

    // Convert both post timestamp and current reference to local timezone
    final localPost = parsedUtc.toLocal();
    final localNow = (now ?? DateTime.now()).toLocal();

    // Difference in time
    final diff = localNow.difference(localPost);

    // 1. Future timestamp or less than 1 minute -> "Just now"
    if (diff.isNegative || diff.inSeconds < 60) {
      return isKhmer ? 'ទើបតែឥឡូវ' : 'Just now';
    }

    // 2. < 1 hour -> "Xm"
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return isKhmer ? '$m នាទី' : '${m}m';
    }

    // 3. < 24 hours -> "Xh"
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return isKhmer ? '$h ម៉ោង' : '${h}h';
    }

    // 4. < 7 days -> "Xd"
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return isKhmer ? '$d ថ្ងៃ' : '${d}d';
    }

    // 5. 7+ days in the current year -> "MMM d" (or "d MMM" in Khmer)
    final mIndex = localPost.month - 1;
    final day = localPost.day;
    final year = localPost.year;

    final isSameYear = localPost.year == localNow.year;

    if (isSameYear) {
      if (isKhmer) {
        final monthName = (mIndex >= 0 && mIndex < 12) ? _kmMonths[mIndex] : '${mIndex + 1}';
        return '$day $monthName';
      } else {
        final monthName = (mIndex >= 0 && mIndex < 12) ? _enMonths[mIndex] : '${mIndex + 1}';
        return '$monthName $day';
      }
    }

    // 6. Previous year -> "MMM d, yyyy" (or "d MMM yyyy" in Khmer)
    if (isKhmer) {
      final monthName = (mIndex >= 0 && mIndex < 12) ? _kmMonths[mIndex] : '${mIndex + 1}';
      return '$day $monthName $year';
    } else {
      final monthName = (mIndex >= 0 && mIndex < 12) ? _enMonths[mIndex] : '${mIndex + 1}';
      return '$monthName $day, $year';
    }
  }

  static bool _isAlreadyFormattedDate(String str) {
    for (final m in _enMonths) {
      if (str.startsWith(m)) return true;
    }
    for (final m in _kmMonths) {
      if (str.contains(m)) return true;
    }
    return false;
  }
}

/// Convenience top-level function for [CommunityDateFormatter.format].
String formatCommunityTimestamp(
  dynamic timestamp, {
  DateTime? now,
  Locale? locale,
}) =>
    CommunityDateFormatter.format(timestamp, now: now, locale: locale);
