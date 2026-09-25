import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../media/domain/entities/media_entity.dart';
import '../../../media/domain/media_upload_service.dart';
import '../../../media/presentation/media_picker.dart';
import '../../domain/models/short_content_models.dart';
import '../../domain/repositories/short_content_repository.dart';

class ShortContentController extends GetxController {
  ShortContentController({
    ShortContentRepository? repository,
    this.mediaUploadService,
    this.pageSize = 20,
    this.autoLoadFeed = true,
  }) : _repository = repository ?? Get.find<ShortContentRepository>();

  final ShortContentRepository _repository;
  final MediaUploadService? mediaUploadService;
  final int pageSize;
  final bool autoLoadFeed;

  final items = <ShortContentModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final currentPage = (-1).obs;
  final errorMessage = RxnString();
  final loadMoreErrorMessage = RxnString();
  final actionErrorMessage = RxnString();
  final isCreating = false.obs;
  final uploadProgress = 0.0.obs;
  final createErrorMessage = RxnString();

  final likingIds = <String>{}.obs;
  final savingIds = <String>{}.obs;
  final sharingIds = <String>{}.obs;
  final deletingIds = <String>{}.obs;

  String? _category;

  MediaUploadService get _uploadService =>
      mediaUploadService ?? Get.find<MediaUploadService>();

  @override
  void onInit() {
    super.onInit();
    if (autoLoadFeed) loadFeed();
  }

