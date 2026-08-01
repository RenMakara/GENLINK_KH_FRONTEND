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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final skeletonColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

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
                    backgroundColor: skeletonColor,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 48,
                    height: 10,
                    decoration: BoxDecoration(
                      color: skeletonColor,
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
                      Get.to(
                        () => StoryViewerScreen(
                          initialGroupIndex: idx,
                          groups: groups,
                        ),
                        opaque: false,
                        transition: Transition.fadeIn,
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
                              radius: 28,
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
                                  border: Border.all(color: bgPrimary, width: 1.5),
                                ),
                                child: const Icon(Icons.add, color: Colors.black, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Your Story",
                        style: TextStyle(
                          color: textPrimary,
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
                  Get.to(
                    () => StoryViewerScreen(
                      initialGroupIndex: idx,
                      groups: groups,
                    ),
                    opaque: false,
                    transition: Transition.fadeIn,
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
                            ? Border.all(color: borderSubtle, width: 1.5)
                            : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: bgPrimary,
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
                          color: group.hasUnseen ? textPrimary : textMuted,
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
