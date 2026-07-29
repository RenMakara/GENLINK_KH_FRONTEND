import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../controllers/community_controller.dart';
import '../widgets/post_card_widget.dart';
import '../widgets/filter_events_sheet.dart';
import '../widgets/story_tray_widget.dart';
import 'create_post_screen.dart';

import '../widgets/community_header_widget.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunityController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: Obx(
          () => CommunityHeaderWidget(
            activeCategory: controller.selectedCategory.value,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              const SizedBox(height: 6),

              // Sticky Navigation Tabs (Feed, Forum, Career, Event)
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: controller.categories.map((cat) {
                      final isSelected = controller.selectedCategory.value == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => controller.setCategory(cat),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.darkTextPrimary
                                  : AppColors.darkSurfaceSecondary,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.darkTextPrimary
                                    : AppColors.darkBorderSubtle,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Dynamic Tab Content Body
              Expanded(
                child: Obx(() {
                  switch (controller.selectedCategory.value) {
                    case 'Forum':
                      return _buildForumTab(context, controller);
                    case 'Career':
                      return _buildCareerTab(context, controller);
                    case 'Event':
                      return _buildEventTab(context, controller);
                    case 'Feed':
                    default:
                      return _buildFeedTab(context, controller);
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: FEED TAB (Stories + Create Post + Community Feed + Polls + Recommendations)
  // ---------------------------------------------------------------------------
  Widget _buildFeedTab(BuildContext context, CommunityController controller) {
    return SingleChildScrollView(
      controller: controller.scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stories (ONLY in Feed Tab)
          const StoryTrayWidget(),

          const SizedBox(height: 8),

          // Create Post Quick Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen())),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorderSubtle),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/images/user_profile.png'),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "What's happening in your community, Sokny?",
                        style: TextStyle(
                          color: AppColors.darkTextMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.communityAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Feed Posts List
          Obx(
            () => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.posts.length,
              itemBuilder: (context, index) {
                final post = controller.posts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PostCardWidget(
                    post: post,
                    controller: controller,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: FORUM TAB (Discussions, Trending Topics, Forum Categories, Pinned)
  // ---------------------------------------------------------------------------
  Widget _buildForumTab(BuildContext context, CommunityController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Context-Aware Forum Search Bar
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.darkTextMuted, size: 20),
                  SizedBox(width: 10),
                  Text("Search Discussions & Topics...", style: TextStyle(color: AppColors.darkTextMuted, fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Trending Topics
            const Text(
              "🔥 Trending Topics",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['#FlutterTech', '#CampusHackathon', '#CADTDesign', '#RUPPExams', '#AIWorkshop'].map((topic) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.communityAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      topic,
                      style: const TextStyle(color: AppColors.communityAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Forum Categories
            const Text(
              "Forum Categories",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildForumCategoryCard("💻 Tech & Coding", "342 Discussions", AppColors.communityAccent),
                _buildForumCategoryCard("🎓 Campus Life", "189 Discussions", AppColors.success),
                _buildForumCategoryCard("📚 Academics", "256 Discussions", AppColors.warning),
                _buildForumCategoryCard("🚀 Projects", "120 Discussions", const Color(0xFF8B7CF6)),
              ],
            ),

            const SizedBox(height: 24),

            // Pinned & Latest Discussions List
            const Text(
              "📌 Pinned Discussions",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildForumThreadCard(
              title: "Guidelines for GenLink KH Annual Student Project Showcase 2026",
              author: "Admin Team",
              timeAgo: "1d ago",
              replies: 48,
              upvotes: 142,
              isPinned: true,
            ),
            _buildForumThreadCard(
              title: "Best resources to master Flutter state management with Riverpod?",
              author: "Sokchea Lim",
              timeAgo: "3h ago",
              replies: 16,
              upvotes: 34,
              isPinned: false,
            ),
            _buildForumThreadCard(
              title: "How to prepare for junior software engineer interviews in Cambodia?",
              author: "Rathana P.",
              timeAgo: "6h ago",
              replies: 29,
              upvotes: 65,
              isPinned: false,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildForumCategoryCard(String title, String count, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(count, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildForumThreadCard({
    required String title,
    required String author,
    required String timeAgo,
    required int replies,
    required int upvotes,
    required bool isPinned,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPinned ? AppColors.communityAccent.withValues(alpha: 0.4) : AppColors.darkBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPinned) ...[
                const Icon(Icons.push_pin, color: AppColors.communityAccent, size: 14),
                const SizedBox(width: 6),
              ],
              Text(author, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text("• $timeAgo", style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined, color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  Text("$upvotes", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  Text("$replies replies", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: CAREER TAB (Search Jobs, Internships, Mentors, Recruiter Events)
  // ---------------------------------------------------------------------------
  Widget _buildCareerTab(BuildContext context, CommunityController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Context-Aware Career Search Bar
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.work_outline, color: AppColors.darkTextMuted, size: 20),
                  SizedBox(width: 10),
                  Text("Search Jobs, Internships & Mentors...", style: TextStyle(color: AppColors.darkTextMuted, fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recommended Opportunities Hero List
            const Text(
              "🎯 Recommended Opportunities",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildJobCard(
              title: "Junior Flutter Developer",
              company: "ABA Bank • Phnom Penh",
              type: "Full-Time",
              salary: "\$600 - \$900 / mo",
              logoColor: const Color(0xFF00529B),
            ),
            _buildJobCard(
              title: "UI/UX Design Intern",
              company: "Smart Axiata • Phnom Penh",
              type: "Internship",
              salary: "\$250 - \$350 / mo",
              logoColor: const Color(0xFFE31B23),
            ),

            const SizedBox(height: 24),

            // Campus Alumni Mentors
            const Text(
              "👨‍🏫 Campus Alumni Mentors",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMentorCard("Sokha Kim", "Senior Tech Lead @ Wing", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150"),
                  _buildMentorCard("Bopha V.", "Lead UX Designer @ ABA", "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"),
                  _buildMentorCard("Dara N.", "Mobile Architect @ Chip Mong", "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150"),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard({
    required String title,
    required String company,
    required String type,
    required String salary,
    required Color logoColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: logoColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: logoColor.withValues(alpha: 0.4)),
            ),
            child: Center(child: Icon(Icons.business_rounded, color: logoColor, size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(company, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.communityAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(type, style: const TextStyle(color: AppColors.communityAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(salary, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorCard(String name, String role, String avatar) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorderSubtle),
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 26, backgroundImage: NetworkImage(avatar)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
          const SizedBox(height: 2),
          Text(role, style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10), textAlign: TextAlign.center, maxLines: 2),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.communityAccent, padding: EdgeInsets.zero),
              child: const Text("Book 1-on-1", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: EVENT TAB (Search, Filters, Featured Carousel, Categories, List)
  // ---------------------------------------------------------------------------
  Widget _buildEventTab(BuildContext context, CommunityController controller) {
    final List<Map<String, dynamic>> eventsList = [
      {
        'title': 'Flutter Mobile Dev Workshop 2026',
        'subtitle': 'Build Cross-platform Apps with Flutter & Dart',
        'category': 'Workshop',
        'time': '9:00 AM – 4:00 PM',
        'location': 'ACLEDA Institute',
        'going': '120 Going',
        'image': 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
      },
      {
        'title': 'GenLink KH Hackathon 2026',
        'subtitle': 'Code. Solve. Impact.',
        'category': 'Hackathon',
        'time': '8:00 AM – 8:00 PM',
        'location': 'Diamond Island Convention',
        'going': '230 Going',
        'image': 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800',
      },
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Filter Row (Local Events Search)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorderSubtle),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.darkTextMuted, size: 20),
                        SizedBox(width: 10),
                        Text("Search Events & Workshops...", style: TextStyle(color: AppColors.darkTextMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const FilterEventsSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.communityAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.communityAccent),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.communityAccent, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Featured Events Carousel
            const Text(
              "🌟 Featured Events",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: eventsList.length,
                itemBuilder: (context, idx) {
                  final ev = eventsList[idx];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(image: NetworkImage(ev['image']), fit: BoxFit.cover),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(ev['location'], style: const TextStyle(color: AppColors.communityAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Event List
            const Text(
              "📅 Upcoming Events",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...eventsList.map((ev) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorderSubtle),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(ev['image'], width: 75, height: 75, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(ev['location'], style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(ev['time'], style: const TextStyle(color: AppColors.communityAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
