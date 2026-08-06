import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import 'event_details_screen.dart';
import 'event_register_screen.dart';
import '../widgets/filter_events_sheet.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> eventsList = [
    {
      'dateHeader': '25 JUL 2026',
      'title': 'Flutter Workshop 2026',
      'subtitle': 'Build Cross-platform Apps with Flutter',
      'category': 'Workshop',
      'categoryColor': AppColors.productivityAccent,
      'time': '9:00 AM – 4:00 PM',
      'location': 'ACLEDA University',
      'going': '120 Going',
      'image': 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
      'actionType': 'Register',
    },
    {
      'dateHeader': '26 JUL 2026',
      'title': 'AI in Everyday Life',
      'subtitle': 'Explore how AI is changing the world',
      'category': 'Seminar',
      'categoryColor': AppColors.financeAccent,
      'time': '2:00 PM – 5:00 PM',
      'location': 'Institute of Technology',
      'going': '85 Going',
      'image': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
      'actionType': 'View Details',
    },
    {
      'dateHeader': '30 JUL 2026',
      'title': 'GenLink Hackathon 2026',
      'subtitle': 'Code. Solve. Impact.',
      'category': 'Hackathon',
      'categoryColor': AppColors.growthAccent,
      'time': '8:00 AM – 8:00 PM',
      'location': 'Diamond Island Convention',
      'going': '230 Going',
      'image': 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800',
      'actionType': 'Register',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final textMuted = isDark ? Colors.white54 : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBorderSubtle;
    final inputBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightBgSecondary;
    final filterBg = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBgSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo Mark
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF2563EB)],
              ).createShader(bounds),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 6),
            Text(
              "GENLINK",
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6), width: 1.5),
              ),
              child: Text("KH", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.search, color: textSecondary), onPressed: () {}),
          IconButton(icon: Icon(Icons.chat_bubble_outline, color: textSecondary), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications_none, color: textSecondary), onPressed: () {}),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Category Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Feed', 'Forum', 'Career', 'Event'].map((cat) {
                      final isSelected = cat == 'Event';
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? textPrimary
                              : inputBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Search & Filter Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'community.searchEventsHint'.tr,
                          hintStyle: TextStyle(color: textMuted),
                          prefixIcon: Icon(Icons.search, color: textMuted),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const FilterEventsSheet(),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: filterBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune, color: textPrimary, size: 18),
                            const SizedBox(width: 6),
                            Text('community.filterEvents'.tr, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Events List by Date Headers
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: eventsList.length,
                  itemBuilder: (context, index) {
                    final item = eventsList[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 10),
                          child: Text(
                            item['dateHeader'] as String,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Event Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: surfaceSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Banner & Badge
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    child: Image.network(
                                      item['image'] as String,
                                      height: 170,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item['categoryColor'] as Color,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item['category'] as String,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                                      child: const Icon(Icons.bookmark_border, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),

                              // Content Info
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtitle'] as String,
                                      style: TextStyle(color: textSecondary, fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, color: textMuted, size: 15),
                                        const SizedBox(width: 6),
                                        Text(item['time'] as String, style: TextStyle(color: textSecondary, fontSize: 12)),
                                        const SizedBox(width: 16),
                                        Icon(Icons.location_on_outlined, color: textMuted, size: 15),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item['location'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: textSecondary, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.people_outline, color: textMuted, size: 16),
                                            const SizedBox(width: 6),
                                            Text(item['going'] as String, style: TextStyle(color: textMuted, fontSize: 12)),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 38,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (item['actionType'] == 'Register') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => EventRegisterScreen(eventData: item)),
                                                );
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => EventDetailsScreen(eventData: item)),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: item['actionType'] == 'Register'
                                                  ? const Color(0xFF6D28D9)
                                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBgSecondary),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              item['actionType'] as String,
                                              style: TextStyle(
                                                color: item['actionType'] == 'Register' ? Colors.white : textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
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
                      ],
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
