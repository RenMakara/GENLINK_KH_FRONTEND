import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
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

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? media = await picker.pickMedia(imageQuality: 95);

      if (context.mounted) {
        Navigator.pop(context);
      }

      if (media != null && context.mounted) {
        final pathLower = media.path.toLowerCase();
        final isVideo = pathLower.endsWith('.mp4') ||
            pathLower.endsWith('.mov') ||
            pathLower.endsWith('.avi') ||
            pathLower.endsWith('.mkv') ||
            pathLower.endsWith('.webm');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => StoryCreatorScreen(
              type: isVideo ? StoryType.video : StoryType.photo,
              mediaPath: media.path,
            ),
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
    Navigator.pop(context);
    if (_isDesktopPlatform) {
      AppNotificationBanner.showSuccess(
        context: context,
        title: "Desktop Platform Notice",
        message: "Opening camera studio...",
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const InAppCameraScreen(initialIsVideoMode: false),
      ),
    );
  }

  void _openTextStory(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const StoryCreatorScreen(type: StoryType.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Header Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "Create Story",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 1. Camera Action
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
            ),
            title: const Text(
              "Camera",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () => _openCamera(context),
          ),

          const SizedBox(height: 4),

          // 2. Gallery Action
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
            ),
            title: const Text(
              "Gallery",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () => _pickFromGallery(context),
          ),

          const SizedBox(height: 4),

          // 3. Text Story Action
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.title_rounded, color: Colors.white, size: 22),
            ),
            title: const Text(
              "Text Story",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () => _openTextStory(context),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
