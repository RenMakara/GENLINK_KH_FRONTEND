import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/story_model.dart';
import '../controllers/story_controller.dart';
import 'story_creator_screen.dart';

enum FlashMode { off, on, auto }

class InAppCameraScreen extends StatefulWidget {
  final bool initialIsVideoMode;

  const InAppCameraScreen({
    super.key,
    this.initialIsVideoMode = false,
  });

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen> {
  late bool _isVideoMode;
  bool _isFrontCamera = false;
  FlashMode _flashMode = FlashMode.auto;
  bool _isCapturing = false;

  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _isVideoMode = widget.initialIsVideoMode;
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _toggleCameraLens() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  void _cycleFlash() {
    setState(() {
      if (_flashMode == FlashMode.auto) {
        _flashMode = FlashMode.on;
      } else if (_flashMode == FlashMode.on) {
        _flashMode = FlashMode.off;
      } else {
        _flashMode = FlashMode.auto;
      }
    });
  }

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  void _startTimer() {
    _recordingSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_recordingSeconds >= 60) {
        t.cancel();
      } else {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
  }

  Future<void> _captureMedia({bool instantPost = false}) async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    if (_isVideoMode) {
      _startTimer();
    }

    final picker = ImagePicker();
    XFile? media;

    try {
      if (_isDesktopPlatform) {
        media = _isVideoMode
            ? await picker.pickVideo(
                source: ImageSource.gallery,
                maxDuration: const Duration(seconds: 60),
              )
            : await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
      } else {
        media = _isVideoMode
            ? await picker.pickVideo(
                source: ImageSource.camera,
                maxDuration: const Duration(seconds: 60),
              )
            : await picker.pickImage(source: ImageSource.camera, imageQuality: 95);
      }

      _stopTimer();

      if (media != null && mounted) {
        if (instantPost) {
          final controller = Get.find<StoryController>();
          final success = await controller.publishStory(
            type: _isVideoMode ? StoryType.video : StoryType.photo,
            mediaUrl: media.path,
            textContent: "CampusLink KH Story",
            visibility: "Public",
          );

          if (mounted) {
            Get.back();
            if (success) {
              AppNotificationBanner.showSuccess(
                context: context,
                title: "✓ Story Posted",
                message: "Your story is live on CampusLink KH!",
                icon: Icons.camera_alt_rounded,
              );
            }
          }
        } else {
          Get.to(
            () => StoryCreatorScreen(
              type: _isVideoMode ? StoryType.video : StoryType.photo,
              mediaPath: media!.path,
            ),
          );
        }
      } else {
        setState(() => _isCapturing = false);
      }
    } catch (e) {
      _stopTimer();
      try {
        media = _isVideoMode
            ? await picker.pickVideo(
                source: ImageSource.gallery,
                maxDuration: const Duration(seconds: 60),
              )
            : await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);

        if (media != null && mounted) {
          Get.to(
            () => StoryCreatorScreen(
              type: _isVideoMode ? StoryType.video : StoryType.photo,
              mediaPath: media!.path,
            ),
          );
        } else {
          setState(() => _isCapturing = false);
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isCapturing = false);
          AppNotificationBanner.showDanger(
            context: context,
            title: "Selection Cancelled",
            message: "No media file selected for story creation.",
          );
        }
      }
    }
  }

  String _formatRecordingTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s / 01:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Camera Viewport Preview Area
          Positioned.fill(
            child: Container(
              color: const Color(0xFF111111),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFrontCamera ? Icons.person_pin_rounded : Icons.photo_camera_rounded,
                        color: AppColors.communityAccent,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Create Story",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          "Capture a photo or choose one from your gallery.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (_isVideoMode && _isCapturing) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                _formatRecordingTime(_recordingSeconds),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top Controls Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Get.back(),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _flashMode == FlashMode.on
                                ? Icons.flash_on_rounded
                                : (_flashMode == FlashMode.auto ? Icons.flash_auto_rounded : Icons.flash_off_rounded),
                            color: _flashMode != FlashMode.off ? Colors.yellowAccent : Colors.white70,
                            size: 26,
                          ),
                          onPressed: _cycleFlash,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 26),
                          onPressed: _toggleCameraLens,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Shutter Bar with Quick Actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Mode Switcher ([ Photo ]  [ Video ])
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isVideoMode = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isVideoMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'community.photo'.tr,
                                style: TextStyle(
                                  color: !_isVideoMode ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _isVideoMode = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isVideoMode ? AppColors.danger : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'community.video'.tr,
                                style: TextStyle(
                                  color: _isVideoMode ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Shutter Row (Gallery Option & Shutter Button)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Action Button
                        TextButton.icon(
                          onPressed: _isCapturing ? null : () => _captureMedia(instantPost: true),
                          icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
                          label: Text('community.gallery'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(color: Colors.white12),
                            ),
                          ),
                        ),

                        // Main Capture Shutter Button
                        GestureDetector(
                          onTap: () => _captureMedia(instantPost: false),
                          child: Container(
                            width: 78,
                            height: 78,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isVideoMode ? AppColors.danger : Colors.white,
                              ),
                              child: _isCapturing
                                  ? Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          color: _isVideoMode ? Colors.white : Colors.black,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),

                        // Flip Camera Lens Action Button
                        IconButton(
                          icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white70, size: 26),
                          onPressed: _toggleCameraLens,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
