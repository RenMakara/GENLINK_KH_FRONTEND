import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
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

  final RxInt requiredPhotosCount = 0.obs;

  final RxInt maxSelectionCount = 0.obs;

  final Rx<StoryTemplateConfig?> selectedTemplate = Rx<StoryTemplateConfig?>(null);
  bool _isCheckingPermission = false;

  static const int pageSize = 60;
  final RxBool hasMore = true.obs;
  final RxBool isLoadingMore = false.obs;
  int _currentPage = 0;

  static PMFilter get storyFilter {
    try {
      if (Platform.isAndroid) {
        return CustomFilter.sql(
          where: '',
          orderBy: [
            OrderByItem.named(
              column: CustomColumns.android.dateTaken,
              isAsc: false,
            ),
            OrderByItem.named(
              column: CustomColumns.android.createDate,
              isAsc: false,
            ),
            OrderByItem.named(
              column: CustomColumns.android.modifiedDate,
              isAsc: false,
            ),
          ],
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        return CustomFilter.sql(
          where: '',
          orderBy: [
            OrderByItem.named(
              column: CustomColumns.base.createDate,
              isAsc: false,
            ),
            OrderByItem.named(
              column: CustomColumns.base.modifiedDate,
              isAsc: false,
            ),
          ],
        );
      }
    } catch (_) {}
    return storyFilterOptionGroup;
  }

  static FilterOptionGroup get storyFilterOptionGroup => FilterOptionGroup(
    orders: const [
      OrderOption(
        type: OrderOptionType.createDate,
        asc: false,
      ),
      OrderOption(
        type: OrderOptionType.updateDate,
        asc: false,
      ),
    ],
    createTimeCond: DateTimeCond.def().copyWith(ignore: true),
    updateTimeCond: DateTimeCond.def().copyWith(ignore: true),
  );

  static int getAssetTimestamp(AssetEntity asset) {
    final createSec = asset.createDateSecond ?? 0;
    if (createSec > 0) return createSec;
    final createMs = asset.createDateTime.millisecondsSinceEpoch ~/ 1000;
    if (createMs > 0) return createMs;
    final modSec = asset.modifiedDateSecond ?? 0;
    if (modSec > 0) return modSec;
    final modMs = asset.modifiedDateTime.millisecondsSinceEpoch ~/ 1000;
    if (modMs > 0) return modMs;
    return 0;
  }

  static int compareAssetsNewestFirst(AssetEntity a, AssetEntity b) {
    final aTime = getAssetTimestamp(a);
    final bTime = getAssetTimestamp(b);
    if (aTime != bTime) {
      // Descending: newer (larger timestamp) first
      return bTime.compareTo(aTime);
    }
    final aMod = a.modifiedDateSecond ?? 0;
    final bMod = b.modifiedDateSecond ?? 0;
    if (aMod != bMod) {
      return bMod.compareTo(aMod);
    }
    return b.id.compareTo(a.id);
  }

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
    if (_isCheckingPermission) return;
    _isCheckingPermission = true;
    if (!isLoading.value) {
      isLoading.value = true;
    }
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        hasPermission.value = true;
        isPermanentlyDenied.value = false;
        await fetchAlbumsAndMedia();
      } else {
        hasPermission.value = false;
        final bool permDenied = await _isMediaPermissionPermanentlyDenied(ps);
        isPermanentlyDenied.value = permDenied;
        isLoading.value = false;
      }
    } catch (_) {
      hasPermission.value = false;
      isPermanentlyDenied.value = false;
      isLoading.value = false;
    } finally {
      _isCheckingPermission = false;
    }
  }

  Future<bool> _isMediaPermissionPermanentlyDenied(PermissionState ps) async {
    if (Get.testMode) return false;
    if (ps == PermissionState.restricted) {
      return true;
    }
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          final isPhotosPermanentlyDenied =
              await Permission.photos.isPermanentlyDenied;
          return isPhotosPermanentlyDenied;
        } else {
          return await Permission.storage.isPermanentlyDenied;
        }
      } else if (Platform.isIOS) {
        return await Permission.photos.isPermanentlyDenied;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<void> openSettings() async {
    try {
      final opened = await openAppSettings();
      if (!opened) {
        await PhotoManager.openSetting();
      }
    } catch (_) {
      try {
        await PhotoManager.openSetting();
      } catch (_) {}
    }
  }

  Future<void> fetchAlbumsAndMedia() async {
    if (Get.testMode) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _currentPage = 0;
    hasMore.value = true;
    try {
      final isTemplate = selectedTemplate.value != null || requiredPhotosCount.value > 0;
      final requestType = isTemplate ? RequestType.image : RequestType.common;
      final List<AssetPathEntity> fetchedAlbums =
          await PhotoManager.getAssetPathList(
            type: requestType,
            onlyAll: false,
            filterOption: storyFilter,
          );
      albums.assignAll(fetchedAlbums);

      if (fetchedAlbums.isNotEmpty) {
        final targetAlbum = fetchedAlbums.firstWhere(
          (a) => a.isAll,
          orElse: () => fetchedAlbums.first,
        );
        currentAlbum.value = targetAlbum;
        final List<AssetEntity> recentMedia = await targetAlbum
            .getAssetListPaged(page: 0, size: pageSize);
        recentMedia.sort(compareAssetsNewestFirst);
        mediaAssets.assignAll(recentMedia);
        if (recentMedia.length < pageSize) {
          hasMore.value = false;
        }
      } else {
        mediaAssets.clear();
        hasMore.value = false;
      }
    } catch (_) {
      mediaAssets.clear();
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectAlbum(AssetPathEntity album) async {
    currentAlbum.value = album;
    isLoading.value = true;
    _currentPage = 0;
    hasMore.value = true;
    try {
      final List<AssetEntity> media = await album.getAssetListPaged(
        page: 0,
        size: pageSize,
      );
      media.sort(compareAssetsNewestFirst);
      mediaAssets.assignAll(media);
      if (media.length < pageSize) {
        hasMore.value = false;
      }
    } catch (_) {
      mediaAssets.clear();
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreMedia() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value || currentAlbum.value == null) {
      return;
    }
    isLoadingMore.value = true;
    try {
      final nextPage = _currentPage + 1;
      final List<AssetEntity> nextPageMedia = await currentAlbum.value!.getAssetListPaged(
        page: nextPage,
        size: pageSize,
      );
      if (nextPageMedia.isEmpty) {
        hasMore.value = false;
      } else {
        nextPageMedia.sort(compareAssetsNewestFirst);
        final existingIds = mediaAssets.map((e) => e.id).toSet();
        final filteredNew = nextPageMedia.where((e) => !existingIds.contains(e.id)).toList();
        if (filteredNew.isNotEmpty) {
          mediaAssets.addAll(filteredNew);
        }
        _currentPage = nextPage;
        if (nextPageMedia.length < pageSize) {
          hasMore.value = false;
        }
      }
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
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
