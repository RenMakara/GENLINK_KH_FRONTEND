import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import '../controllers/story_gallery_controller.dart';
import 'in_app_camera_screen.dart';
import 'story_creator_screen.dart';
import '../../domain/models/story_model.dart';

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

  bool get _isTemplateMode =>
      widget.targetTemplate != null ||
      (widget.requiredPhotos != null && widget.requiredPhotos! > 0) ||
      controller.selectedTemplate.value != null ||
      controller.requiredPhotosCount.value > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isTemplateMode) _buildCreationModesRow(),
            if (_isTemplateMode) _buildTemplateInstructionBanner(),
            Expanded(
              child: Stack(
                children: [_buildMainContent(), _buildDraftOverlay()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Top Header ──
  Widget _buildHeader() {
    return Obx(() {
      final tmpl = controller.selectedTemplate.value ?? widget.targetTemplate;
      String headerTitle = "Create Story";
      if (widget.replaceSlotIndex != null) {
        headerTitle = "Replace Slot ${widget.replaceSlotIndex! + 1}";
      } else if (tmpl != null) {
        headerTitle = tmpl.name;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: "Close",
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                controller.saveDraft();
                Get.back();
              },
            ),
            Expanded(
              child: Text(
                headerTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Camera",
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _openDeviceCamera,
                ),
                IconButton(
                  tooltip: "System Gallery",
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _pickFromSystemPicker,
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
                        : "Select $req Photos ($selectedCount/$req)"),
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
            final result = await Get.to(
              () => StoryCreatorScreen(
                type: StoryType.photo,
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
        final XFile? file = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 95,
        );
        if (file != null && mounted) {
          if (widget.replaceSlotIndex != null) {
            Get.back(result: file.path);
          } else if (widget.onPhotosSelected != null) {
            widget.onPhotosSelected!([file.path]);
            Get.back(result: [file.path]);
          } else if (_isTemplateMode && widget.targetTemplate != null) {
            Get.back(result: [file.path]);
          } else {
            final result = await Get.to(
              () => StoryCreatorScreen(
                type: StoryType.photo,
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
        }
      }
    } catch (_) {}
  }

  // ── 2. Creation Mode Row ──
  Widget _buildCreationModesRow() {
    final modes = [
      (
        icon: Icons.text_fields_rounded,
        label: "Text",
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
        icon: Icons.music_note_rounded,
        label: "Music",
        onTap: () => _showComingSoon("Music Story"),
      ),
      (
        icon: Icons.all_inclusive_rounded,
        label: "Boomerang",
        onTap: () => _showComingSoon("Boomerang"),
      ),
    ];

    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: modes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final mode = modes[i];
          return GestureDetector(
            onTap: mode.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(mode.icon, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mode.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      "Coming Soon",
      "$feature is currently under development.",
      colorText: Colors.white,
      backgroundColor: const Color(0xFF222226),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      borderRadius: 14,
    );
  }

  // ── 3. Main Body Content (Permissions / Gallery / Empty) ──
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildMediaSubHeader(),
        Expanded(
          child: Obx(() {
            if (!controller.hasPermission.value) {
              return _buildPermissionState();
            }
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              );
            }
            if (controller.mediaAssets.isEmpty) {
              return _buildEmptyGalleryState();
            }

            return _buildPhotoGrid();
          }),
        ),
      ],
    );
  }

  // ── 4. Camera Roll Subheader & Multi-Select Bar ──
  Widget _buildMediaSubHeader() {
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
                final displayName = (albumName == null || albumName.isEmpty)
                    ? "Camera roll"
                    : albumName;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
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
                      : const Color(0xFF222226),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: count == req
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  "$count/$req selected",
                  style: TextStyle(
                    color: count == req
                        ? const Color(0xFF4ADE80)
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            final isMulti = controller.isMultiSelectMode.value;
            final count = controller.selectedAssets.length;
            final label = (isMulti && count > 0)
                ? "$count selected"
                : "Select multiple";

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
                  color: isMulti ? Colors.white : const Color(0xFF222226),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMulti
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isMulti ? Colors.black : Colors.white,
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
                      album.name.isEmpty ? "All Photos" : album.name,
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
            GestureDetector(
              onTap: _openDeviceCamera,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
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
          ],
        ),
      ),
    );
  }

  // ── 7. Clean 3-Column Photo Grid ──
  Widget _buildPhotoGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: controller.mediaAssets.length,
      itemBuilder: (context, index) {
        final asset = controller.mediaAssets[index];
        return _buildAssetItem(asset);
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
            FutureBuilder<File?>(
              future: asset.file,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(snapshot.data!, fit: BoxFit.cover);
                }
                return Container(color: const Color(0xFF1E1E22));
              },
            ),

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
    if (widget.replaceSlotIndex != null) {
      final file = await asset.file;
      if (file != null && mounted) {
        Get.back(result: file.path);
      }
      return;
    }

    if (widget.onPhotosSelected != null) {
      final file = await asset.file;
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
          final f = await a.file;
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
    final file = await asset.file;
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
  }
}
