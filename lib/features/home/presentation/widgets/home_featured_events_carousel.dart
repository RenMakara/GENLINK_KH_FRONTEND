import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../community/domain/models/community_models.dart';
import '../../../community/presentation/screens/event_details_screen.dart';
import '../../domain/entities/home_entity.dart';

/// Featured Event on the GenLink KH Mobile Home Screen.
///
/// Follows Requirements 10 & 11:
/// - Uses the actual upcomingEvent from GET /api/v1/mobile/home
/// - Does not invent fake event data or fake carousel slides
/// - Renders a clean compact empty state if upcomingEvent is null
/// - Strong cover image, 2-line description, subtle orange calendar icon
/// - Opens EventDetailsScreen on tap
class HomeFeaturedEventsCarousel extends StatelessWidget {
  const HomeFeaturedEventsCarousel({
    super.key,
    this.upcomingEvent,
    this.onViewAll,
  });

  final UpcomingEvent? upcomingEvent;
  final VoidCallback? onViewAll;

  static const Color eventAccentColor = Color(0xFFF97316); // Orange

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardSurface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final sectionTitle = 'home.featuredEvents'.tr.isNotEmpty &&
            'home.featuredEvents'.tr != 'home.featuredEvents'
        ? 'home.featuredEvents'.tr.toUpperCase()
        : 'FEATURED EVENTS';

    final event = upcomingEvent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: FEATURED EVENTS (NO "See all", NO arrows)
        Text(
          sectionTitle,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
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

  Widget _buildEmptyState({
    required bool isDark,
    required Color cardSurface,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final emptyTitle = 'home.noEventsTitle'.tr.isNotEmpty &&
            'home.noEventsTitle'.tr != 'home.noEventsTitle'
        ? 'home.noEventsTitle'.tr
        : 'No upcoming events';

    final emptySubtitle = 'home.noEventsSubtitle'.tr.isNotEmpty &&
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
              color: eventAccentColor.withValues(
                alpha: isDark ? 0.14 : 0.10,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_outlined,
              size: 20,
              color: eventAccentColor,
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
    required UpcomingEvent event,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardSurface,
    required Color borderSubtle,
  }) {
    final heroTag = 'home-featured-event-${event.eventId}';

    final locationDisplay = (event.locationName != null &&
            event.locationName!.trim().isNotEmpty)
        ? event.locationName!
        : 'GenLink Campus';

    final isOnline = locationDisplay.toLowerCase().contains('online');

    final dateTimeDisplay = _formatDateTime(event.dateTime);

    final rawCat = (event.category != null && event.category!.trim().isNotEmpty)
        ? event.category!
        : 'Campus Event';

    final categoryDisplay = rawCat.toUpperCase();

    final joinedLabel = 'home.joined'.tr.isNotEmpty &&
            'home.joined'.tr != 'home.joined'
        ? 'home.joined'.tr
        : 'Joined';

    final viewDetailsLabel = 'home.viewDetails'.tr.isNotEmpty &&
            'home.viewDetails'.tr != 'home.viewDetails'
        ? 'home.viewDetails'.tr
        : 'View details';

    final descriptionText = (event.description != null &&
            event.description!.trim().isNotEmpty)
        ? event.description!
        : '';

    final participantCount = event.participantCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final eventModel = EventModel(
                id: event.eventId,
                title: event.title,
                subtitle: descriptionText,
                organizerName: 'GenLink Campus',
                eventType: isOnline ? 'Online' : 'In person',
                location: locationDisplay,
                dateString: dateTimeDisplay,
                timeString: '',
                description: descriptionText,
                category: rawCat,
                imageUrl: event.coverImageUrl ?? '',
                attendeesCount: participantCount,
              );
              Get.to(
                () => EventDetailsScreen(
                  event: eventModel,
                  heroTag: heroTag,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. Event Cover Image (Compact & Visually Strong) ──
                Stack(
                  children: [
                    SizedBox(
                      height: 125,
                      width: double.infinity,
                      child: Hero(
                        tag: heroTag,
                        child: _buildCoverImage(
                          event.coverImageUrl,
                          isDark,
                          textMuted,
                        ),
                      ),
                    ),

                    // Top-Left Category Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
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
                    ),
                  ],
                ),

                // ── 2. Compact Event Body ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),

                      // Description (up to 2 lines, ellipsis)
                      if (descriptionText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          descriptionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Date / Time row
                      if (dateTimeDisplay.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: eventAccentColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dateTimeDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 4),

                      // Location row
                      Row(
                        children: [
                          Icon(
                            isOnline
                                ? Icons.language_outlined
                                : Icons.location_on_outlined,
                            size: 12.5,
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
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Bottom row: Participant count + View Details →
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (participantCount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 13,
                                  color: textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$participantCount $joinedLabel',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                viewDetailsLabel,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: textPrimary,
                              ),
                            ],
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
    );
  }

  Widget _buildCoverImage(
    String? imageUrl,
    bool isDark,
    Color textMuted,
  ) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return Image.network(
        imageUrl.trim(),
        fit: BoxFit.cover,
        width: double.infinity,
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
      color: isDark ? const Color(0xFF1F1F23) : const Color(0xFFEBEBEB),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          color: textMuted,
          size: 32,
        ),
      ),
    );
  }

  static String _formatDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) {
      final months = [
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
        'Dec'
      ];
      final month = months[parsed.month - 1];
      final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final ampm = parsed.hour >= 12 ? 'PM' : 'AM';
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '${parsed.day} $month ${parsed.year} · $hour:$minute $ampm';
    }
    return raw;
  }
}
