import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/story_model.dart';
import '../screens/story_creator_screen.dart';
import '../screens/in_app_camera_screen.dart';

class StoryCreationPickerSheet extends StatelessWidget {
  const StoryCreationPickerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (ctx) => const StoryCreationPickerSheet(),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? media = await picker.pickMedia(imageQuality: 95);

      Get.back();

      if (media != null) {
        final pathLower = media.path.toLowerCase();
        final isVideo = pathLower.endsWith('.mp4') ||
            pathLower.endsWith('.mov') ||
            pathLower.endsWith('.avi') ||
            pathLower.endsWith('.mkv') ||
            pathLower.endsWith('.webm');

        Get.to(
          () => StoryCreatorScreen(
            type: isVideo ? StoryType.video : StoryType.photo,
            mediaPath: media.path,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Media Selection Error",
          message: "Could not open media file picker: $e",
        );
      }
    }
  }

  void _openCamera(BuildContext context) {
    Get.back();
    try {
      Get.to(() => const InAppCameraScreen(initialIsVideoMode: false));
    } catch (e) {
      if (context.mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Camera Error",
          message: "Could not open camera screen: $e",
        );
      }
    }
  }

  void _openTextStory(BuildContext context) {
    Get.back();
    Get.to(() => const StoryCreatorScreen(type: StoryType.text));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfacePrimary = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final iconBgColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBgSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Swipe Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : AppColors.lightBorderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "Create Story",
              style: TextStyle(
                color: textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 1. Camera Action
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_rounded, color: textPrimary, size: 22),
              ),
              title: Text(
                "Camera",
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () => _openCamera(context),
            ),
          ),

          const SizedBox(height: 4),

          // 2. Gallery Action
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_rounded, color: textPrimary, size: 22),
              ),
              title: Text(
                "Gallery",
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () => _pickFromGallery(context),
            ),
          ),

          const SizedBox(height: 4),

          // 3. Text Story Action
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.title_rounded, color: textPrimary, size: 22),
              ),
              title: Text(
                "Text Story",
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () => _openTextStory(context),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
