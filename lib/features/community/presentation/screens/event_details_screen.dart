import 'package:flutter/material.dart';
import '../../../../design_system/colors/app_colors.dart';
import 'event_register_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventDetailsScreen({
    super.key,
    required this.eventData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfacePrimary = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Cover Image Hero with Back, Bookmark & Share Buttons
                Stack(
                  children: [
                    Image.network(
                      eventData['image'] as String? ??
                          'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                            bgPrimary,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 48,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 48,
                      right: 16,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.black.withValues(alpha: 0.5),
                            child: IconButton(
                              icon: const Icon(Icons.bookmark_border, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.black.withValues(alpha: 0.5),
                            child: IconButton(
                              icon: const Icon(Icons.share, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.communityAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          eventData['category'] as String? ?? 'Workshop',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Event Title & Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventData['title'] as String? ?? 'Flutter Workshop 2026',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eventData['subtitle'] as String? ?? 'Build Cross-platform Apps with Flutter',
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 20),

                      // Quick Info Grid (4 Cards)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                        children: [
                          _buildInfoTile(
                            context: context,
                            icon: Icons.calendar_today_outlined,
                            title: '25 July 2026',
                            subtitle: '9:00 AM – 4:00 PM',
                          ),
                          _buildInfoTile(
                            context: context,
                            icon: Icons.location_on_outlined,
                            title: 'ACLEDA University',
                            subtitle: 'Phnom Penh',
                          ),
                          _buildInfoTile(
                            context: context,
                            icon: Icons.hub_outlined,
                            title: 'Organizer',
                            subtitle: 'GenLink Cambodia',
                          ),
                          _buildInfoTile(
                            context: context,
                            icon: Icons.people_outline,
                            title: '120',
                            subtitle: 'Going',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // About This Event Section
                      Text(
                        "About This Event",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Join us for an intensive hands-on workshop where you'll learn how to build beautiful and high-performance cross-platform applications using Flutter.\n\nWhether you are a beginner or looking to enhance your skills, this workshop covers clean architecture, state management, and real-world backend API integration.",
                        style: TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Register Now Fixed Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfacePrimary,
                border: Border(top: BorderSide(color: borderSubtle)),
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventRegisterScreen(eventData: eventData),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.communityAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Register Now",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textMuted = isDark ? Colors.white54 : AppColors.lightTextSecondary;
    final tileBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightBgSecondary;
    final borderSubtle = isDark ? Colors.white10 : AppColors.lightBorderSubtle;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
