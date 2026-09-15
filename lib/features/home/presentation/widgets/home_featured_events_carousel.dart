import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../community/domain/models/community_models.dart';
import '../../../community/presentation/controllers/community_controller.dart';
import '../../../community/presentation/screens/event_details_screen.dart';
import '../../domain/entities/home_entity.dart';

class HomeFeaturedEventsCarousel extends StatelessWidget {
  const HomeFeaturedEventsCarousel({
    super.key,
    this.upcomingEvent,
    this.onViewAll,
  });

  final UpcomingEvent? upcomingEvent;
  final VoidCallback? onViewAll;

  static const Map<String, int> _monthMap = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final cardSurface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final sectionTitle = 'home.featuredEvents'.tr;

    if (upcomingEvent != null) {
      final adapted = _convertLegacyUpcomingEvent(upcomingEvent!);
      return _buildSection(
        context: context,
        sectionTitle: sectionTitle,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        cardSurface: cardSurface,
        borderSubtle: borderSubtle,
        event: adapted,
      );
    }

    if (Get.isRegistered<CommunityController>()) {
      final controller = Get.find<CommunityController>();
      return Obx(() {
        final isLoading =
            controller.isLoadingFeed.value && controller.events.isEmpty;

        if (isLoading) {
          return _buildLoadingSkeleton(
            sectionTitle: sectionTitle,
            isDark: isDark,
            textPrimary: textPrimary,
            cardSurface: cardSurface,
            borderSubtle: borderSubtle,
          );
        }

        final targetEvent = _resolveFeaturedEvent(controller.events);

        return _buildSection(
          context: context,
          sectionTitle: sectionTitle,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          cardSurface: cardSurface,
          borderSubtle: borderSubtle,
          event: targetEvent,
        );
      });
    }

