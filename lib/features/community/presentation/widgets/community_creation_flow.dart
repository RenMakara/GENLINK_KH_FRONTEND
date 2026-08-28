import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/story_gallery_controller.dart';
import '../screens/create_event_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/story_gallery_screen.dart';
import 'community_creation_bottom_sheet.dart';

/// Centralized creation flow helper for GenLink KH Community.
///
/// Ensures consistent behavior and navigation across all entry points
/// (Home dashboard, Community screen, and Global '+' center nav button).
abstract final class CommunityCreationFlow {
  /// Opens the central Creation Menu bottom sheet.
  ///
  /// Presents options:
  /// - Create Post -> Navigates to [CreatePostScreen]
  /// - Create Story -> Navigates to [StoryGalleryScreen]
  /// - Create Event -> Navigates to [CreateEventScreen]
  static Future<void> openCreateMenu([BuildContext? context]) async {
    final ctx = context ?? Get.context;
    if (ctx == null) return;

    return showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (sheetContext) => CommunityCreationBottomSheet(
        onSelectCreatePost: () {
          Navigator.of(sheetContext).pop();
          openCreatePost();
        },
        onSelectCreateStory: () {
          Navigator.of(sheetContext).pop();
          openCreateStory();
        },
        onSelectCreateEvent: () {
          Navigator.of(sheetContext).pop();
          openCreateEvent();
        },
      ),
    );
  }

  /// Navigates directly to the Create Post composer screen.
  static Future<T?> openCreatePost<T>([BuildContext? context]) async {
    return Get.to<T>(
      () => const CreatePostScreen(),
      routeName: '/CreatePostScreen',
      transition: Transition.cupertino,
    );
  }

  /// Navigates directly to the Story Creator hub screen.
  static Future<T?> openCreateStory<T>([BuildContext? context]) async {
    final galleryCtrl = Get.isRegistered<StoryGalleryController>()
        ? Get.find<StoryGalleryController>()
        : Get.put(StoryGalleryController());

    galleryCtrl.configureForTemplate(
      template: null,
      requiredPhotos: 0,
      maxSelection: 0,
      isMultiSelect: false,
      clearSelection: true,
    );

    return Get.to<T>(
      () => const StoryGalleryScreen(),
      routeName: '/StoryGalleryScreen',
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  /// Navigates directly to the Create Event screen.
  static Future<T?> openCreateEvent<T>([BuildContext? context]) async {
    return Get.to<T>(
      () => const CreateEventScreen(),
      routeName: '/CreateEventScreen',
      transition: Transition.cupertino,
    );
  }
}
