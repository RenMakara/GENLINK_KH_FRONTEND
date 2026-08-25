import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/models/story_template_model.dart';

class StoryGalleryController extends GetxController {
  final LocalStorage _localStorage = Get.find<LocalStorage>();

  final RxList<AssetEntity> mediaAssets = <AssetEntity>[].obs;
  final RxList<AssetEntity> selectedAssets = <AssetEntity>[].obs;
  final RxList<AssetPathEntity> albums = <AssetPathEntity>[].obs;
  final Rx<AssetPathEntity?> currentAlbum = Rx<AssetPathEntity?>(null);

  final RxBool hasPermission = false.obs;
  final RxBool isPermanentlyDenied = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasDraft = false.obs;
  final RxBool isMultiSelectMode = false.obs;

  /// Target number of photos required by the selected template (e.g. 1, 2, 3, 4).
  final RxInt requiredPhotosCount = 0.obs;

  /// Max selection limit for template selection.
  final RxInt maxSelectionCount = 0.obs;

  /// Active template configuration preset (if in template mode).
  final Rx<StoryTemplateConfig?> selectedTemplate = Rx<StoryTemplateConfig?>(null);

  /// Safely configures template photo limits and selection mode.
  /// Should be called from user actions (e.g. template selection, slot replacement)
  /// BEFORE navigation or widget building.
  void configureForTemplate({
    StoryTemplateConfig? template,
    int requiredPhotos = 0,
    int maxSelection = 0,
    bool isMultiSelect = false,
    bool clearSelection = true,
  }) {
    if (template != null) {
      if (selectedTemplate.value?.id != template.id) {
        selectedTemplate.value = template;
      }
      final count = template.slotCount;
      requiredPhotos = count;
      maxSelection = count;
      isMultiSelect = count > 1;
    } else if (requiredPhotos == 0 && selectedTemplate.value != null) {
      selectedTemplate.value = null;
    }

    if (clearSelection && selectedAssets.isNotEmpty) {
      selectedAssets.clear();
    }
    if (requiredPhotosCount.value != requiredPhotos) {
      requiredPhotosCount.value = requiredPhotos;
    }
    final targetMax = maxSelection > 0 ? maxSelection : requiredPhotos;
    if (maxSelectionCount.value != targetMax) {
      maxSelectionCount.value = targetMax;
    }
    if (isMultiSelectMode.value != isMultiSelect) {
      isMultiSelectMode.value = isMultiSelect;
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (!Get.testMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkDrafts();
        checkAndRequestPermission();
      });
    }
  }

  Future<void> _checkDrafts() async {
    try {
      final draftData = await _localStorage.readStoryDraft();
      if (draftData != null && draftData.isNotEmpty) {
        hasDraft.value = true;
      }
    } catch (_) {
      hasDraft.value = false;
    }
  }

  Future<void> checkAndRequestPermission() async {
    if (!isLoading.value) {
      isLoading.value = true;
    }
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        hasPermission.value = true;
        isPermanentlyDenied.value = false;
        await fetchAlbumsAndMedia();
      } else if (ps == PermissionState.denied ||
          ps == PermissionState.restricted) {
        hasPermission.value = false;
        isPermanentlyDenied.value = true;
        isLoading.value = false;
      } else {
        hasPermission.value = false;
        isPermanentlyDenied.value = false;
        isLoading.value = false;
      }
    } catch (_) {
      hasPermission.value = false;
      isPermanentlyDenied.value = false;
      isLoading.value = false;
    }
  }

  Future<void> openSettings() async {
    try {
      await PhotoManager.openSetting();
    } catch (_) {}
  }

  Future<void> fetchAlbumsAndMedia() async {
    isLoading.value = true;
    try {
      final List<AssetPathEntity> fetchedAlbums =
          await PhotoManager.getAssetPathList(
            type: RequestType.image,
            onlyAll: false,
          );
      albums.assignAll(fetchedAlbums);

      if (fetchedAlbums.isNotEmpty) {
        currentAlbum.value = fetchedAlbums.first;
        final List<AssetEntity> recentMedia = await fetchedAlbums.first
            .getAssetListPaged(page: 0, size: 150);
        mediaAssets.assignAll(recentMedia);
      } else {
        mediaAssets.clear();
      }
    } catch (_) {
      mediaAssets.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectAlbum(AssetPathEntity album) async {
    currentAlbum.value = album;
    isLoading.value = true;
    try {
      final List<AssetEntity> media = await album.getAssetListPaged(
        page: 0,
        size: 150,
      );
      mediaAssets.assignAll(media);
    } catch (_) {
      mediaAssets.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void toggleMultiSelectMode() {
    isMultiSelectMode.value = !isMultiSelectMode.value;
    if (!isMultiSelectMode.value && selectedAssets.length > 1) {
      final first = selectedAssets.first;
      selectedAssets.assignAll([first]);
    }
  }

  void selectAsset(AssetEntity asset) {
    if (isMultiSelectMode.value) {
      if (selectedAssets.contains(asset)) {
        selectedAssets.remove(asset);
      } else {
        if (maxSelectionCount.value > 0 &&
            selectedAssets.length >= maxSelectionCount.value) {
          Get.rawSnackbar(
            messageText: Text(
              "You can select up to ${maxSelectionCount.value} ${maxSelectionCount.value == 1 ? 'photo' : 'photos'} for this template.",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            backgroundColor: const Color(0xFF222226),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 75),
            borderRadius: 14,
            duration: const Duration(seconds: 2),
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white70,
              size: 20,
            ),
          );
          return;
        }
        selectedAssets.add(asset);
      }
    } else {
      if (selectedAssets.contains(asset)) {
        selectedAssets.clear();
      } else {
        selectedAssets.assignAll([asset]);
      }
    }
  }

  int getSelectionIndex(AssetEntity asset) {
    final index = selectedAssets.indexOf(asset);
    return index >= 0 ? index + 1 : 0;
  }

  Future<void> saveDraft() async {
    if (selectedAssets.isNotEmpty) {
      try {
        await _localStorage.saveStoryDraft('{"draft": true}');
      } catch (_) {}
    }
  }

  Future<void> clearDraft() async {
    try {
      await _localStorage.deleteStoryDraft();
    } catch (_) {}
    hasDraft.value = false;
  }

  void discardDraftAndContinue() {
    clearDraft();
  }
}
