import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../controllers/story_controller.dart';
import '../screens/story_viewer_screen.dart';
import 'story_creation_picker_sheet.dart';

class StoryTrayWidget extends StatelessWidget {
  const StoryTrayWidget({super.key});

  void _showCreateStorySheet(BuildContext context, StoryController controller) {
    StoryCreationPickerSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoryController());

    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 48,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final groups = controller.storyGroups;

      return Container(
        height: 105,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: groups.length,
          itemBuilder: (context, idx) {
            final group = groups[idx];

            if (group.isOwner) {
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    if (group.stories.isNotEmpty) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          transitionDuration: const Duration(milliseconds: 250),
                          reverseTransitionDuration: const Duration(milliseconds: 250),
                          pageBuilder: (context, animation, secondaryAnimation) => StoryViewerScreen(
                            initialGroupIndex: idx,
                            groups: groups,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    } else {
                      _showCreateStorySheet(context, controller);
                    }
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: group.stories.isNotEmpty ? AppColors.communityAccent : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: group.userAvatar.startsWith('assets/')
                                  ? AssetImage(group.userAvatar) as ImageProvider
                                  : NetworkImage(group.userAvatar),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: GestureDetector(
                              onTap: () => _showCreateStorySheet(context, controller),
                              child: Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.communityAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.darkBgPrimary, width: 1.5),
                                ),
                                child: const Icon(Icons.add, color: Colors.black, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Your Story",
                        style: TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      transitionDuration: const Duration(milliseconds: 250),
                      reverseTransitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (context, animation, secondaryAnimation) => StoryViewerScreen(
                        initialGroupIndex: idx,
                        groups: groups,
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: group.hasUnseen
                            ? const LinearGradient(
                                colors: [AppColors.communityAccent, Color(0xFFC8BFAE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        border: !group.hasUnseen
                            ? Border.all(color: AppColors.darkBorderSubtle, width: 1.5)
                            : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.darkBgPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: group.userAvatar.startsWith('assets/')
                              ? AssetImage(group.userAvatar) as ImageProvider
                              : NetworkImage(group.userAvatar),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 68,
                      child: Text(
                        group.userName,
                        style: TextStyle(
                          color: group.hasUnseen ? AppColors.darkTextPrimary : AppColors.darkTextMuted,
                          fontSize: 11,
                          fontWeight: group.hasUnseen ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
