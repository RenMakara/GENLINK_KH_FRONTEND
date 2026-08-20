import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/storage/local_storage.dart';

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

  @override
  void onInit() {
    super.onInit();
    _checkDrafts();
    checkAndRequestPermission();
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
    isLoading.value = true;
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
