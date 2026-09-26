import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/story_gallery_controller.dart';
import '../screens/create_discussion_screen.dart';
import '../screens/create_event_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/story_gallery_screen.dart';
import 'community_creation_bottom_sheet.dart';
import 'story_creation_picker_sheet.dart';

abstract final class CommunityCreationFlow {
  static Future<void> openCreateMenu([BuildContext? context]) async {
    final ctx = context ?? Get.context;
    if (ctx == null) return;
    return showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => CommunityCreationBottomSheet(
        onSelectCreatePost: () {
          Navigator.pop(bottomSheetContext);
          openCreatePost(ctx);
        },
        onSelectCreateStory: () {
          Navigator.pop(bottomSheetContext);
          openCreateStory(ctx);
        },
        onSelectCreateEvent: () {
          Navigator.pop(bottomSheetContext);
          openCreateEvent(ctx);
        },
      ),
    );
  }

  static Future<T?> openCreatePost<T>([BuildContext? context]) async {
    return Get.to<T>(
      () => const CreatePostScreen(),
      routeName: '/CreatePostScreen',
      transition: Transition.cupertino,
    );
  }

  static Future<T?> openCreatePostWithPhoto<T>([BuildContext? context]) async {
    return Get.to<T>(
      () => const CreatePostScreen(autoOpenGallery: true),
      routeName: '/CreatePostScreen',
      transition: Transition.cupertino,
    );
  }

  static Future<T?> openCreatePostWithCamera<T>([BuildContext? context]) async {
    return Get.to<T>(
      () => const CreatePostScreen(autoOpenCamera: true),
      routeName: '/CreatePostScreen',
      transition: Transition.cupertino,
    );
  }

  static Future<T?> openCreateStory<T>([BuildContext? context]) async {
    final ctx = context ?? Get.context;
    if (ctx != null) {
      StoryCreationPickerSheet.show(ctx);
      return null;
    }

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

  static Future<T?> openCreateDiscussion<T>([BuildContext? context]) async {
    return Get.to<T>(
      () => const CreateDiscussionScreen(),
      routeName: '/CreateDiscussionScreen',
      transition: Transition.cupertino,
    );
  }

  static Future<T?> openCreateEvent<T>([BuildContext? context]) async {
    return Get.to<T>(
      () => const CreateEventScreen(),
      routeName: '/CreateEventScreen',
      transition: Transition.cupertino,
    );
  }
}
