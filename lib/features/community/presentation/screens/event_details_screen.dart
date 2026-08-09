import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'event_register_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final surfacePrimary = isDark ? const Color(0xFF181818) : Colors.white;
    final tileBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5);
    final borderSubtle = isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;

    final bool hasNetworkImage = event.imageUrl.isNotEmpty;
    final bool hasLocalImage = event.coverImageFile != null;

    final controller = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : null;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Image with Back / Share ─────────────────────────
                Stack(
                  children: [
                    // Image area
                    SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: hasLocalImage
                          ? Image.file(event.coverImageFile!, fit: BoxFit.cover)
                          : hasNetworkImage
                              ? Image.network(
                                  event.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, _) => _placeholderCover(isDark),
                                )
                              : _placeholderCover(isDark),
                    ),
                    // Gradient overlay
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                            bgPrimary,
                          ],
                        ),
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: 48,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    // Share button
                    Positioned(
                      top: 48,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        child: IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ),
                    // Category badge (only if category exists)
                    if (event.category.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.category,
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Event Title & Subtitle ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      if (event.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.subtitle,
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // ── Quick Info Cards ──────────────────────────────
                      // Date & Time
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
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
                          icon: Icons.location_on_outlined,
                          line1: event.location,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          tileBg: tileBg,
                          borderSubtle: borderSubtle,
                        )
                      else if (event.eventType == 'Online' && event.onlineLink.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.videocam_outlined,
                          line1: 'Online Event',
                          line2: event.onlineLink,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          tileBg: tileBg,
                          borderSubtle: borderSubtle,
                        )
                      else
                        _buildInfoRow(
                          icon: Icons.place_outlined,
                          line1: 'Location TBC',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          tileBg: tileBg,
                          borderSubtle: borderSubtle,
                        ),
                      const SizedBox(height: 10),

                      // Organizer
                      _buildInfoRow(
                        icon: Icons.hub_outlined,
                        line1: event.organizerName.isNotEmpty ? event.organizerName : 'Unknown',
                        line2: 'Organizer',
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
                              return _buildInfoRow(
                                icon: Icons.people_outline,
                                line1: '$count Going',
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                tileBg: tileBg,
                                borderSubtle: borderSubtle,
                              );
                            })
                          : _buildInfoRow(
                              icon: Icons.people_outline,
                              line1: '${event.attendeesCount} Going',
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              tileBg: tileBg,
                              borderSubtle: borderSubtle,
                            ),

                      const SizedBox(height: 24),

                      // ── About This Event ──────────────────────────────
                      Text(
                        'community.aboutThisEvent'.tr,
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
                            : 'No description provided.',
                        style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
                      ),

                      const SizedBox(height: 120),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: surfacePrimary,
                border: Border(top: BorderSide(color: borderSubtle)),
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
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isRsvped
              ? (isDark ? const Color(0xFF303030) : const Color(0xFFF0F0F0))
              : (isDark ? Colors.white : Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRsvped) ...[
              Icon(Icons.check, color: isDark ? Colors.white : Colors.black87, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              isRsvped ? 'Going' : 'community.registerNow'.tr,
              style: TextStyle(
                color: isRsvped
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.black : Colors.white),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: textSecondary, size: 20),
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
      color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
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
