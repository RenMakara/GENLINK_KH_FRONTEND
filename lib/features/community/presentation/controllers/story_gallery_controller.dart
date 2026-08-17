import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/storage/local_storage.dart';

class StoryGalleryController extends GetxController {
  final LocalStorage _localStorage = Get.find<LocalStorage>();
  
  final RxList<AssetEntity> mediaAssets = <AssetEntity>[].obs;
  final RxList<AssetEntity> selectedAssets = <AssetEntity>[].obs;
  
  final RxBool hasPermission = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasDraft = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkDrafts();
    _requestPermissionAndFetch();
  }

  Future<void> _checkDrafts() async {
    final draftData = await _localStorage.readStoryDraft();
    if (draftData != null && draftData.isNotEmpty) {
      hasDraft.value = true;
    }
  }

  Future<void> _requestPermissionAndFetch() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      hasPermission.value = true;
      await _fetchMedia();
    } else {
      hasPermission.value = false;
      isLoading.value = false;
    }
  }

  Future<void> _fetchMedia() async {
    isLoading.value = true;
    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        final AssetPathEntity recentAlbum = albums.first;
        final List<AssetEntity> recentMedia = await recentAlbum.getAssetListPaged(page: 0, size: 100);
        mediaAssets.assignAll(recentMedia);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelection(AssetEntity asset) {
    final isSelected = selectedAssets.contains(asset);
    if (isSelected) {
      selectedAssets.remove(asset);
    } else {
      selectedAssets.add(asset);
    }
  }

  int getSelectionIndex(AssetEntity asset) {
    final index = selectedAssets.indexOf(asset);
    return index >= 0 ? index + 1 : 0;
  }

  Future<void> saveDraft() async {
    if (selectedAssets.isNotEmpty) {
      await _localStorage.saveStoryDraft('{"draft": true}');
    }
  }

  Future<void> clearDraft() async {
    await _localStorage.deleteStoryDraft();
    hasDraft.value = false;
  }

  void discardDraftAndContinue() {
    clearDraft();
  }
}
