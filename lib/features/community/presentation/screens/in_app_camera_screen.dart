import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/story_model.dart';
import '../controllers/story_gallery_controller.dart';
import 'story_creator_screen.dart';
import 'story_gallery_screen.dart';

class InAppCameraScreen extends StatefulWidget {
  final bool initialIsVideoMode;

  const InAppCameraScreen({super.key, this.initialIsVideoMode = false});

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen>
    with WidgetsBindingObserver {
  late bool _isVideoMode;
  FlashMode _flashMode = FlashMode.auto;
  bool _isCapturing = false;
  bool _isRecording = false;

  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isInitializing = false;
  bool _permissionDenied = false;
  bool _isPermissionPermanentlyDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isVideoMode = widget.initialIsVideoMode;
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      debugPrint('[StoryCamera] App inactive - disposing CameraController');
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[StoryCamera] App resumed - reinitializing CameraController');
      _initCamera(cameraIndex: _selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera({int? cameraIndex}) async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _permissionDenied = false;
      _isPermissionPermanentlyDenied = false;
    });

    debugPrint('[StoryCamera] Starting initialization');

    try {
      debugPrint('[StoryCamera] Checking permission');
      final permissionStatus = await Permission.camera.status;
      debugPrint('[StoryCamera] Permission result: $permissionStatus');

      if (!permissionStatus.isGranted) {
        final requested = await Permission.camera.request();
        debugPrint('[StoryCamera] Permission request result: $requested');
        if (!requested.isGranted) {
          debugPrint('[StoryCamera] INITIALIZATION FAILED');
          debugPrint('[StoryCamera] Exception type: PermissionDeniedException');
          debugPrint(
            '[StoryCamera] Error message: Camera permission denied ($requested)',
          );
          if (mounted) {
            setState(() {
              _isInitializing = false;
              _isCameraInitialized = false;
              _permissionDenied = true;
              _isPermissionPermanentlyDenied = requested.isPermanentlyDenied;
              _errorMessage = requested.isPermanentlyDenied
                  ? "Camera permission is permanently denied. Please enable camera access in system settings."
                  : "Camera permission is required to capture photos and videos for your Story.";
            });
          }
          return;
        }
      }

      debugPrint('[StoryCamera] Loading available cameras');
      _cameras = await availableCameras();
      debugPrint('[StoryCamera] Cameras found: ${_cameras.length}');

      if (_cameras.isEmpty) {
        debugPrint('[StoryCamera] INITIALIZATION FAILED');
        debugPrint('[StoryCamera] Exception type: CameraNotFoundException');
        debugPrint(
          '[StoryCamera] Error message: No available cameras found on this device',
        );
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _isCameraInitialized = false;
            _errorMessage = "No camera hardware was detected on this device.";
          });
        }
        return;
      }

      if (cameraIndex != null &&
          cameraIndex >= 0 &&
          cameraIndex < _cameras.length) {
        _selectedCameraIndex = cameraIndex;
      } else if (_selectedCameraIndex >= _cameras.length) {
        _selectedCameraIndex = 0;
      }

      final selectedCamera = _cameras[_selectedCameraIndex];
      debugPrint(
        '[StoryCamera] Creating CameraController for ${selectedCamera.name} (${selectedCamera.lensDirection})',
      );

      final oldController = _cameraController;
      _cameraController = null;
      await oldController?.dispose();

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;

      debugPrint('[StoryCamera] Initializing CameraController');
      await controller.initialize();
      debugPrint('[StoryCamera] Camera initialized successfully');

      try {
        await controller.setFlashMode(_flashMode);
      } catch (_) {
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isInitializing = false;
        });
      }
    } on CameraException catch (e, stack) {
      debugPrint('[StoryCamera] INITIALIZATION FAILED');
      debugPrint('[StoryCamera] Exception type: CameraException (${e.code})');
      debugPrint(
        '[StoryCamera] Error message: ${e.description ?? e.toString()}',
      );
      debugPrint('$stack');
      if (mounted) {
        final isDenied =
            e.code == 'CameraAccessDenied' ||
            e.code == 'CameraAccessDeniedWithoutPrompt';
        setState(() {
          _isCameraInitialized = false;
          _isInitializing = false;
          _permissionDenied = isDenied;
          _errorMessage = isDenied
              ? "Camera permission denied."
              : "Camera initialization failed: ${e.description ?? e.code}";
        });
      }
    } catch (e, stack) {
      debugPrint('[StoryCamera] INITIALIZATION FAILED');
      debugPrint('[StoryCamera] Exception type: ${e.runtimeType}');
      debugPrint('[StoryCamera] Error message: $e');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isInitializing = false;
          _errorMessage = "Could not initialize camera: $e";
        });
      }
    }
  }

  Future<void> _toggleCameraLens() async {
    if (_cameras.length < 2 ||
        _isInitializing ||
        _isCapturing ||
        _isRecording) {
      return;
    }

    final currentDirection = _cameras[_selectedCameraIndex].lensDirection;
    int nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection != currentDirection) {
        nextIndex = i;
        break;
      }
    }

    await _initCamera(cameraIndex: nextIndex);
  }

  Future<void> _cycleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    FlashMode nextMode;
    if (_flashMode == FlashMode.auto) {
      nextMode = FlashMode.always;
    } else if (_flashMode == FlashMode.always) {
      nextMode = FlashMode.off;
    } else {
      nextMode = FlashMode.auto;
    }

    try {
      await controller.setFlashMode(nextMode);
      if (mounted) {
        setState(() {
          _flashMode = nextMode;
        });
      }
    } catch (e) {
      debugPrint('[StoryCamera] Failed to set flash mode: $e');
    }
  }

  void _startTimer() {
    _recordingSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_recordingSeconds >= 60) {
        t.cancel();
        if (_isRecording) {
          await _captureMedia();
        }
      } else {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
          });
        }
      }
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
  }

  Future<void> _captureMedia() async {
    if (_isCapturing) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      debugPrint(
        '[StoryCamera] Capture requested while camera is not initialized',
      );
      return;
    }

    if (_isVideoMode) {
      if (_isRecording) {
        _stopTimer();
        setState(() => _isCapturing = true);
        try {
          final XFile videoFile = await controller.stopVideoRecording();
          final durationSec = _recordingSeconds;
          _stopTimer();

          // Ensure the recorded .mp4 file is flushed and accessible before navigating
          final file = File(videoFile.path);
          int retries = 0;
          while (retries < 20) {
            try {
              if (file.existsSync() && file.lengthSync() > 0) {
                break;
              }
            } catch (_) {}
            await Future.delayed(const Duration(milliseconds: 50));
            retries++;
          }

          final exists = file.existsSync();
          final size = exists ? file.lengthSync() : 0;
          final ext = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : '';
          debugPrint(
            '[StoryCamera] Video recording stopped and verified:\n'
            '  - Path: ${file.path}\n'
            '  - Exists: $exists\n'
            '  - Size: $size bytes\n'
            '  - Extension: .$ext\n'
            '  - MIME Type: video/mp4\n'
            '  - Duration: ${durationSec}s',
          );

          if (mounted) {
            setState(() {
              _isRecording = false;
              _isCapturing = false;
            });
            final result = await Get.to(
              () => StoryCreatorScreen(
                type: StoryType.video,
                mediaPaths: [videoFile.path],
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
        } catch (e, stack) {
          _stopTimer();
          debugPrint('[StoryCamera] Stop video recording failed: $e\n$stack');
          if (mounted) {
            setState(() {
              _isRecording = false;
              _isCapturing = false;
            });
            AppNotificationBanner.showDanger(
              context: context,
              title: "Recording Failed",
              message: e.toString(),
            );
          }
        }
      } else {
        final micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          if (mounted) {
            AppNotificationBanner.showWarning(
              context: context,
              title: "Microphone Access",
              message:
                  "Microphone permission is required to record video stories.",
            );
          }
          return;
        }

        try {
          await controller.startVideoRecording();
          debugPrint('[StoryCamera] Video recording started');
          _startTimer();
          if (mounted) {
            setState(() {
              _isRecording = true;
            });
          }
        } catch (e, stack) {
          _stopTimer();
          debugPrint('[StoryCamera] Start video recording failed: $e\n$stack');
          if (mounted) {
            setState(() {
              _isRecording = false;
              _isCapturing = false;
            });
            AppNotificationBanner.showDanger(
              context: context,
              title: "Recording Failed",
              message: e.toString(),
            );
          }
        }
      }
    } else {
      setState(() => _isCapturing = true);
      try {
        final XFile photo = await controller.takePicture();
        debugPrint('[StoryCamera] Photo captured, path: ${photo.path}');
        if (mounted) {
          final result = await Get.to(
            () => StoryCreatorScreen(
              type: StoryType.photo,
              mediaPaths: [photo.path],
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
      } catch (e, stack) {
        debugPrint('[StoryCamera] Photo capture failed: $e\n$stack');
        if (mounted) {
          AppNotificationBanner.showDanger(
            context: context,
            title: "Capture Failed",
            message: e.toString(),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCapturing = false);
        }
      }
    }
  }

  Future<void> _openGallery() async {
    if (_isCapturing || _isRecording) return;

    if (Get.previousRoute == '/StoryGalleryScreen') {
      Get.back();
      return;
    }

    try {
      final galleryCtrl = Get.isRegistered<StoryGalleryController>()
          ? Get.find<StoryGalleryController>()
          : Get.put(StoryGalleryController());
      galleryCtrl.configureForTemplate(
        template: null,
        requiredPhotos: 0,
        maxSelection: 0,
        isMultiSelect: false,
        clearSelection: true,
      );

      final result = await Get.to(
        () => const StoryGalleryScreen(),
        routeName: '/StoryGalleryScreen',
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      if (result == true && mounted) {
        Get.back(result: true);
      }
    } catch (e) {
      debugPrint('[StoryCamera] In-app gallery error, falling back to system picker: $e');
      _openSystemPickerFallback();
    }
  }

  Future<void> _openSystemPickerFallback() async {
    final picker = ImagePicker();
    try {
      final XFile? media = _isVideoMode
          ? await picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: const Duration(seconds: 60),
            )
          : await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 95,
            );

      if (media != null && mounted) {
        final result = await Get.to(
          () => StoryCreatorScreen(
            type: _isVideoMode ? StoryType.video : StoryType.photo,
            mediaPaths: [media.path],
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
    } catch (e) {
      debugPrint('[StoryCamera] System picker fallback error: $e');
    }
  }

  String _formatRecordingTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s / 01:00';
  }

  Widget _buildCameraViewport() {
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          final double screenHeight = constraints.maxHeight;
          final double screenRatio = screenWidth / screenHeight;

          final double rawRatio = _cameraController!.value.aspectRatio;
          final bool isPortrait =
              MediaQuery.of(context).orientation == Orientation.portrait;
          final double previewRatio =
              isPortrait ? (1 / rawRatio) : rawRatio;

          double previewWidth;
          double previewHeight;

          if (screenRatio > previewRatio) {
            previewWidth = screenWidth;
            previewHeight = screenWidth / previewRatio;
          } else {
            previewHeight = screenHeight;
            previewWidth = screenHeight * previewRatio;
          }

          return ClipRect(
            child: Center(
              child: SizedBox(
                width: previewWidth,
                height: previewHeight,
                child: CameraPreview(_cameraController!),
              ),
            ),
          );
        },
      );
    }

    if (_isInitializing) {
      return Container(
        color: const Color(0xFF111111),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.communityAccent,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                "Initializing camera...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _permissionDenied
                    ? Icons.no_photography_rounded
                    : Icons.camera_alt_outlined,
                color: _permissionDenied
                    ? AppColors.danger
                    : AppColors.communityAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _permissionDenied
                    ? 'community.cameraPermissionTitle'.tr
                    : 'community.cameraUnavailableTitle'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ??
                    (_permissionDenied
                        ? 'community.cameraPermissionMessage'.tr
                        : 'community.cameraUnavailableMessage'.tr),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (_permissionDenied) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_isPermissionPermanentlyDenied) {
                      await openAppSettings();
                    } else {
                      await _initCamera();
                    }
                  },
                  icon: Icon(
                    _isPermissionPermanentlyDenied
                        ? Icons.settings_rounded
                        : Icons.lock_open_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _isPermissionPermanentlyDenied
                        ? "Open App Settings"
                        : "Grant Permission",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.communityAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => _initCamera(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.communityAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _openGallery,
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: Text('community.gallery'.tr),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildCameraViewport(),
          ),

          if (_isVideoMode && _isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatRecordingTime(_recordingSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _flashMode == FlashMode.always
                                ? Icons.flash_on_rounded
                                : (_flashMode == FlashMode.auto
                                    ? Icons.flash_auto_rounded
                                    : Icons.flash_off_rounded),
                            color: _flashMode != FlashMode.off
                                ? Colors.yellowAccent
                                : Colors.white70,
                            size: 26,
                          ),
                          onPressed: _cycleFlash,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: _toggleCameraLens,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

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
                            onTap: _isRecording
                                ? null
                                : () => setState(() => _isVideoMode = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: !_isVideoMode
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'community.photo'.tr,
                                style: TextStyle(
                                  color: !_isVideoMode
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _isRecording
                                ? null
                                : () => setState(() => _isVideoMode = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _isVideoMode
                                    ? AppColors.danger
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'community.video'.tr,
                                style: TextStyle(
                                  color: _isVideoMode
                                      ? Colors.white
                                      : Colors.white70,
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: (_isCapturing || _isRecording)
                              ? null
                              : _openGallery,
                          icon: const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            'community.gallery'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(color: Colors.white12),
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: _isCapturing ? null : _captureMedia,
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
                                color: (_isVideoMode || _isRecording)
                                    ? AppColors.danger
                                    : Colors.white,
                              ),
                              child: _isCapturing
                                  ? Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          color: (_isVideoMode || _isRecording)
                                              ? Colors.white
                                              : Colors.black,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : _isRecording
                                      ? Center(
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        )
                                      : null,
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.flip_camera_android_rounded,
                            color: Colors.white70,
                            size: 26,
                          ),
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
