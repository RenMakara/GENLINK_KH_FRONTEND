import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'event_register_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final String? heroTag;

  const EventDetailsScreen({
    super.key,
    required this.event,
    this.heroTag,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final surfacePrimary = isDark ? const Color(0xFF141414) : Colors.white;
    final tileBg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF7F7F8);
    final borderSubtle = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;

    final bool hasNetworkImage = event.imageUrl.isNotEmpty;
    final bool hasLocalImage = event.coverImageFile != null;

    final controller = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : null;

    final effectiveHeroTag = widget.heroTag ?? 'event-image-${event.id}';

    return Scaffold(
      backgroundColor: bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Image with Back / Bookmark / Share ───────────────
                Stack(
                  children: [
                    // Hero Image area
                    Hero(
                      tag: effectiveHeroTag,
                      child: SizedBox(
                        height: 290,
                        width: double.infinity,
                        child: hasLocalImage
                            ? Image.file(event.coverImageFile!, fit: BoxFit.cover)
                            : hasNetworkImage
                                ? Image.network(
                                    event.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _placeholderCover(isDark),
                                  )
                                : _placeholderCover(isDark),
                      ),
                    ),

                    // Subtle top & bottom gradient overlay for readability
                    Container(
                      height: 290,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                            Colors.transparent,
                            bgPrimary.withValues(alpha: 0.95),
                          ],
                          stops: const [0.0, 0.25, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Top Action Bar
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // Back button
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.black.withValues(alpha: 0.55),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Spacer(),

                            // Bookmark button
                            if (controller != null)
                              Obx(() {
                                final ev = controller.events.firstWhereOrNull(
                                  (e) => e.id == event.id,
                                );
                                final isBookmarked = ev?.isBookmarked ?? event.isBookmarked;
                                return CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                                  child: IconButton(
                                    icon: Icon(
                                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                      color: isBookmarked ? AppColors.communityAccent : Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      controller.toggleEventBookmark(event.id);
                                      final nowSaved = !(isBookmarked);
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            nowSaved ? 'community.savedToBookmarks'.tr : 'community.removedFromBookmarks'.tr,
                                            style: TextStyle(color: textPrimary),
                                          ),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              })
                            else
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.black.withValues(alpha: 0.55),
                                child: IconButton(
                                  icon: Icon(
                                    _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                    color: _isBookmarked ? AppColors.communityAccent : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _isBookmarked = !_isBookmarked);
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isBookmarked ? 'community.savedToBookmarks'.tr : 'community.removedFromBookmarks'.tr,
                                          style: TextStyle(color: textPrimary),
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(width: 8),

                            // Share button
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.black.withValues(alpha: 0.55),
                              child: IconButton(
                                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'community.share'.tr,
                                        style: TextStyle(color: textPrimary),
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Badges (Category & Format)
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Row(
                        children: [
                          if (event.category.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.communityAccent,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                ('community.${event.category.toLowerCase()}'.tr.isNotEmpty &&
                                        'community.${event.category.toLowerCase()}'.tr != 'community.${event.category.toLowerCase()}'
                                    ? 'community.${event.category.toLowerCase()}'.tr
                                    : event.category).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black87,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              (event.eventType.toLowerCase().contains('online')
                                  ? ('community.onlineEvent'.tr.isNotEmpty && 'community.onlineEvent'.tr != 'community.onlineEvent' ? 'community.onlineEvent'.tr : 'ONLINE')
                                  : ('community.inPerson'.tr.isNotEmpty && 'community.inPerson'.tr != 'community.inPerson' ? 'community.inPerson'.tr : 'IN PERSON')).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Event Title & Subtitle ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      if (event.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.subtitle,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // ── Quick Info Cards ──────────────────────────────
                      // Date & Time
                      _buildInfoRow(
                        icon: Icons.calendar_today_rounded,
                        line1: event.dateString.isNotEmpty ? event.dateString : 'Date TBC',
                        line2: event.timeString.isNotEmpty ? event.timeString : null,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        tileBg: tileBg,
                        borderSubtle: borderSubtle,
                      ),
                      const SizedBox(height: 10),

                      // Location OR Online Link
                      if (event.eventType == 'In person' && event.location.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.location_on_rounded,
                          line1: event.location,
                          line2: 'community.physicalVenue'.tr.isNotEmpty && 'community.physicalVenue'.tr != 'community.physicalVenue'
                              ? 'community.physicalVenue'.tr
                              : 'Physical Venue',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          tileBg: tileBg,
                          borderSubtle: borderSubtle,
                        )
                      else if (event.eventType == 'Online' && event.onlineLink.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.videocam_rounded,
                          line1: 'community.onlineEvent'.tr.isNotEmpty && 'community.onlineEvent'.tr != 'community.onlineEvent'
                              ? 'community.onlineEvent'.tr
                              : 'Online Event',
                          line2: event.onlineLink,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          tileBg: tileBg,
                          borderSubtle: borderSubtle,
                        )
                      else
                        _buildInfoRow(
                          icon: Icons.place_rounded,
                          line1: 'Location TBC',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          tileBg: tileBg,
                          borderSubtle: borderSubtle,
                        ),
                      const SizedBox(height: 10),

                      // Organizer
                      _buildInfoRow(
                        icon: Icons.hub_rounded,
                        line1: event.organizerName.isNotEmpty ? event.organizerName : 'GenLink Community',
                        line2: 'community.organizer'.tr.isNotEmpty && 'community.organizer'.tr != 'community.organizer'
                            ? 'community.organizer'.tr
                            : 'Event Organizer',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        tileBg: tileBg,
                        borderSubtle: borderSubtle,
                      ),
                      const SizedBox(height: 10),

                      // Ticket / Price Info
                      _buildInfoRow(
                        icon: Icons.confirmation_number_outlined,
                        line1: event.isPaid
                            ? '${event.priceKhr.toInt()} KHR'
                            : ('community.freeEntry'.tr.isNotEmpty && 'community.freeEntry'.tr != 'community.freeEntry'
                                ? 'community.freeEntry'.tr
                                : ('community.free'.tr.isNotEmpty && 'community.free'.tr != 'community.free' ? 'community.free'.tr : 'Free Entry')),
                        line2: event.isPaid
                            ? ('community.standardTicket'.tr.isNotEmpty && 'community.standardTicket'.tr != 'community.standardTicket'
                                ? 'community.standardTicket'.tr
                                : 'Standard Ticket')
                            : ('community.noRegistrationFee'.tr.isNotEmpty && 'community.noRegistrationFee'.tr != 'community.noRegistrationFee'
                                ? 'community.noRegistrationFee'.tr
                                : 'No Registration Fee'),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        tileBg: tileBg,
                        borderSubtle: borderSubtle,
                      ),
                      const SizedBox(height: 10),

                      // Attendees (reactive)
                      controller != null
                          ? Obx(() {
                              final ev = controller.events.firstWhereOrNull(
                                (e) => e.id == event.id,
                              );
                              final count = ev?.attendeesCount ?? event.attendeesCount;
                              final goingLabel = 'community.going'.tr.isNotEmpty && 'community.going'.tr != 'community.going'
                                  ? 'community.going'.tr
                                  : 'Going';
                              final attendeesLabel = 'community.registeredAttendees'.tr.isNotEmpty && 'community.registeredAttendees'.tr != 'community.registeredAttendees'
                                  ? 'community.registeredAttendees'.tr
                                  : 'Registered Attendees';
                              return _buildInfoRow(
                                icon: Icons.people_alt_rounded,
                                line1: '$count $goingLabel',
                                line2: attendeesLabel,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                tileBg: tileBg,
                                borderSubtle: borderSubtle,
                              );
                            })
                          : _buildInfoRow(
                              icon: Icons.people_alt_rounded,
                              line1: '${event.attendeesCount} ${'community.going'.tr}',
                              line2: 'community.registeredAttendees'.tr,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              tileBg: tileBg,
                              borderSubtle: borderSubtle,
                            ),

                      const SizedBox(height: 24),

                      // ── About This Event ──────────────────────────────
                      Text(
                        'community.aboutThisEvent'.tr.isNotEmpty &&
                                'community.aboutThisEvent'.tr != 'community.aboutThisEvent'
                            ? 'community.aboutThisEvent'.tr
                            : 'About This Event',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.description.isNotEmpty
                            ? event.description
                            : 'Discover opportunities, meet peers, and grow your skills with this student community event.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 130),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed Bottom RSVP Bar ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 8
                    : 20,
              ),
              decoration: BoxDecoration(
                color: surfacePrimary,
                border: Border(top: BorderSide(color: borderSubtle, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: controller != null
                  ? Obx(() {
                      final ev = controller.events.firstWhereOrNull(
                        (e) => e.id == event.id,
                      );
                      final isRsvped = ev?.isRsvped ?? event.isRsvped;
                      return _buildRsvpButton(
                        context: context,
                        isRsvped: isRsvped,
                        isDark: isDark,
                        onTap: () {
                          if (isRsvped) {
                            controller.toggleRsvp(event.id);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventRegisterScreen(event: event),
                              ),
                            );
                          }
                        },
                      );
                    })
                  : _buildRsvpButton(
                      context: context,
                      isRsvped: event.isRsvped,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventRegisterScreen(event: event),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpButton({
    required BuildContext context,
    required bool isRsvped,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isRsvped
              ? (isDark ? const Color(0xFF282828) : const Color(0xFFEEEEEE))
              : (isDark ? Colors.white : Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: isRsvped
                ? BorderSide(
                    color: isDark ? const Color(0xFF3E3E3E) : const Color(0xFFD5D5D5),
                    width: 1.0,
                  )
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Row(
            key: ValueKey<bool>(isRsvped),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRsvped) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isRsvped
                    ? ('community.going'.tr.isNotEmpty && 'community.going'.tr != 'community.going'
                        ? 'community.going'.tr
                        : 'Going')
                    : ('community.registerNow'.tr.isNotEmpty &&
                            'community.registerNow'.tr != 'community.registerNow'
                        ? 'community.registerNow'.tr
                        : 'Register Now'),
                style: TextStyle(
                  color: isRsvped
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.black : Colors.white),
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String line1,
    String? line2,
    required Color textPrimary,
    required Color textSecondary,
    required Color tileBg,
    required Color borderSubtle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (line2 != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    line2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderCover(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F2),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 64,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }
}