  Future<void> loadFeed({String? category}) async {
    if (isLoading.value || isRefreshing.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    _category = _normalizeCategory(category) ?? _category;

    try {
      final page = await _repository.getFeed(
        page: 0,
        size: pageSize,
        category: _category,
      );
      _replaceFeed(page);
    } catch (error) {
      errorMessage.value = _messageForLoadError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFeed() async {
    if (isLoading.value || isRefreshing.value) return;
    isRefreshing.value = true;
    loadMoreErrorMessage.value = null;

    try {
      final page = await _repository.getFeed(
        page: 0,
        size: pageSize,
        category: _category,
      );
      _replaceFeed(page);
      errorMessage.value = null;
    } catch (error) {
      errorMessage.value = _messageForLoadError(error);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value ||
        isRefreshing.value ||
        isLoadingMore.value ||
        !hasMore.value) {
      return;
    }

    isLoadingMore.value = true;
    loadMoreErrorMessage.value = null;
    final nextPage = currentPage.value < 0 ? 0 : currentPage.value + 1;

    try {
      final page = await _repository.getFeed(
        page: nextPage,
        size: pageSize,
        category: _category,
      );
      _appendFeed(page);
    } catch (error) {
      loadMoreErrorMessage.value = _messageForLoadError(error);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<ShortContentModel?> loadById(String contentId) async {
    final normalizedId = contentId.trim();
    if (normalizedId.isEmpty) return null;

    final existing = _find(normalizedId);
    if (existing != null) return existing;

    try {
      final item = await _repository.getById(normalizedId);
      _insertCreated(item);
      return item;
    } catch (error) {
      errorMessage.value = _messageForLoadError(error);
      return null;
    }
  }

  ShortContentModel? itemById(String contentId) => _find(contentId.trim());

  Future<ShortContentModel?> createShortContent({
    required String title,
    required PickedMedia video,
    String? description,
    String? category,
    PickedMedia? thumbnail,
  }) async {
    if (isCreating.value) return null;

    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      createErrorMessage.value = _requiredTitleMessage();
      return null;
    }
    if (video.bytes.isEmpty || !video.contentType.startsWith('video/')) {
      createErrorMessage.value = _videoRequiredMessage();
      return null;
    }

    isCreating.value = true;
    uploadProgress.value = 0;
    createErrorMessage.value = null;
    final uploadedMediaIds = <String>[];

    try {
      final videoMedia = await _uploadService.upload(
        bytes: video.bytes,
        contentType: video.contentType,
        purpose: MediaPurpose.short,
        width: video.width,
        height: video.height,
        onProgress: (fraction) {
          uploadProgress.value =
              fraction.clamp(0.0, 1.0) * (thumbnail == null ? 0.9 : 0.7);
        },
      );
      _trackUploadedMedia(uploadedMediaIds, videoMedia);
      _ensureMediaUrl(videoMedia);

      MediaEntity? thumbnailMedia;
      if (thumbnail != null) {
        if (thumbnail.bytes.isEmpty ||
            !thumbnail.contentType.startsWith('image/')) {
          throw const AppError(
            message: 'The thumbnail must be a valid image.',
            errorCode: 'SHORT_CONTENT_INVALID_THUMBNAIL',
          );
        }
        thumbnailMedia = await _uploadService.upload(
          bytes: thumbnail.bytes,
          contentType: thumbnail.contentType,
          purpose: MediaPurpose.short,
          width: thumbnail.width,
          height: thumbnail.height,
          onProgress: (fraction) {
            uploadProgress.value = 0.7 + fraction.clamp(0.0, 1.0) * 0.2;
          },
        );
        _trackUploadedMedia(uploadedMediaIds, thumbnailMedia);
        _ensureMediaUrl(thumbnailMedia);
      }

      uploadProgress.value = 0.95;
      final created = await _repository.create(
        ShortContentCreateRequest(
          title: normalizedTitle,
          description: _normalizeOptional(description),
          category: _normalizeOptional(category),
          videoUrl: videoMedia.url,
          thumbnailUrl: thumbnailMedia?.url,
          videoMediaId: videoMedia.mediaId,
          thumbnailMediaId: thumbnailMedia?.mediaId,
        ),
      );
      uploadProgress.value = 1;
      _insertCreated(created);
      return created;
    } catch (error) {
      createErrorMessage.value = _messageForCreateError(error);
      await _deleteUploadedMedia(uploadedMediaIds);
      return null;
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> toggleLike(String contentId) async {
    final normalizedId = contentId.trim();
    final current = _find(normalizedId);
    if (normalizedId.isEmpty ||
        current == null ||
        likingIds.contains(normalizedId)) {
      return;
    }

    likingIds.add(normalizedId);
    actionErrorMessage.value = null;
    try {
      final updated = current.liked
          ? await _repository.unlike(normalizedId)
          : await _repository.like(normalizedId);
      _upsert(updated);
    } catch (error) {
      actionErrorMessage.value = _messageForActionError(error);
    } finally {
      likingIds.remove(normalizedId);
    }
  }

  Future<void> toggleSave(String contentId) async {
    final normalizedId = contentId.trim();
    final current = _find(normalizedId);
    if (normalizedId.isEmpty ||
        current == null ||
        savingIds.contains(normalizedId)) {
      return;
    }

    savingIds.add(normalizedId);
    actionErrorMessage.value = null;
    try {
      final updated = current.saved
          ? await _repository.unsave(normalizedId)
          : await _repository.save(normalizedId);
      _upsert(updated);
    } catch (error) {
      actionErrorMessage.value = _messageForActionError(error);
    } finally {
      savingIds.remove(normalizedId);
    }
  }

  Future<ShortContentModel?> share(String contentId) async {
    final normalizedId = contentId.trim();
    if (normalizedId.isEmpty || sharingIds.contains(normalizedId)) {
      return null;
    }

    sharingIds.add(normalizedId);
    actionErrorMessage.value = null;
    try {
      final updated = await _repository.share(normalizedId);
      _upsert(updated);
      return updated;
    } catch (error) {
      actionErrorMessage.value = _messageForActionError(error);
      return null;
    } finally {
      sharingIds.remove(normalizedId);
    }
  }

  Future<bool> delete(String contentId) async {
    final normalizedId = contentId.trim();
    if (normalizedId.isEmpty || deletingIds.contains(normalizedId)) {
      return false;
    }

    deletingIds.add(normalizedId);
    actionErrorMessage.value = null;
    try {
      await _repository.delete(normalizedId);
      items.removeWhere((item) => item.shortContentId == normalizedId);
      items.refresh();
      return true;
    } catch (error) {
      actionErrorMessage.value = _messageForActionError(error);
      return false;
    } finally {
      deletingIds.remove(normalizedId);
    }
  }

  bool isLiking(String contentId) => likingIds.contains(contentId);

  bool isSaving(String contentId) => savingIds.contains(contentId);

  bool isSharing(String contentId) => sharingIds.contains(contentId);

  bool isDeleting(String contentId) => deletingIds.contains(contentId);

  void clearCreateError() => createErrorMessage.value = null;

  ShortContentModel? _find(String contentId) {
    for (final item in items) {
      if (item.shortContentId == contentId) return item;
    }
    return null;
  }

  void _replaceFeed(ShortContentPage page) {
    items.assignAll(_validItems(page.content));
    currentPage.value = page.page;
    hasMore.value = page.hasNext;
  }

  void _appendFeed(ShortContentPage page) {
    final existingIds = items.map((item) => item.shortContentId).toSet();
    for (final item in _validItems(page.content)) {
      if (existingIds.add(item.shortContentId)) items.add(item);
    }
    currentPage.value = page.page;
    hasMore.value = page.hasNext;
  }

  void _upsert(ShortContentModel updated) {
    final index = items.indexWhere(
      (item) => item.shortContentId == updated.shortContentId,
    );
    if (index == -1) return;
    items[index] = updated;
    items.refresh();
  }

  void _insertCreated(ShortContentModel created) {
    if (created.shortContentId.trim().isEmpty) return;
    final existingIndex = items.indexWhere(
      (item) => item.shortContentId == created.shortContentId,
    );
    if (existingIndex >= 0) {
      items[existingIndex] = created;
      items.refresh();
      return;
    }
    items.insert(0, created);
  }

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static void _trackUploadedMedia(List<String> mediaIds, MediaEntity media) {
    final mediaId = media.mediaId.trim();
    if (mediaId.isNotEmpty) mediaIds.add(mediaId);
  }

  static void _ensureMediaUrl(MediaEntity media) {
    if (media.url.trim().isEmpty) {
      throw const AppError(
        message: 'The uploaded media URL was not returned.',
        errorCode: 'SHORT_CONTENT_MEDIA_URL_MISSING',
      );
    }
  }

  Future<void> _deleteUploadedMedia(List<String> mediaIds) async {
    for (final mediaId in mediaIds.reversed) {
      try {
        await _uploadService.delete(mediaId);
      } catch (_) {
        // Preserve the original publish error. The scheduled backend cleanup
        // also handles confirmed media that is never referenced by content.
      }
    }
  }

  static List<ShortContentModel> _validItems(
    Iterable<ShortContentModel> source,
  ) {
    return source
        .where((item) => item.shortContentId.trim().isNotEmpty)
        .toList(growable: false);
  }

  static String? _normalizeCategory(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _messageForLoadError(Object error) {
    if (error is AppError && error.message.trim().isNotEmpty) {
      return error.message;
    }
    final translated = 'shortContent.loadFailed'.tr;
    return translated == 'shortContent.loadFailed'
        ? 'Unable to load short content right now.'
        : translated;
  }

  String _messageForActionError(Object error) {
    if (error is AppError && error.message.trim().isNotEmpty) {
      return error.message;
    }
    final translated = 'shortContent.actionFailed'.tr;
    return translated == 'shortContent.actionFailed'
        ? 'This action could not be completed.'
        : translated;
  }

  String _messageForCreateError(Object error) {
    if (error is AppError && error.message.trim().isNotEmpty) {
      return error.message;
    }
    final translated = 'shortContent.createFailed'.tr;
    return translated == 'shortContent.createFailed'
        ? 'Unable to publish short content right now.'
        : translated;
  }

  String _requiredTitleMessage() {
    final translated = 'shortContent.titleRequired'.tr;
    return translated == 'shortContent.titleRequired'
        ? 'Add a title before publishing.'
        : translated;
  }

  String _videoRequiredMessage() {
    final translated = 'shortContent.videoRequired'.tr;
    return translated == 'shortContent.videoRequired'
        ? 'Select a video before publishing.'
        : translated;
  }
}