    return _buildSection(
      context: context,
      sectionTitle: sectionTitle,
      isDark: isDark,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      cardSurface: cardSurface,
      borderSubtle: borderSubtle,
      event: null,
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String sectionTitle,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardSurface,
    required Color borderSubtle,
    required EventModel? event,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            if (onViewAll != null)
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'home.seeAll'.tr,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        if (event == null)
          _buildEmptyState(
            isDark: isDark,
            cardSurface: cardSurface,
            borderSubtle: borderSubtle,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          )
        else
          _buildEventCard(
            context: context,
            event: event,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardSurface: cardSurface,
            borderSubtle: borderSubtle,
          ),
      ],
    );
  }

  Widget _buildLoadingSkeleton({
    required String sectionTitle,
    required bool isDark,
    required Color textPrimary,
    required Color cardSurface,
    required Color borderSubtle,
  }) {
    final shimmerBase = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: TextStyle(
            color: textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: borderSubtle, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 155,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 220,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: shimmerBase,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 80,
                          decoration: BoxDecoration(
                            color: shimmerBase,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required Color cardSurface,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final emptyTitle =
        'home.noEventsTitle'.tr.isNotEmpty &&
            'home.noEventsTitle'.tr != 'home.noEventsTitle'
        ? 'home.noEventsTitle'.tr
        : 'No upcoming events';

    final emptySubtitle =
        'home.noEventsSubtitle'.tr.isNotEmpty &&
            'home.noEventsSubtitle'.tr != 'home.noEventsSubtitle'
        ? 'home.noEventsSubtitle'.tr
        : 'Check back later for campus activities.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.event_outlined,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emptyTitle,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  emptySubtitle,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required BuildContext context,
    required EventModel event,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardSurface,
    required Color borderSubtle,
  }) {
    final heroTag = 'event-cover-${event.id}';

    final isOnline =
        event.eventType.toLowerCase() == 'online' ||
        (event.mode?.toUpperCase() == 'ONLINE') ||
        (event.location.toLowerCase().contains('online')) ||
        (event.locationName?.toLowerCase().contains('online') == true);

    final String locationDisplay;
    if (isOnline) {
      locationDisplay = 'home.onlineEvent'.tr;
    } else if (event.location.trim().isNotEmpty) {
      locationDisplay = event.location.trim();
    } else if (event.locationName != null &&
        event.locationName!.trim().isNotEmpty) {
      locationDisplay = event.locationName!.trim();
    } else {
      locationDisplay = 'GenLink Campus';
    }

    final dateTimeDisplay = _formatEventDateTime(
      event.dateString,
      event.timeString,
      event.startDateTime,
    );

    final String categoryDisplay;
    if (event.category.trim().isNotEmpty) {
      categoryDisplay = event.category.trim().toUpperCase();
    } else {
      categoryDisplay = 'GenLink Event';
    }

    final viewEventLabel = 'home.viewEvent'.tr;

    final descriptionText = event.subtitle.trim().isNotEmpty
        ? event.subtitle.trim()
        : event.description.trim();

    final isJoined =
        event.isRsvped ||
        event.myRsvpStatus?.toUpperCase() == 'GOING' ||
        event.myRsvpStatus?.toUpperCase() == 'REGISTERED';

    final participantCount = event.attendeesCount;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 8 * (1.0 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderSubtle, width: 0.8),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToDetails(event, heroTag),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 155,
                        width: double.infinity,
                        child: Hero(
                          tag: heroTag,
                          child: _buildCoverImage(
                            event.imageUrl,
                            isDark,
                            textMuted,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.6,
                                ),
                              ),
                              child: const Text(
                                'UPCOMING EVENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                categoryDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isJoined)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 0.7,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 11.5,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Joined',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        if (descriptionText.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            descriptionText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (dateTimeDisplay.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12.5,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  dateTimeDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                        Row(
                          children: [
                            Icon(
                              isOnline
                                  ? Icons.language_outlined
                                  : Icons.location_on_outlined,
                              size: 13,
                              color: textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locationDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (participantCount > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 13.5,
                                    color: textMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$participantCount',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox.shrink(),
                            Material(
                              color: isDark ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: InkWell(
                                onTap: () => _navigateToDetails(event, heroTag),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        viewEventLabel,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 13,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(EventModel event, String heroTag) {
    Get.to(() => EventDetailsScreen(event: event, heroTag: heroTag));
  }

  Widget _buildCoverImage(String? imageUrl, bool isDark, Color textMuted) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      final trimmed = imageUrl.trim();
      if (trimmed.startsWith('assets/')) {
        return Image.asset(
          trimmed,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 155,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholder(isDark, textMuted),
        );
      }
      return Image.network(
        trimmed,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 155,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(isDark, textMuted),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(isDark, textMuted);
        },
      );
    }
    return _buildPlaceholder(isDark, textMuted);
  }

  Widget _buildPlaceholder(bool isDark, Color textMuted) {
    return Container(
      color: isDark ? const Color(0xFF1F1F23) : const Color(0xFFF4F4F5),
      child: Center(
        child: Icon(Icons.event_outlined, color: textMuted, size: 36),
      ),
    );
  }

  static EventModel _convertLegacyUpcomingEvent(UpcomingEvent legacy) {
    final isOnline =
        legacy.locationName?.toLowerCase().contains('online') == true;
    return EventModel(
      id: legacy.eventId,
      title: legacy.title,
      subtitle: legacy.description ?? '',
      organizerName: 'GenLink Campus',
      eventType: isOnline ? 'Online' : 'In person',
      location: legacy.locationName ?? 'GenLink Campus',
      dateString: legacy.dateTime ?? '',
      description: legacy.description ?? '',
      category: legacy.category ?? '',
      imageUrl: legacy.coverImageUrl ?? '',
      attendeesCount: legacy.participantCount ?? 0,
    );
  }

  static EventModel? resolveFeaturedEvent(List<EventModel> events) =>
      _resolveFeaturedEvent(events);

  static EventModel? _resolveFeaturedEvent(List<EventModel> events) {
    final published = events.where((e) {
      final s = e.status.toUpperCase();
      return s == 'PUBLISHED' || s.isEmpty;
    }).toList();

    if (published.isEmpty) return null;

    final now = DateTime.now();
    final upcoming = <MapEntry<EventModel, DateTime>>[];

    for (final e in published) {
      final date = _resolveEventDate(e);
      if (date != null && (date.isAfter(now) || date.isAtSameMomentAs(now))) {
        upcoming.add(MapEntry(e, date));
      }
    }

    if (upcoming.isNotEmpty) {
      upcoming.sort((a, b) => a.value.compareTo(b.value));
      return upcoming.first.key;
    }

    // Fallback: If no future published events are found (e.g. mock/demo data where dates
    // might precede the current device time in test environments), return the first published event.
    return published.first;
  }

  static DateTime? _resolveEventDate(EventModel event) {
    if (event.startDateTime != null) {
      return event.startDateTime;
    }
    final dateStr = event.dateString.trim();
    if (dateStr.isNotEmpty) {
      final isoParsed = DateTime.tryParse(dateStr);
      if (isoParsed != null) return isoParsed;

      final regexDayMonthYear = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})');
      final matchDMY = regexDayMonthYear.firstMatch(dateStr);
      if (matchDMY != null) {
        final day = int.tryParse(matchDMY.group(1)!);
        final monthStr = matchDMY.group(2)!.toLowerCase();
        final year = int.tryParse(matchDMY.group(3)!);
        final month =
            _monthMap[monthStr.length >= 3
                ? monthStr.substring(0, 3)
                : monthStr];
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }

      final regexMonthDayYear = RegExp(r'^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})');
      final matchMDY = regexMonthDayYear.firstMatch(dateStr);
      if (matchMDY != null) {
        final monthStr = matchMDY.group(1)!.toLowerCase();
        final day = int.tryParse(matchMDY.group(2)!);
        final year = int.tryParse(matchMDY.group(3)!);
        final month =
            _monthMap[monthStr.length >= 3
                ? monthStr.substring(0, 3)
                : monthStr];
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  static String _formatEventDateTime(
    String dateStr,
    String timeStr,
    DateTime? startDateTime,
  ) {
    final d = dateStr.trim();
    final t = timeStr.trim();
    if (d.isNotEmpty && t.isNotEmpty) {
      return '$d · $t';
    }
    if (d.isNotEmpty) {
      return d;
    }
    if (startDateTime != null) {
      const months = [
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
      final m = months[startDateTime.month - 1];
      final base = '${startDateTime.day} $m ${startDateTime.year}';
      if (t.isNotEmpty) return '$base · $t';
      return base;
    }
    return t;
  }
}
