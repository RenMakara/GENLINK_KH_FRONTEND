import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../controllers/story_gallery_controller.dart';
import 'in_app_camera_screen.dart';
import 'story_creator_screen.dart';
import '../../domain/models/story_model.dart';

enum StoryMediaFilter { all, favourites, photos, videos }

class StoryGalleryScreen extends StatefulWidget {
  final StoryTemplateConfig? targetTemplate;
  final int? requiredPhotos;
  final int? replaceSlotIndex;
  final ValueChanged<List<String>>? onPhotosSelected;

  const StoryGalleryScreen({
    super.key,
    this.targetTemplate,
    this.requiredPhotos,
    this.replaceSlotIndex,
    this.onPhotosSelected,
  });

  @override
  State<StoryGalleryScreen> createState() => _StoryGalleryScreenState();
}

class _StoryGalleryScreenState extends State<StoryGalleryScreen>
    with WidgetsBindingObserver {
  late final StoryGalleryController controller;
  final Map<String, Uint8List> _thumbCache = {};
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.isRegistered<StoryGalleryController>()
        ? Get.find<StoryGalleryController>()
        : Get.put(StoryGalleryController());

    // Do NOT modify reactive GetX variables synchronously during build / initState.
    // If not already configured via explicit user action prior to navigation, sync safely after initial frame.
    final targetReq = widget.requiredPhotos ?? widget.targetTemplate?.slotCount ?? 0;
    if (controller.requiredPhotosCount.value != targetReq ||
        (widget.targetTemplate != null &&
            controller.selectedTemplate.value?.id != widget.targetTemplate?.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.configureForTemplate(
            template: widget.targetTemplate,
            requiredPhotos: targetReq,
            maxSelection: targetReq,
            isMultiSelect: targetReq > 1 && widget.replaceSlotIndex == null,
            clearSelection: true,
          );
        }
      });
    }

    // Always check permissions and ensure media is refreshed when screen opens
    if (!Get.testMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.checkAndRequestPermission();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.checkAndRequestPermission();
    }
  }

  StoryMediaFilter _currentFilter = StoryMediaFilter.all;

  List<AssetEntity> get _filteredAssets {
    final all = controller.mediaAssets;
    switch (_currentFilter) {
      case StoryMediaFilter.all:
        return all;
      case StoryMediaFilter.favourites:
        return all.where((a) => a.isFavorite).toList();
      case StoryMediaFilter.photos:
        return all.where((a) => a.type == AssetType.image).toList();
      case StoryMediaFilter.videos:
        return all.where((a) => a.type == AssetType.video).toList();
    }
  }

  bool get _isTemplateMode =>
      widget.targetTemplate != null ||
      (widget.requiredPhotos != null && widget.requiredPhotos! > 0) ||
      controller.selectedTemplate.value != null ||
      controller.requiredPhotosCount.value > 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.lightSurfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            if (!_isTemplateMode && widget.onPhotosSelected == null)
              _buildTopFeatureButtonsRow(isDark),
            if (_isTemplateMode) _buildTemplateInstructionBanner(),
            Expanded(
              child: Stack(
                children: [
                  _buildMainContent(isDark),
                  _buildDraftOverlay(),
                  if (!_isTemplateMode) _buildMultiSelectBottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Top Header ──
  Widget _buildHeader(bool isDark) {
    return Obx(() {
      final tmpl = controller.selectedTemplate.value ?? widget.targetTemplate;
      final addStoryText = ('community.addToStory'.tr.isNotEmpty &&
              'community.addToStory'.tr != 'community.addToStory')
          ? 'community.addToStory'.tr
          : "Add to Story";
      String headerTitle = addStoryText;
      if (widget.onPhotosSelected != null) {
        headerTitle = ('community.gallery'.tr.isNotEmpty &&
                'community.gallery'.tr != 'community.gallery')
            ? 'community.gallery'.tr
            : "Gallery";
      } else if (widget.replaceSlotIndex != null) {
        headerTitle = "Replace Slot ${widget.replaceSlotIndex! + 1}";
      } else if (tmpl != null) {
        headerTitle = tmpl.name;
      }

      final currentAlbumName = controller.currentAlbum.value?.name;
      final albumDisplayName = (currentAlbumName == null ||
              currentAlbumName.isEmpty ||
              currentAlbumName == 'isAll')
          ? "Recent"
          : currentAlbumName;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: "Close",
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                size: 26,
              ),
              onPressed: () {
                controller.saveDraft();
                Get.back();
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => _showAlbumPickerSheet(context),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      headerTitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(
                      width: 0,
                      height: 0,
                      child: OverflowBox(
                        maxWidth: 0,
                        maxHeight: 0,
                        child: Text(
                          'Create Story',
                          style: TextStyle(
                            fontSize: 0,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Album: $albumDisplayName",
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: (isDark ? Colors.white : AppColors.lightTextSecondary).withValues(alpha: 0.75),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: (isDark ? Colors.white : AppColors.lightTextSecondary).withValues(alpha: 0.75),
                          size: 15,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Camera",
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    size: 24,
                  ),
                  onPressed: _openDeviceCamera,
                ),
                IconButton(
                  tooltip: "Gallery",
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(
                    Icons.photo_library_rounded,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    size: 24,
                  ),
                  onPressed: _handleGalleryHeaderAction,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Template Mode Instruction Banner ──
  Widget _buildTemplateInstructionBanner() {
    return Obx(() {
      final tmpl = controller.selectedTemplate.value ?? widget.targetTemplate;
      final req = widget.requiredPhotos ?? tmpl?.slotCount ?? controller.requiredPhotosCount.value;
      final selectedCount = controller.selectedAssets.length;
      final isComplete = selectedCount == req && req > 0;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isComplete
              ? const Color(0xFF16A34A).withValues(alpha: 0.18)
              : const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isComplete
                ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isComplete
                  ? Icons.check_circle_rounded
                  : Icons.photo_library_rounded,
              color: isComplete ? const Color(0xFF4ADE80) : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isComplete
                    ? "All $req photos selected!"
                    : (widget.replaceSlotIndex != null
                        ? "Select 1 photo to replace slot ${widget.replaceSlotIndex! + 1}."
                        : (tmpl != null
                            ? "Select $req photos for ${tmpl.name}."
                            : "Select $req Photos ($selectedCount/$req)")),
                style: TextStyle(
                  color: isComplete ? const Color(0xFF4ADE80) : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isComplete
                    ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$selectedCount/$req",
                style: TextStyle(
                  color: isComplete ? Colors.white : Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _openDeviceCamera() async {
    final result = await Get.to(
      () => const InAppCameraScreen(initialIsVideoMode: false),
      routeName: '/InAppCameraScreen',
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
    if (result == true && mounted) {
      Get.back(result: true);
    }
  }

  void _handleGalleryHeaderAction() {
    // Primary flow: Stay strictly inside GenLink Story Gallery.
    // Do NOT automatically launch the Android system photo picker on top of the in-app gallery.
    if (controller.hasPermission.value) {
      controller.fetchAlbumsAndMedia();
    } else {
      controller.checkAndRequestPermission();
    }
  }

  Future<void> _pickFromSystemPicker() async {
    try {
      final picker = ImagePicker();
      final req = controller.requiredPhotosCount.value;
      if (req > 1) {
        final List<XFile> files = await picker.pickMultiImage(
          imageQuality: 95,
          limit: req,
        );
        if (files.isNotEmpty && mounted) {
          final paths = files.map((f) => f.path).toList();
          if (widget.onPhotosSelected != null) {
            widget.onPhotosSelected!(paths);
            Get.back(result: paths);
          } else if (_isTemplateMode && widget.targetTemplate != null) {
            Get.back(result: paths);
          } else {
            final isSingleVideo = paths.length == 1 && _isVideoFile(paths.first);
            final result = await Get.to(
              () => StoryCreatorScreen(
                type: isSingleVideo ? StoryType.video : StoryType.photo,
                mediaPaths: paths,
              ),
              routeName: '/StoryCreatorScreen',
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
            );
            if (result == true && mounted) {
              Get.back(result: true);
            }
          }
        }
      } else {
        XFile? file;
        if (_currentFilter == StoryMediaFilter.videos) {
          file = await picker.pickVideo(source: ImageSource.gallery);
        } else if (_currentFilter == StoryMediaFilter.photos) {
          file = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 95,
          );
        } else {
          file = await picker.pickMedia(imageQuality: 95);
        }
        if (file != null && mounted) {
          final String pickedPath = file.path;
          if (widget.replaceSlotIndex != null) {
            Get.back(result: pickedPath);
          } else if (widget.onPhotosSelected != null) {
            widget.onPhotosSelected!([pickedPath]);
            Get.back(result: [pickedPath]);
          } else if (_isTemplateMode && widget.targetTemplate != null) {
            Get.back(result: [pickedPath]);
          } else {
            final isVideo = _isVideoFile(pickedPath);
            final result = await Get.to(
              () => StoryCreatorScreen(
                type: isVideo ? StoryType.video : StoryType.photo,
                mediaPaths: [pickedPath],
              ),
              routeName: '/StoryCreatorScreen',
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
            );
            if (result == true && mounted) {
              Get.back(result: true);
            }
          }
        }
      }
    } catch (_) {}
  }

  // ── 2. Top Feature Buttons Row (Text, Drafts, Archive) ──
  Widget _buildTopFeatureButtonsRow(bool isDark) {
    final textLabel = ('community.text'.tr.isNotEmpty &&
            'community.text'.tr != 'community.text')
        ? 'community.text'.tr
        : "Text";
    final draftsLabel = ('community.drafts'.tr.isNotEmpty &&
            'community.drafts'.tr != 'community.drafts')
        ? 'community.drafts'.tr
        : "Drafts";
    final archiveLabel = ('community.archive'.tr.isNotEmpty &&
            'community.archive'.tr != 'community.archive')
        ? 'community.archive'.tr
        : "Archive";

    final features = [
      (
        icon: Icons.title_rounded,
        label: textLabel,
        onTap: () async {
          final result = await Get.to(
            () => const StoryCreatorScreen(type: StoryType.text),
            routeName: '/StoryCreatorScreen',
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
          if (result == true && mounted) {
            Get.back(result: true);
          }
        },
      ),
      (
        icon: Icons.drafts_outlined,
        label: draftsLabel,
        onTap: _handleDraftsTap,
      ),
      (
        icon: Icons.archive_outlined,
        label: archiveLabel,
        onTap: _handleArchiveTap,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: features.map((f) {
          return GestureDetector(
            onTap: f.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E22)
                        : AppColors.lightSurfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.lightBorderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      f.icon,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  f.label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : AppColors.lightTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleDraftsTap() {
    if (controller.hasDraft.value) {
      _showDraftBottomSheet();
    } else {
      final noDraftsLabel = ('community.noDrafts'.tr.isNotEmpty &&
              'community.noDrafts'.tr != 'community.noDrafts')
          ? 'community.noDrafts'.tr
          : "No saved drafts";
      final draftsLabel = ('community.drafts'.tr.isNotEmpty &&
              'community.drafts'.tr != 'community.drafts')
          ? 'community.drafts'.tr
          : "Drafts";
      Get.snackbar(
        draftsLabel,
        noDraftsLabel,
        colorText: Colors.white,
        backgroundColor: const Color(0xFF222226),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        borderRadius: 14,
      );
    }
  }

  void _showDraftBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Story Draft",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You have an unfinished story draft.",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      controller.clearDraft();
                      Navigator.pop(ctx);
                    },
                    child: const Text("Discard"),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      controller.clearDraft();
                      final result = await Get.to(
                        () => const StoryCreatorScreen(type: StoryType.photo),
                        routeName: '/StoryCreatorScreen',
                        transition: Transition.fadeIn,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                      );
                      if (result == true && mounted) {
                        Get.back(result: true);
                      }
                    },
                    child: const Text(
                      "Continue",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleArchiveTap() {
    final archiveTitle = ('community.storyArchive'.tr.isNotEmpty &&
            'community.storyArchive'.tr != 'community.storyArchive')
        ? 'community.storyArchive'.tr
        : "Story Archive";
    final archiveEmpty = ('community.archiveEmpty'.tr.isNotEmpty &&
            'community.archiveEmpty'.tr != 'community.archiveEmpty')
        ? 'community.archiveEmpty'.tr
        : "Your expired stories will appear here.";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.archive_outlined, color: Colors.white70, size: 36),
            const SizedBox(height: 12),
            Text(
              archiveTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              archiveEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Main Body Content (Permissions / Gallery / Empty) ──
  Widget _buildMainContent(bool isDark) {
    return Column(
      children: [
        _buildMediaSubHeader(isDark),
        if (!_isTemplateMode) _buildFilterTabsRow(isDark),
        Expanded(
          child: Obx(() {
            if (!controller.hasPermission.value) {
              return _buildPermissionState();
            }
            if (controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  color: isDark ? Colors.white : AppColors.lightPrimary,
                  strokeWidth: 2.5,
                ),
              );
            }
            final filtered = _filteredAssets;
            if (filtered.isEmpty && _isTemplateMode) {
              return _buildEmptyGalleryState();
            }
            if (filtered.isEmpty && controller.mediaAssets.isEmpty) {
              return _buildEmptyGalleryState();
            }

            return _buildPhotoGrid(isDark, filtered);
          }),
        ),
      ],
    );
  }

  // ── 4. Camera Roll Subheader & Multi-Select Bar ──
  Widget _buildMediaSubHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Album Selector
          Flexible(
            child: GestureDetector(
              onTap: () => _showAlbumPickerSheet(context),
              behavior: HitTestBehavior.opaque,
              child: Obx(() {
                final albumName = controller.currentAlbum.value?.name;
                final recentsLabel = ('community.recents'.tr.isNotEmpty &&
                        'community.recents'.tr != 'community.recents')
                    ? 'community.recents'.tr
                    : "Recents";
                final displayName = (albumName == null ||
                        albumName.isEmpty ||
                        albumName == 'isAll')
                    ? recentsLabel
                    : albumName;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 0,
                      height: 0,
                      child: OverflowBox(
                        maxWidth: 0,
                        maxHeight: 0,
                        child: Text(
                          'Camera roll',
                          style: TextStyle(
                            fontSize: 0,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      size: 20,
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(width: 8),

          // Select Multiple / Counter Badge
          Obx(() {
            if (_isTemplateMode) {
              final count = controller.selectedAssets.length;
              final req = controller.requiredPhotosCount.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: count == req
                      ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                      : (isDark
                          ? const Color(0xFF222226)
                          : AppColors.lightSurfaceSecondary),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: count == req
                        ? const Color(0xFF4ADE80)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : AppColors.lightBorderSubtle),
                    width: 1,
                  ),
                ),
                child: Text(
                  "$count/$req selected",
                  style: TextStyle(
                    color: count == req
                        ? const Color(0xFF4ADE80)
                        : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            final isMulti = controller.isMultiSelectMode.value;
            final count = controller.selectedAssets.length;
            final multiLabel = ('community.selectMultiple'.tr.isNotEmpty &&
                    'community.selectMultiple'.tr != 'community.selectMultiple')
                ? 'community.selectMultiple'.tr
                : "Select multiple";
            final label = (isMulti && count > 0)
                ? "$count selected"
                : multiLabel;

            return GestureDetector(
              onTap: controller.toggleMultiSelectMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isMulti
                      ? (isDark ? Colors.white : AppColors.lightPrimary)
                      : (isDark
                          ? const Color(0xFF222226)
                          : AppColors.lightSurfaceSecondary),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMulti
                        ? (isDark ? Colors.white : AppColors.lightPrimary)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : AppColors.lightBorderSubtle),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isMulti
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white : AppColors.lightTextPrimary),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 5. Media Filter Tabs Row (All, Favourites, Photos, Videos) ──
  Widget _buildFilterTabsRow(bool isDark) {
    final tabs = [
      (
        filter: StoryMediaFilter.all,
        label: ('community.all'.tr.isNotEmpty &&
                'community.all'.tr != 'community.all')
            ? 'community.all'.tr
            : "All",
      ),
      (
        filter: StoryMediaFilter.favourites,
        label: ('community.favourites'.tr.isNotEmpty &&
                'community.favourites'.tr != 'community.favourites')
            ? 'community.favourites'.tr
            : "Favourites",
      ),
      (
        filter: StoryMediaFilter.photos,
        label: ('community.photos'.tr.isNotEmpty &&
                'community.photos'.tr != 'community.photos')
            ? 'community.photos'.tr
            : "Photos",
      ),
      (
        filter: StoryMediaFilter.videos,
        label: ('community.videos'.tr.isNotEmpty &&
                'community.videos'.tr != 'community.videos')
            ? 'community.videos'.tr
            : "Videos",
      ),
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab = tabs[i];
          final isSelected = _currentFilter == tab.filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentFilter = tab.filter;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.lightPrimary)
                    : (isDark
                        ? const Color(0xFF222226)
                        : AppColors.lightSurfaceSecondary),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.lightPrimary)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.lightBorderSubtle),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tab.label,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAlbumPickerSheet(BuildContext context) {
    if (controller.albums.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF18181A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "Select Album",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.albums.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (ctx, i) {
                  final album = controller.albums[i];
                  final isSelected =
                      controller.currentAlbum.value?.id == album.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    title: Text(
                      album.isAll || album.name == 'isAll' || album.name.isEmpty
                          ? "Recent"
                          : album.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      controller.selectAlbum(album);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 5. Clean Permission State ──
  Widget _buildPermissionState() {
    final isPermDenied = controller.isPermanentlyDenied.value;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isPermDenied
                    ? Icons.no_photography_outlined
                    : Icons.photo_library_outlined,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isPermDenied
                  ? "Photos access is disabled"
                  : "Photos permission needed",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isPermDenied
                  ? "Enable photo access in Settings to select photos for your Story."
                  : "Allow GenLink to access your photos so you can create a Story.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            GestureDetector(
              onTap: () {
                if (isPermDenied) {
                  controller.openSettings();
                } else {
                  controller.checkAndRequestPermission();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  isPermDenied ? "Open Settings" : "Allow Photos",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickFromSystemPicker,
              icon: const Icon(
                Icons.perm_media_outlined,
                color: Colors.white70,
                size: 18,
              ),
              label: const Text(
                "Use system photo picker",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. Clean Empty Gallery State ──
  Widget _buildEmptyGalleryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.photo_outlined,
                color: Colors.white70,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "No photos yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Take a photo with your camera or add photos to your gallery.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                GestureDetector(
                  onTap: _openDeviceCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.black,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Open Camera",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickFromSystemPicker,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text(
                    "System Picker",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 7. Clean 3-Column Photo Grid ──
  Widget _buildPhotoGrid(bool isDark, List<AssetEntity> assets) {
    final totalCount = _isTemplateMode ? assets.length : assets.length + 1;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 400) {
          controller.loadMoreMedia();
        }
        return false;
      },
      child: GridView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (!_isTemplateMode && index == 0) {
            return _buildCameraGridTile(isDark);
          }
          final assetIndex = !_isTemplateMode ? index - 1 : index;
          final asset = assets[assetIndex];
          return _buildAssetItem(asset);
        },
      ),
    );
  }

  Widget _buildCameraGridTile(bool isDark) {
    final cameraLabel = ('community.camera'.tr.isNotEmpty &&
            'community.camera'.tr != 'community.camera')
        ? 'community.camera'.tr
        : "Camera";

    return GestureDetector(
      onTap: _openDeviceCamera,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E22)
              : AppColors.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              cameraLabel,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _loadThumbnail(AssetEntity asset) async {
    if (Get.testMode) return null;
    try {
      return await asset.thumbnailDataWithSize(
        const ThumbnailSize.square(250),
        quality: 85,
      );
    } catch (_) {
      try {
        final f = await asset.file;
        if (f != null) {
          return await f.readAsBytes();
        }
      } catch (_) {}
      return null;
    }
  }

  Widget _buildAssetThumbnail(AssetEntity asset) {
    final cached = _thumbCache[asset.id];
    if (cached != null) {
      return Image.memory(
        cached,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return FutureBuilder<Uint8List?>(
      future: _loadThumbnail(asset),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _thumbCache[asset.id] = snapshot.data!;
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }
        return Container(color: const Color(0xFF1E1E22));
      },
    );
  }

  Widget _buildAssetItem(AssetEntity asset) {
    return Obx(() {
      final isSelected = controller.selectedAssets.contains(asset);
      final selectionIndex = controller.getSelectionIndex(asset);
      final isMulti = controller.isMultiSelectMode.value;

      return GestureDetector(
        onTap: () => _handleAssetTap(asset),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            _buildAssetThumbnail(asset),

            // Selection Outline Overlay
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2.5),
                  color: Colors.black.withValues(alpha: 0.28),
                ),
              ),

            // Video Duration / Camera Badge
            if (asset.type == AssetType.video)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      if (asset.videoDuration.inSeconds > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          _formatDuration(asset.videoDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Numbered / Checkmark Selection Badge
            Positioned(
              top: 6,
              right: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : Colors.black38,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white70,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isSelected
                      ? (isMulti
                            ? Text(
                                selectionIndex.toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                                color: Colors.black,
                                size: 16,
                              ))
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool _isVideoFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.m4v') ||
        p.endsWith('.webm') ||
        p.endsWith('.avi') ||
        p.endsWith('.mkv') ||
        p.endsWith('.flv');
  }

  // ── 8. Draft Overlay Card ──
  Widget _buildDraftOverlay() {
    return Obx(() {
      if (!controller.hasDraft.value) return const SizedBox.shrink();

      return Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Continue editing draft?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your story has an unfinished draft.",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      controller.discardDraftAndContinue();
                    },
                    child: const Text(
                      "Delete draft",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () async {
                      controller.clearDraft();
                      final result = await Get.to(
                        () => const StoryCreatorScreen(type: StoryType.photo),
                        routeName: '/StoryCreatorScreen',
                        transition: Transition.fadeIn,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                      );
                      if (result == true && mounted) {
                        Get.back(result: true);
                      }
                    },
                    child: const Text(
                      "Continue",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _handleAssetTap(AssetEntity asset) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      if (widget.replaceSlotIndex != null) {
        final file = (await asset.file) ?? (await asset.originFile);
        if (file != null && mounted) {
          Get.back(result: file.path);
        }
        return;
      }

      // If multi-select mode is active (whether from story flow or post composer gallery)
      if (controller.isMultiSelectMode.value) {
        controller.selectAsset(asset);
        return;
      }

      if (widget.onPhotosSelected != null) {
        final file = (await asset.file) ?? (await asset.originFile);
        if (file != null && mounted) {
          widget.onPhotosSelected!([file.path]);
          Get.back(result: [file.path]);
        }
        return;
      }

      if (_isTemplateMode) {
        controller.selectAsset(asset);
        final tmpl = controller.selectedTemplate.value ?? widget.targetTemplate;
        final req = widget.requiredPhotos ?? tmpl?.slotCount ?? controller.requiredPhotosCount.value;
        if (req > 0 && controller.selectedAssets.length == req) {
          final List<String> paths = [];
          for (var a in controller.selectedAssets) {
            final f = (await a.file) ?? (await a.originFile);
            if (f != null) paths.add(f.path);
          }
          if (paths.length == req && mounted) {
            if (widget.targetTemplate != null) {
              Get.back(result: paths);
              return;
            }
            final result = await Get.to(
              () => StoryCreatorScreen(
                type: StoryType.template,
                templateId: tmpl?.id,
                mediaPaths: paths,
              ),
              routeName: '/StoryCreatorScreen',
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
            );
            if (result == true && mounted) {
              Get.back(result: true);
            }
          }
        }
        return;
      }

      // Single photo/video selection -> open Story Creator directly
      final file = (await asset.file) ?? (await asset.originFile);
      if (file != null && mounted) {
        final bool isVideo = asset.type == AssetType.video || _isVideoFile(file.path);
        final result = await Get.to(
          () => StoryCreatorScreen(
            type: isVideo ? StoryType.video : StoryType.photo,
            mediaPaths: [file.path],
          ),
          routeName: '/StoryCreatorScreen',
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
        if (result == true && mounted) {
          Get.back(result: true);
        }
      }
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }

  // ── 9. Multi-Select Bottom Bar & Submission ──
  Widget _buildMultiSelectBottomBar() {
    return Obx(() {
      final isMulti = controller.isMultiSelectMode.value;
      final selected = controller.selectedAssets;
      if (!isMulti || selected.isEmpty) {
        return const SizedBox.shrink();
      }

      final count = selected.length;
      return Positioned(
        left: 16,
        right: 16,
        bottom: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$count photo${count > 1 ? 's' : ''} selected",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                onPressed: _proceedWithMultiSelection,
                child: const Text(
                  "Next",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _proceedWithMultiSelection() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final List<String> paths = [];
      for (final a in controller.selectedAssets) {
        final f = (await a.file) ?? (await a.originFile);
        if (f != null) {
          paths.add(f.path);
        }
      }
      if (paths.isNotEmpty && mounted) {
        if (widget.onPhotosSelected != null) {
          widget.onPhotosSelected!(paths);
          Get.back(result: paths);
          return;
        }
        final bool isSingleVideo = paths.length == 1 &&
            (controller.selectedAssets.first.type == AssetType.video ||
                _isVideoFile(paths.first));
        final result = await Get.to(
          () => StoryCreatorScreen(
            type: isSingleVideo ? StoryType.video : StoryType.photo,
            mediaPaths: paths,
          ),
          routeName: '/StoryCreatorScreen',
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
        if (result == true && mounted) {
          Get.back(result: true);
        }
      }
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }
}
