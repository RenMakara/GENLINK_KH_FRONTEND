import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_creation_flow.dart';
import 'event_details_screen.dart';
import 'my_events_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final CommunityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CommunityController>();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark
        ? const Color(0xFFA6A6A6)
        : const Color(0xFF666666);
    final textMuted = isDark
        ? const Color(0xFF666666)
        : const Color(0xFF999999);
    final cardBg = isDark ? const Color(0xFF181818) : const Color(0xFFF7F7F7);
    final borderSubtle = isDark
        ? const Color(0xFF303030)
        : const Color(0xFFE0E0E0);
    final inputBg = isDark ? const Color(0xFF181818) : const Color(0xFFF2F2F2);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText:
                            'community.searchEvents'.tr.isNotEmpty &&
                                'community.searchEvents'.tr !=
                                    'community.searchEvents'
                            ? 'community.searchEvents'.tr
                            : 'Search events...',
                        hintStyle: TextStyle(color: textMuted, fontSize: 15),
                        prefixIcon: Icon(
                          Icons.search,
                          color: textMuted,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: textMuted,
                                  size: 18,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'community.myEvents'.tr,
                    onPressed: () => Get.to(() => const MyEventsScreen()),
                    icon: Icon(Icons.event_note_outlined, color: textPrimary),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => CommunityCreationFlow.openCreateEvent(context),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: textPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: bg, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'community.create'.tr.isNotEmpty &&
                                    'community.create'.tr != 'community.create'
                                ? 'community.create'.tr
                                : 'Create',
                            style: TextStyle(
                              color: bg,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Obx(() {
                if (_controller.isLoadingEvents.value &&
                    _controller.events.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: textPrimary,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                if (_controller.hasEventsError.value &&
                    _controller.events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 48,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderSubtle),
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              size: 36,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _controller.eventsErrorMessage.value.isNotEmpty
                                ? _controller.eventsErrorMessage.value
                                : ('community.unableToLoadEvents'
                                              .tr
                                              .isNotEmpty &&
                                          'community.unableToLoadEvents'.tr !=
                                              'community.unableToLoadEvents'
                                      ? 'community.unableToLoadEvents'.tr
                                      : 'Unable to load events'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () => _controller.fetchEvents(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white
                                  : Colors.black87,
                              foregroundColor: isDark
                                  ? Colors.black87
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              'community.tryAgain'.tr.isNotEmpty &&
                                      'community.tryAgain'.tr !=
                                          'community.tryAgain'
                                  ? 'community.tryAgain'.tr
                                  : 'Retry',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allEvents = _controller.events;
                final filtered = _searchQuery.isEmpty
                    ? allEvents
                    : allEvents
                          .where(
                            (e) =>
                                e.title.toLowerCase().contains(_searchQuery) ||
                                e.location.toLowerCase().contains(
                                  _searchQuery,
                                ) ||
                                e.category.toLowerCase().contains(_searchQuery),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _controller.refreshEvents(),
                    color: AppColors.communityAccent,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 48,
                                    color: textMuted,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? ('community.noUpcomingEvents'
                                                      .tr
                                                      .isNotEmpty &&
                                                  'community.noUpcomingEvents'
                                                          .tr !=
                                                      'community.noUpcomingEvents'
                                              ? 'community.noUpcomingEvents'.tr
                                              : 'No upcoming events')
                                        : 'No events match your search.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_searchQuery.isEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'community.newEventsAppearHere'
                                                  .tr
                                                  .isNotEmpty &&
                                              'community.newEventsAppearHere'
                                                      .tr !=
                                                  'community.newEventsAppearHere'
                                          ? 'community.newEventsAppearHere'.tr
                                          : 'New events will appear here.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _controller.refreshEvents(),
                  color: AppColors.communityAccent,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 300) {
                        _controller.loadMoreEvents();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount:
                          filtered.length +
                          (_controller.hasMoreEvents.value ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return Center(
                            child: _controller.isLoadingMoreEvents.value
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 12),
                          );
                        }
                        return _EventCard(
                          event: filtered[index],
                          controller: _controller,
                          index: index,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          textMuted: textMuted,
                          cardBg: cardBg,
                          borderSubtle: borderSubtle,
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final CommunityController controller;
  final int index;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color borderSubtle;

  const _EventCard({
    required this.event,
    required this.controller,
    this.index = 0,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.borderSubtle,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = event.eventType.toLowerCase().contains('online');
    final String onlineLabel =
        'community.onlineEvent'.tr.isNotEmpty &&
            'community.onlineEvent'.tr != 'community.onlineEvent'
        ? 'community.onlineEvent'.tr
        : 'Online Event';
    final String inPersonLabel =
        'community.inPerson'.tr.isNotEmpty &&
            'community.inPerson'.tr != 'community.inPerson'
        ? 'community.inPerson'.tr
        : 'In Person';
    final String locationDisplay = isOnline
        ? '🌐 $onlineLabel'
        : '📍 ${event.effectiveLocationName.isNotEmpty ? event.effectiveLocationName : (event.location.isNotEmpty ? event.location : inPersonLabel)}';

    String dateDisplay = '';
    if (event.formattedDateRange.isNotEmpty &&
        event.formattedTimeRange.isNotEmpty) {
      dateDisplay =
          '📅 ${event.formattedDateRange} · ${event.formattedTimeRange}';
    } else if (event.formattedDateRange.isNotEmpty) {
      dateDisplay = '📅 ${event.formattedDateRange}';
    } else if (event.timeString.isNotEmpty && event.dateString.isNotEmpty) {
      dateDisplay = '📅 ${event.dateString} · ${event.timeString}';
    } else if (event.dateString.isNotEmpty) {
      dateDisplay = '📅 ${event.dateString}';
    }

    final String rawCat = event.category.isNotEmpty ? event.category : 'Event';
    final String catKey = 'community.${rawCat.toLowerCase()}';
    final String categoryDisplay = catKey.tr.isNotEmpty && catKey.tr != catKey
        ? catKey.tr
        : rawCat;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 240 + (index.clamp(0, 5) * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(
            () => EventDetailsScreen(
              event: event,
              heroTag: 'event-image-${event.id}-standalone',
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle, width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: Hero(
                      tag: 'event-image-${event.id}-standalone',
                      child: _buildImage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: borderSubtle.withValues(alpha: 0.6),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIconData(event.category),
                                  size: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  categoryDisplay,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (event.isPaid) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.communityAccent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'community.paid'.tr.isNotEmpty &&
                                        'community.paid'.tr != 'community.paid'
                                    ? 'community.paid'.tr.toUpperCase()
                                    : 'PAID',
                                style: const TextStyle(
                                  color: AppColors.communityAccent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                controller.toggleEventBookmark(event.id);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: AnimatedScale(
                                  scale: event.isBookmarked ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutBack,
                                  child: Icon(
                                    event.isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: event.isBookmarked
                                        ? (isDark
                                              ? Colors.white
                                              : Colors.black87)
                                        : textMuted,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      Text(
                        event.title,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      if (dateDisplay.isNotEmpty) ...[
                        Text(
                          dateDisplay,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],

                      Text(
                        locationDisplay,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildImage() {
    if (event.coverImageFile != null) {
      return Image.file(
        event.coverImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    if (event.imageUrl.isNotEmpty) {
      return Image.network(
        event.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: isDark ? const Color(0xFF1E2228) : const Color(0xFFE9ECF0),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: isDark ? const Color(0xFF1E2228) : const Color(0xFFE9ECF0),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          color: textMuted.withValues(alpha: 0.6),
          size: 28,
        ),
      ),
    );
  }

  IconData _getCategoryIconData(String cat) {
    switch (cat.toLowerCase()) {
      case 'technology':
        return Icons.computer_outlined;
      case 'design':
      case 'arts':
      case 'art':
        return Icons.palette_outlined;
      case 'business':
        return Icons.business_center_outlined;
      case 'career':
        return Icons.work_outline_rounded;
      case 'education':
        return Icons.school_outlined;
      case 'workshop':
        return Icons.build_outlined;
      case 'competition':
        return Icons.emoji_events_outlined;
      case 'sports':
      case 'sport':
        return Icons.sports_soccer_outlined;
      case 'social':
        return Icons.people_outline_rounded;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'seminar':
        return Icons.groups_outlined;
      case 'hackathon':
        return Icons.terminal_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
