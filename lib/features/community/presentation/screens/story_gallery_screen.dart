import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../controllers/story_gallery_controller.dart';
import 'story_creator_screen.dart';
import 'in_app_camera_screen.dart';
import '../../domain/models/story_model.dart';

class StoryGalleryScreen extends StatefulWidget {
  const StoryGalleryScreen({super.key});

  @override
  State<StoryGalleryScreen> createState() => _StoryGalleryScreenState();
}

class _StoryGalleryScreenState extends State<StoryGalleryScreen> {
  final StoryGalleryController controller = Get.put(StoryGalleryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildToolOptions(),
            Expanded(
              child: Stack(
                children: [
                  _buildGalleryGrid(),
                  _buildDraftOverlay(),
                ],
              ),
            ),
            _buildBottomActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () {
              controller.saveDraft();
              Get.back();
            },
          ),
          const Text(
            "Create Story",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                onPressed: () {
                  Get.to(() => const InAppCameraScreen(initialIsVideoMode: false));
                },
              ),
              IconButton(
                icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                onPressed: () {
                  // Already in gallery, but maybe they want the native picker? 
                  // As per requirements, we stay here.
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolOptions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildToolItem(Icons.text_fields_rounded, "Text", () {
            Get.to(() => const StoryCreatorScreen(type: StoryType.text));
          }),
          _buildToolItem(Icons.music_note_rounded, "Music", () {
            _showComingSoon();
          }),
          _buildToolItem(Icons.all_inclusive_rounded, "Boomerang", () {
            _showComingSoon();
          }),
          _buildToolItem(Icons.copy_rounded, "Template", () {
            _showComingSoon();
          }),
        ],
      ),
    );
  }

  Widget _buildToolItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }

  void _showComingSoon() {
    Get.snackbar(
      "Coming soon",
      "This feature is currently under development.",
      colorText: Colors.white,
      backgroundColor: const Color(0xFF242424),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  Widget _buildGalleryGrid() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text("Camera roll", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Select multiple", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (!controller.hasPermission.value) {
              return const Center(child: Text("Permission required to access photos.", style: TextStyle(color: Colors.white54)));
            }
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (controller.mediaAssets.isEmpty) {
              return const Center(child: Text("No photos found.", style: TextStyle(color: Colors.white54)));
            }

            return GridView.builder(
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
          }),
        ),
      ],
    );
  }

  Widget _buildAssetItem(AssetEntity asset) {
    return Obx(() {
      final isSelected = controller.selectedAssets.contains(asset);
      final selectionIndex = controller.getSelectionIndex(asset);

      return GestureDetector(
        onTap: () => controller.toggleSelection(asset),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<File?>(
              future: asset.file,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(color: const Color(0xFF1E1E1E));
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  );
                }
                return Container(color: const Color(0xFF1E1E1E));
              },
            ),
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFFF4F9A) : Colors.black26,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: isSelected
                      ? Text(
                          selectionIndex.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

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
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF333333)),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Continue editing draft?",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                    child: const Text("Delete draft", style: TextStyle(color: Colors.redAccent)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      // Navigate to editor with draft
                      controller.clearDraft();
                      Get.to(() => const StoryCreatorScreen(type: StoryType.photo));
                    },
                    child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBottomActionArea() {
    return Obx(() {
      final hasSelection = controller.selectedAssets.isNotEmpty;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Color(0xFF242424))),
        ),
        child: SafeArea(
          top: false,
          child: InkWell(
            onTap: hasSelection
                ? () async {
                    // Navigate to existing Story Editor
                    final List<String> paths = [];
                    for (var asset in controller.selectedAssets) {
                      final file = await asset.file;
                      if (file != null) {
                        paths.add(file.path);
                      }
                    }
                    if (paths.isNotEmpty) {
                      Get.to(() => StoryCreatorScreen(
                        type: StoryType.photo,
                        mediaPaths: paths,
                      ));
                    }
                  }
                : null,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                color: hasSelection ? Colors.white : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Center(
                child: Text(
                  "Next   →",
                  style: TextStyle(
                    color: hasSelection ? Colors.black : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
