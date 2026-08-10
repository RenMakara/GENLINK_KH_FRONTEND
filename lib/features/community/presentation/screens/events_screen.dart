import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';

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
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
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
    final textSecondary = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF666666);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final cardBg = isDark ? const Color(0xFF181818) : const Color(0xFFF7F7F7);
    final borderSubtle = isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);
    final inputBg = isDark ? const Color(0xFF181818) : const Color(0xFFF2F2F2);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search & Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        hintStyle: TextStyle(color: textMuted, fontSize: 15),
                        prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Create Event shortcut button
                  GestureDetector(
                    onTap: () => Get.to(() => const CreateEventScreen()),
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
                            'Create',
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

            // ── Event List ───────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                final allEvents = _controller.events;
                final filtered = _searchQuery.isEmpty
                    ? allEvents
                    : allEvents
                        .where((e) =>
                            e.title.toLowerCase().contains(_searchQuery) ||
                            e.location.toLowerCase().contains(_searchQuery) ||
                            e.category.toLowerCase().contains(_searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_outlined, size: 56, color: textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No events yet.\nTap Create to add one!'
                              : 'No events match your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _EventCard(
                      event: filtered[index],
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      cardBg: cardBg,
                      borderSubtle: borderSubtle,
                    );
                  },
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
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color borderSubtle;

  const _EventCard({
    required this.event,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.borderSubtle,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLocalImage = event.coverImageFile != null;
    final bool hasNetworkImage = event.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => Get.to(() => EventDetailsScreen(event: event)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: hasLocalImage
                    ? Image.file(event.coverImageFile!, fit: BoxFit.cover)
                    : hasNetworkImage
                        ? Image.network(
                            event.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, _) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (event.category.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.category,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  Text(
                    event.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Date
                  if (event.dateString.isNotEmpty)
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: event.timeString.isNotEmpty
                          ? '${event.dateString} · ${event.timeString}'
                          : event.dateString,
                      color: textSecondary,
                    ),

                  // Location or Online
                  if (event.eventType == 'In person' && event.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: event.location,
                      color: textSecondary,
                    ),
                  ] else if (event.eventType == 'Online') ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.videocam_outlined,
                      text: 'Online Event',
                      color: textSecondary,
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Bottom row: attendees + View Event
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() {
                        final updated = Get.find<CommunityController>()
                            .events
                            .firstWhereOrNull((e) => e.id == event.id);
                        final count = updated?.attendeesCount ?? event.attendeesCount;
                        return Row(
                          children: [
                            Icon(Icons.people_outline, color: textMuted, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '$count Going',
                              style: TextStyle(color: textMuted, fontSize: 12),
                            ),
                          ],
                        );
                      }),
                      Text(
                        'View Event →',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 40,
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
