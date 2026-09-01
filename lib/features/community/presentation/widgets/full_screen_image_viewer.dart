import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../design_system/colors/app_colors.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTagPrefix;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTagPrefix = 'post_img',
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformationControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _getTransformationController(int index) {
    if (!_transformationControllers.containsKey(index)) {
      _transformationControllers[index] = TransformationController();
    }
    return _transformationControllers[index]!;
  }

  void _handleDoubleTap(int index) {
    final controller = _getTransformationController(index);
    if (controller.value != Matrix4.identity()) {
      controller.value = Matrix4.identity();
    } else {
      controller.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
    }
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.contain, alignment: Alignment.center);
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.communityAccent,
                strokeWidth: 2.5,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: Colors.white38,
            size: 64,
          ),
        ),
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 250) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            // Full Screen Image PageView with Pinch Zoom & Double Tap
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemBuilder: (context, index) {
                final imagePath = widget.images[index];
                final heroTag = '${widget.heroTagPrefix}_$index';
                final transformController = _getTransformationController(index);

                return GestureDetector(
                  onDoubleTap: () => _handleDoubleTap(index),
                  child: Center(
                    child: Hero(
                      tag: heroTag,
                      child: InteractiveViewer(
                        transformationController: transformController,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: _buildImageWidget(imagePath),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top Control Bar: Close (✕) Button & Counter Indicator
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),

                    // Page Indicator Badge (e.g., "2 / 5")
                    if (widget.images.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Text(
                          "${_currentIndex + 1} / ${widget.images.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
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
}
