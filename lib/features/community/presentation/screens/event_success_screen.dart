import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/community_models.dart';

class EventSuccessScreen extends StatelessWidget {
  final EventModel event;

  const EventSuccessScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final textMuted = isDark ? Colors.white54 : AppColors.lightTextMuted;
    final textMutedSubtle = isDark ? Colors.white38 : AppColors.lightTextMuted;
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? Colors.white10 : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),

              // Confetti Green Circle Checkmark Icon
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'community.registrationSuccessful'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'community.registeredSuccessfullySub'.tr,
                style: TextStyle(color: textMuted, fontSize: 13),
              ),

              const SizedBox(height: 24),

              // Event Ticket Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: event.coverImageFile != null
                          ? Image.file(
                              event.coverImageFile!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : event.imageUrl.isNotEmpty
                              ? Image.network(
                                  event.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 70,
                                    height: 70,
                                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                                    child: Icon(Icons.event_outlined, color: textMuted, size: 32),
                                  ),
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.event_outlined, color: textMuted, size: 32),
                                ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (event.dateString.isNotEmpty)
                            Text(
                              '\u{1F4C5} ${event.dateString}${event.timeString.isNotEmpty ? ' \u2022 ${event.timeString}' : ''}',
                              style: TextStyle(color: textSecondary, fontSize: 11),
                            ),
                          if (event.eventType == 'In person' && event.location.isNotEmpty)
                            Text(
                              '\u{1F4CD} ${event.location}',
                              style: TextStyle(color: textMutedSubtle, fontSize: 11),
                            )
                          else if (event.eventType == 'Online')
                            Text(
                              '\u{1F4F9} Online Event',
                              style: TextStyle(color: textMutedSubtle, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Options Card Buttons
              _buildActionTile(
                context: context,
                icon: Icons.confirmation_number_outlined,
                title: 'community.viewTicket'.tr,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                context: context,
                icon: Icons.calendar_today_outlined,
                title: 'community.addToCalendar'.tr,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                context: context,
                icon: Icons.chat_bubble_outline,
                title: 'community.openEventChat'.tr,
                onTap: () {},
              ),

              const Spacer(),

              // Back to Events Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.communityAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'community.backToEvents'.tr,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? Colors.white10 : AppColors.lightBorderSubtle;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: textSecondary, size: 20),
          title: Text(
            title,
            style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white38 : AppColors.lightTextMuted),
          onTap: onTap,
        ),
      ),
    );
  }
}
