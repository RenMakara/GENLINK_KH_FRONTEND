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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cover Image (approx 16:9)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasLocalImage
                  ? Image.file(event.coverImageFile!, fit: BoxFit.cover)
                  : hasNetworkImage
                      ? Image.network(
                          event.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
            ),
          ),

          // 2. Event Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date, Time, Location
                Text(
                  event.timeString.isNotEmpty
                      ? '${event.dateString} · ${event.timeString} · ${event.location.isNotEmpty ? event.location : "Online"}'
                      : '${event.dateString} · ${event.location.isNotEmpty ? event.location : "Online"}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  event.title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Organizer and attendees
                Obx(() {
                  final updated = Get.find<CommunityController>()
                      .events
                      .firstWhereOrNull((e) => e.id == event.id);
                  final count = updated?.attendeesCount ?? event.attendeesCount;
                  
                  return Text(
                    '${event.organizerName.isNotEmpty ? event.organizerName : "GenLink Community"} · $count attendees',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }),

                const SizedBox(height: 20),

                // 3. Action Area
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Get.to(() => EventDetailsScreen(event: event)),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'View Event',
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {}, // Share logic
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: borderSubtle),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Icon(
                          Icons.ios_share,
                          color: textPrimary,
                          size: 20,
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
