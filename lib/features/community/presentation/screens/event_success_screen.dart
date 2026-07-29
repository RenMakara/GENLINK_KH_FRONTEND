import 'package:flutter/material.dart';
import '../../../../design_system/colors/app_colors.dart';

class EventSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventSuccessScreen({
    super.key,
    required this.eventData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
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

              const Text(
                "Registration Successful!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "You have successfully registered for",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),

              const SizedBox(height: 24),

              // Event Ticket Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        eventData['image'] as String? ??
                            'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=300',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventData['title'] as String? ?? 'Flutter Workshop 2026',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "📅 25 July 2026 • 9:00 AM - 4:00 PM",
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const Text(
                            "📍 ACLEDA University",
                            style: TextStyle(color: Colors.white38, fontSize: 11),
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
                icon: Icons.confirmation_number_outlined,
                title: "View Ticket",
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.calendar_today_outlined,
                title: "Add to Calendar",
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.chat_bubble_outline,
                title: "Open Event Chat",
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
                  child: const Text(
                    "Back to Events",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
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
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
