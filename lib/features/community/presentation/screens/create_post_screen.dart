import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../shared/utils/current_user.dart';
import '../../../../shared/widgets/global_create_sheet.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import '../../../media/presentation/media_picker.dart';

class CreatePostScreen extends StatefulWidget {
  final CommunityPostModel? initialPost;
  final MediaPicker? mediaPicker;

  const CreatePostScreen({super.key, this.initialPost, this.mediaPicker});

  @override
  State<CreatePostScreen> createState() => CreatePostScreenState();
}

class CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  String _selectedAudience = 'Public';
  List<String> _attachedImages = [];
  // ─── Step 3B-Frontend: Video state ────────────────────────────────────────
  String? _attachedVideo;          // local file path of the selected video
  VideoPlayerController? _previewVideoController; // preview controller
  bool _videoInitialized = false;  // controller ready to render
  bool _videoInitError = false;    // init failed (bad codec, corrupt, etc.)
  // ──────────────────────────────────────────────────────────────────────────

  String? _selectedLocation;
  EventModel? _attachedEvent;
  String? _selectedFeeling;
  final List<String> _taggedPeople = [];

  String? _pollQuestion;
  List<String> _pollOptionsList = [];
  final String _pollDuration = '3 Days';

  String? _attachedLink;
  String? _linkTitle;
  String? _linkDomain;

  bool _isSubmitting = false;
  final int _maxCharacters = 2000;

  bool get _isEditing => widget.initialPost != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _textController.text = widget.initialPost!.content;
      _attachedImages = List.from(widget.initialPost!.imageUrls);
      _selectedAudience = widget.initialPost!.visibility;
      _selectedLocation = widget.initialPost!.location;
      _attachedLink = widget.initialPost!.linkUrl;
      _linkTitle = widget.initialPost!.linkPreviewTitle;
      _linkDomain = widget.initialPost!.linkPreviewDomain;
      _pollQuestion = widget.initialPost!.pollQuestion;
      if (widget.initialPost!.pollOptions != null) {
        _pollOptionsList = widget.initialPost!.pollOptions!.map((o) => o.text).toList();
      }
      if (widget.initialPost!.attachedEvent != null) {
        _attachedEvent = widget.initialPost!.attachedEvent;
      }
      if (widget.initialPost!.videoUrl != null && widget.initialPost!.videoUrl!.isNotEmpty) {
        _attachedVideo = widget.initialPost!.videoUrl;
      }
    }
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _editorFocusNode.dispose();
    _previewVideoController?.dispose(); // Step 3B: no controller leak
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();
  late final MediaPicker _mediaPicker = widget.mediaPicker ?? MediaPicker(picker: _picker);

  Future<void> _pickGalleryImages() async {
    // If a video is attached, ask user before replacing it with images
    if (_attachedVideo != null) {
      final replace = await _showMediaConflictDialog(videoReplacingImages: false);
      if (!replace) return;
      await _clearVideo();
    }
    try {
      final List<XFile> selected = await _picker.pickMultiImage();
      if (selected.isNotEmpty) {
        setState(() {
          _attachedImages.addAll(selected.map((e) => e.path));
        });
      }
    } on PlatformException catch (e) {
      // Permission denied or picker unavailable

      debugPrint('[CreatePostScreen] Gallery pick PlatformException: ${e.code} — ${e.message}');
      if (!mounted) return;
      final bool isPermissionError =
          e.code == 'photo_access_denied' ||
          e.code == 'access_denied' ||
          e.code == 'permission_denied' ||
          (e.message ?? '').toLowerCase().contains('permission') ||
          (e.message ?? '').toLowerCase().contains('denied');
      AppNotificationBanner.showDanger(
        context: context,
        title: isPermissionError
            ? ('community.photoPermissionDenied'.tr.isNotEmpty &&
                'community.photoPermissionDenied'.tr != 'community.photoPermissionDenied'
                    ? 'community.photoPermissionDenied'.tr
                    : 'Photo Access Denied')
            : ('community.galleryUnavailable'.tr.isNotEmpty &&
                'community.galleryUnavailable'.tr != 'community.galleryUnavailable'
                    ? 'community.galleryUnavailable'.tr
                    : 'Gallery Unavailable'),
        message: isPermissionError
            ? ('community.photoPermissionDeniedMsg'.tr.isNotEmpty &&
                'community.photoPermissionDeniedMsg'.tr != 'community.photoPermissionDeniedMsg'
                    ? 'community.photoPermissionDeniedMsg'.tr
                    : 'Please allow photo access in your device settings to attach images.')
            : ('community.galleryUnavailableMsg'.tr.isNotEmpty &&
                'community.galleryUnavailableMsg'.tr != 'community.galleryUnavailableMsg'
                    ? 'community.galleryUnavailableMsg'.tr
                    : 'Could not open photo gallery. Please try again.'),
      );
    } catch (e) {
      // Unexpected error — log but do not crash; picker cancellation is not an error
      debugPrint('[CreatePostScreen] Gallery pick unexpected error: $e');
    }
  }

  Future<void> _pickCameraImage() async {
    // If a video is attached, ask user before replacing it with camera photo
    if (_attachedVideo != null) {
      final replace = await _showMediaConflictDialog(videoReplacingImages: false);
      if (!replace) return;
      await _clearVideo();
    }
    try {
      final XFile? captured = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (captured != null) {
        final capturedPath = captured.path;
        setState(() {
          _attachedImages.add(capturedPath);
        });
      }
    } catch (e, stack) {
      debugPrint('[CreatePostScreen] Camera pick error: $e\n$stack');
      if (mounted) {
        final String errorMessage = e is StateError
            ? "Camera is not available on this device."
            : "Could not access device camera: $e";
        AppNotificationBanner.showDanger(
          context: context,
          title: "Camera Unavailable",
          message: errorMessage,
        );
      }
    }
  }

  // ─── Video picking using existing MediaPicker ────────────────────────────

  /// Picks a video from the gallery using [MediaPicker.pickVideo].
  /// If images are already attached, asks the user to confirm replacement.
  Future<void> _pickGalleryVideo() async {
    // Conflict: images exist — ask user
    if (_attachedImages.isNotEmpty) {
      final replace = await _showMediaConflictDialog(videoReplacingImages: true);
      if (!replace) return;
    }

    try {
      final PickedMedia? picked = await _mediaPicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (picked == null) return; // user cancelled — not an error

      if (picked.path != null && picked.path!.isNotEmpty) {
        await _setVideoFile(picked.path!);
      }
    } on PlatformException catch (e) {
      debugPrint('[CreatePostScreen] Video pick PlatformException: ${e.code} — ${e.message}');
      if (!mounted) return;
      final bool isPermission =
          e.code == 'photo_access_denied' ||
          e.code == 'access_denied' ||
          e.code == 'permission_denied' ||
          (e.message ?? '').toLowerCase().contains('permission') ||
          (e.message ?? '').toLowerCase().contains('denied');
      AppNotificationBanner.showDanger(
        context: context,
        title: 'community.videoPermissionDenied'.tr != 'community.videoPermissionDenied'
            ? 'community.videoPermissionDenied'.tr
            : isPermission ? 'Video Access Denied' : 'Video Unavailable',
        message: 'community.videoPermissionDeniedMsg'.tr != 'community.videoPermissionDeniedMsg'
            ? 'community.videoPermissionDeniedMsg'.tr
            : 'Please allow video access in your device settings.',
      );
    } catch (e) {
      // Cancellation / unexpected — do not crash or show error for simple cancel
      debugPrint('[CreatePostScreen] Video pick: $e');
    }
  }

  /// Initializes the [VideoPlayerController] for preview from [path].
  /// Disposes any previous controller first to prevent leaks.
  Future<void> _setVideoFile(String path) async {
    // Dispose old controller cleanly
    final old = _previewVideoController;
    setState(() {
      _attachedVideo = path;
      _attachedImages = []; // clear any images — video/image mutual exclusion
      _previewVideoController = null;
      _videoInitialized = false;
      _videoInitError = false;
    });
    await old?.dispose();

    try {
      final ctrl = VideoPlayerController.file(File(path));
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _previewVideoController = ctrl;
        _videoInitialized = true;
      });
    } catch (e) {
      debugPrint('[CreatePostScreen] VideoPlayerController init error: $e');
      if (mounted) setState(() => _videoInitError = true);
    }
  }

  /// Removes the selected video and disposes its controller.
  Future<void> _clearVideo() async {
    final ctrl = _previewVideoController;
    setState(() {
      _attachedVideo = null;
      _previewVideoController = null;
      _videoInitialized = false;
      _videoInitError = false;
    });
    await ctrl?.dispose();
  }

  @visibleForTesting
  String? get attachedVideo => _attachedVideo;

  @visibleForTesting
  List<String> get attachedImages => _attachedImages;

  @visibleForTesting
  bool get videoInitError => _videoInitError;

  @visibleForTesting
  Future<void> setVideoFileForTesting(String path) => _setVideoFile(path);

  @visibleForTesting
  Future<void> clearVideoForTesting() => _clearVideo();

  @visibleForTesting
  void setVideoInitErrorForTesting(bool error) {
    setState(() {
      _videoInitError = error;
    });
  }

  @visibleForTesting
  void setAttachedVideoForTesting(String? path) {
    setState(() {
      _attachedVideo = path;
    });
  }

  @visibleForTesting
  void setVideoInitializedForTesting(bool initialized) {
    setState(() {
      _videoInitialized = initialized;
    });
  }

  @visibleForTesting
  void setAttachedImagesForTesting(List<String> images) {
    setState(() {
      _attachedImages = List.from(images);
    });
  }

  /// Shows a conflict dialog when the user tries to switch between media types.
  /// Returns true if the user confirms the replacement.
  Future<bool> _showMediaConflictDialog({required bool videoReplacingImages}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2228) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            videoReplacingImages
                ? ('community.videoReplaceImages'.tr != 'community.videoReplaceImages'
                    ? 'community.videoReplaceImages'.tr
                    : 'Replace photos with video?')
                : ('community.imagesReplaceVideo'.tr != 'community.imagesReplaceVideo'
                    ? 'community.imagesReplaceVideo'.tr
                    : 'Replace video with photos?'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            videoReplacingImages
                ? ('community.videoReplaceImagesMsg'.tr != 'community.videoReplaceImagesMsg'
                    ? 'community.videoReplaceImagesMsg'.tr
                    : 'Selecting a video will remove your selected photos. Continue?')
                : ('community.imagesReplaceVideoMsg'.tr != 'community.imagesReplaceVideoMsg'
                    ? 'community.imagesReplaceVideoMsg'.tr
                    : 'Selecting photos will remove your selected video. Continue?'),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'community.keepEditing'.tr != 'community.keepEditing'
                    ? 'community.keepEditing'.tr
                    : 'Cancel',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'community.done'.tr != 'community.done' ? 'community.done'.tr : 'Replace',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  // ──────────────────────────────────────────────────────────────────────────

  void _showMediaPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16181C) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF8E9297) : const Color(0xFF65676B);
    final borderColor = isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'community.photoVideo'.tr.isNotEmpty && 'community.photoVideo'.tr != 'community.photoVideo'
                    ? 'community.photoVideo'.tr
                    : 'Add Photos or Video',
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF22262E) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_outlined, color: textPrimary, size: 20),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: Text(
                  'Select multiple photos from your library',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickGalleryImages();
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF22262E) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: textPrimary, size: 20),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: Text(
                  'Capture a new photo with your camera',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCameraImage();
                },
              ),
              const SizedBox(height: 6),
              // ─── Step 3B-Frontend: Video picker option ─────────────────
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF22262E) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.videocam_outlined, color: textPrimary, size: 20),
                ),
                title: Text(
                  'community.selectVideo'.tr != 'community.selectVideo'
                      ? 'community.selectVideo'.tr
                      : 'Select Video',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: Text(
                  'community.videoFromGallery'.tr != 'community.videoFromGallery'
                      ? 'community.videoFromGallery'.tr
                      : 'Choose a video from your gallery',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickGalleryVideo();
                },
              ),
              // ──────────────────────────────────────────────────────────
            ],
          ),
        ),
      ),
    );
  }

  void _removeImageAt(int index) {
    if (index >= 0 && index < _attachedImages.length) {
      setState(() {
        _attachedImages.removeAt(index);
      });
    }
  }

  void _showAudiencePickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF8E9297) : const Color(0xFF65676B);
    final surface = isDark ? const Color(0xFF16181C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'community.whoCanSee'.tr.isNotEmpty && 'community.whoCanSee'.tr != 'community.whoCanSee'
                    ? 'community.whoCanSee'.tr
                    : 'Who can see your post?',
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...[
                {'key': 'Public', 'label': 'community.public'.tr.isNotEmpty && 'community.public'.tr != 'community.public' ? 'community.public'.tr : 'Public', 'desc': 'Visible to everyone on GenLink', 'icon': Icons.public},
                {'key': 'Friends', 'label': 'community.friendsOnly'.tr.isNotEmpty && 'community.friendsOnly'.tr != 'community.friendsOnly' ? 'community.friendsOnly'.tr : 'Friends Only', 'desc': 'Only your connections can view', 'icon': Icons.group_outlined},
                {'key': 'Only Me', 'label': 'community.onlyMe'.tr.isNotEmpty && 'community.onlyMe'.tr != 'community.onlyMe' ? 'community.onlyMe'.tr : 'Only Me', 'desc': 'Private to your account only', 'icon': Icons.lock_outline},
              ].map((item) {
                final key = item['key'] as String;
                final label = item['label'] as String;
                final desc = item['desc'] as String;
                final icon = item['icon'] as IconData;
                final isSelected = _selectedAudience == key;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF22262E) : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: isSelected ? textPrimary : textSecondary, size: 20),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    desc,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  trailing: isSelected ? Icon(Icons.check_circle_rounded, color: textPrimary, size: 20) : null,
                  onTap: () {
                    setState(() {
                      _selectedAudience = key;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationPickerSheet() {
    final locations = [
      'CADT Innovation Center, Phnom Penh',
      'RUPP Campus 1, Phnom Penh',
      'ITC Campus, Phnom Penh',
      'National University of Management',
      'Paragon International University',
      'Phnom Penh City Center (PPCC)',
      'Siem Reap Campus Hub',
      'Aeon Mall Sen Sok, Phnom Penh',
      'Factory Phnom Penh',
      'Chip Mong 271 Mega Mall',
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16181C) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF8E9297) : const Color(0xFF65676B);
    final borderColor = isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8);
    final inputBg = isDark ? const Color(0xFF1E2228) : const Color(0xFFF2F4F7);

    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = locations.where((l) => l.toLowerCase().contains(query.toLowerCase())).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Material(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.65,
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'community.location'.tr.isNotEmpty && 'community.location'.tr != 'community.location'
                          ? 'community.location'.tr
                          : 'Add Location',
                      style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (v) => setSheetState(() => query = v),
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 18),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length + (query.trim().isNotEmpty ? 1 : 0),
                        itemBuilder: (context, idx) {
                          if (query.trim().isNotEmpty && idx == filtered.length) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.add_location_alt_outlined, color: textPrimary),
                              title: Text(
                                'Use "$query"',
                                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedLocation = query.trim();
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          }
                          final loc = filtered[idx];
                          final isSel = _selectedLocation == loc;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.location_on_outlined, color: isSel ? textPrimary : textSecondary),
                            title: Text(
                              loc,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSel ? Icon(Icons.check, color: textPrimary, size: 18) : null,
                            onTap: () {
                              setState(() {
                                _selectedLocation = isSel ? null : loc;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFeelingActivitySheet() {
    final feelings = [
      '😊 Happy',
      '🤩 Excited',
      '😇 Blessed',
      '💡 Inspired',
      '😴 Tired',
      '💪 Motivated',
      '🥳 Celebrating',
      '🧘 Relaxed',
      '☕ Chilling',
      '❤️ Loved',
      '🔥 Fired up',
      '🧠 Focused',
    ];

    final activities = [
      '📚 Studying',
      '💻 Coding',
      '🎓 In Class',
      '🚀 Working on project',
      '🍕 Having lunch',
      '🎧 Listening to music',
      '🏋️ Working out',
      '✈️ Traveling',
      '🎮 Gaming',
      '☕ Drinking coffee',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16181C) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E2228) : const Color(0xFFF2F4F7);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF8E9297) : const Color(0xFF65676B);
    final borderColor = isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.55,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'community.selectFeeling'.tr.isNotEmpty && 'community.selectFeeling'.tr != 'community.selectFeeling'
                    ? 'community.selectFeeling'.tr
                    : 'How are you feeling?',
                style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TabBar(
                labelColor: textPrimary,
                unselectedLabelColor: textSecondary,
                indicatorColor: textPrimary,
                indicatorWeight: 2,
                tabs: [
                  Tab(
                    text: 'community.feelings'.tr.isNotEmpty && 'community.feelings'.tr != 'community.feelings'
                        ? 'community.feelings'.tr
                        : 'Feelings',
                  ),
                  Tab(
                    text: 'community.activities'.tr.isNotEmpty && 'community.activities'.tr != 'community.activities'
                        ? 'community.activities'.tr
                        : 'Activities',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: feelings.length,
                      itemBuilder: (context, idx) {
                        final item = feelings[idx];
                        final isSel = _selectedFeeling == item;
                        return Material(
                          color: isSel ? (isDark ? Colors.white : Colors.black87) : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFeeling = isSel ? null : item;
                              });
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? Colors.transparent : borderColor,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSel ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                  fontSize: 13,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: activities.length,
                      itemBuilder: (context, idx) {
                        final item = activities[idx];
                        final isSel = _selectedFeeling == item;
                        return Material(
                          color: isSel ? (isDark ? Colors.white : Colors.black87) : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFeeling = isSel ? null : item;
                              });
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? Colors.transparent : borderColor,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSel ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                  fontSize: 13,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGifPickerSheet() async {
    if (_attachedVideo != null) {
      final replace = await _showMediaConflictDialog(videoReplacingImages: false);
      if (!replace) return;
      await _clearVideo();
    }
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16181C) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E2228) : const Color(0xFFF2F4F7);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF8E9297) : const Color(0xFF65676B);
    final borderColor = isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8);
    final inputBg = isDark ? const Color(0xFF1E2228) : const Color(0xFFF2F4F7);

    final gifs = [
      {'title': 'Celebration 🎉', 'url': 'https://media.giphy.com/media/artj92V8o75VPL7AeQ/giphy.gif'},
      {'title': 'Thumbs Up 👍', 'url': 'https://media.giphy.com/media/111ebonMs90YLu/giphy.gif'},
      {'title': 'Excited 🤩', 'url': 'https://media.giphy.com/media/5GoVLqeAOo6PK/giphy.gif'},
      {'title': 'Coding 💻', 'url': 'https://media.giphy.com/media/JIX9t2j0ZTN9S/giphy.gif'},
      {'title': 'Mind Blown 🤯', 'url': 'https://media.giphy.com/media/xT0xeJpnrWC4XWblEk/giphy.gif'},
      {'title': 'Coffee Time ☕', 'url': 'https://media.giphy.com/media/oZEBLugoTNRxS/giphy.gif'},
      {'title': 'High Five 🙌', 'url': 'https://media.giphy.com/media/3oEjHV0z8S7WM4MwnK/giphy.gif'},
      {'title': 'Let\'s Go 🚀', 'url': 'https://media.giphy.com/media/7WvAUvZZTRpSuudobh/giphy.gif'},
    ];

    String gifQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filteredGifs = gifs.where((g) => g['title']!.toLowerCase().contains(gifQuery.toLowerCase())).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Material(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.60,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select GIF',
                          style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textSecondary, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (val) => setSheetState(() => gifQuery = val),
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search GIFs...',
                        hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 18),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: filteredGifs.length,
                        itemBuilder: (context, idx) {
                          final item = filteredGifs[idx];
                          final url = item['url']!;
                          final title = item['title']!;

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Material(
                              color: cardBg,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _attachedImages.add(url);
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        color: Colors.black54,
                                        child: Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showScheduleDialog() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null && mounted) {
      AppNotificationBanner.showInfo(
        context: context,
        title: 'community.postScheduled'.tr.isNotEmpty && 'community.postScheduled'.tr != 'community.postScheduled'
            ? 'community.postScheduled'.tr
            : 'Post Scheduled',
        message: 'community.postScheduledAt'.tr.isNotEmpty && 'community.postScheduledAt'.tr != 'community.postScheduledAt'
            ? 'community.postScheduledAt'.tr.replaceAll('@time', pickedTime.format(context))
            : 'Your post is scheduled for ${pickedTime.format(context)}',
      );
    }
  }

  bool get _canPost {
    final text = _textController.text.trim();
    return text.isNotEmpty ||
        _attachedImages.isNotEmpty ||
        _attachedVideo != null || // Step 3B: video-only post is valid
        _pollQuestion != null ||
        _attachedEvent != null ||
        _selectedLocation != null ||
        _selectedFeeling != null ||
        _taggedPeople.isNotEmpty ||
        _attachedLink != null;
  }

  void _onBackPress() {
    if (_canPost) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E2228),
          title: Text(
            'community.discardDraft'.tr.isNotEmpty && 'community.discardDraft'.tr != 'community.discardDraft'
                ? 'community.discardDraft'.tr
                : 'Discard draft?',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'community.discardMessage'.tr.isNotEmpty && 'community.discardMessage'.tr != 'community.discardMessage'
                ? 'community.discardMessage'.tr
                : 'You have unsaved changes. If you leave now, your changes will be discarded.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'community.keepEditing'.tr.isNotEmpty && 'community.keepEditing'.tr != 'community.keepEditing'
                    ? 'community.keepEditing'.tr
                    : 'Keep Editing',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'community.discard'.tr.isNotEmpty && 'community.discard'.tr != 'community.discard'
                    ? 'community.discard'.tr
                    : 'Discard',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildUserAvatar(bool isDark) {
    return AppAvatar(
      imageUrl: CurrentUser.avatarUrl,
      name: CurrentUser.name,
      size: 34,
    );
  }

  void _submitPost() async {
    if (!_canPost || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final controller = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : Get.put(CommunityController());

    List<PollOptionModel>? pollOpts;
    if (_pollQuestion != null && _pollOptionsList.isNotEmpty) {
      pollOpts = _pollOptionsList
          .map((opt) => PollOptionModel(
                text: opt,
                votes: 0,
                isVoted: false,
              ))
          .toList();
    }

    final visibilityValue = _selectedAudience;

    if (_isEditing) {
      await controller.updatePost(
        postId: widget.initialPost!.id,
        content: _textController.text.trim(),
        imageUrls: _attachedImages,
        videoUrl: _attachedVideo,
        visibility: visibilityValue,
        location: _selectedLocation,
        linkUrl: _attachedLink,
        linkPreviewTitle: _linkTitle,
        linkPreviewDomain: _linkDomain,
        pollQuestion: _pollQuestion,
        pollOptions: pollOpts,
        pollDuration: _pollDuration,
        attachedEvent: _attachedEvent,
      );

      if (mounted) {
        AppNotificationBanner.showSuccess(
          context: context,
          title: 'community.postUpdated'.tr.isNotEmpty && 'community.postUpdated'.tr != 'community.postUpdated'
              ? 'community.postUpdated'.tr
              : 'Post updated',
          message: 'community.postUpdatedMsg'.tr.isNotEmpty && 'community.postUpdatedMsg'.tr != 'community.postUpdatedMsg'
              ? 'community.postUpdatedMsg'.tr
              : 'Your post changes have been saved.',
        );
        Navigator.pop(context);
      }
    } else {
      final success = await controller.createPost(
        content: _textController.text.trim(),
        imageUrls: _attachedImages,
        videoUrl: _attachedVideo,
        visibility: visibilityValue,
        location: _selectedLocation,
        linkUrl: _attachedLink,
        linkPreviewTitle: _linkTitle,
        linkPreviewDomain: _linkDomain,
        pollQuestion: _pollQuestion,
        pollOptions: pollOpts,
        pollDuration: _pollDuration,
        attachedEvent: _attachedEvent,
      );

      if (mounted) {
        if (success) {
          AppNotificationBanner.showSuccess(
            context: context,
            title: 'community.postCreated'.tr.isNotEmpty && 'community.postCreated'.tr != 'community.postCreated'
                ? 'community.postCreated'.tr
                : 'Post published',
            message: 'community.postCreatedMsg'.tr.isNotEmpty && 'community.postCreatedMsg'.tr != 'community.postCreatedMsg'
                ? 'community.postCreatedMsg'.tr
                : 'Your post is now live on the community feed.',
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF8E9297) : const Color(0xFF65676B);
    final cardBg = isDark ? const Color(0xFF16181C) : const Color(0xFFF2F4F7);
    final cardBorder = isDark ? const Color(0xFF262B34) : const Color(0xFFE2E4E8);
    final bottomBarBg = isDark ? const Color(0xFF101216) : Colors.white;

    final charCount = _textController.text.length;

    return PopScope(
      canPop: !_canPost || _isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBackPress();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: isDark ? const Color(0xFF0C0E12) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0C0E12) : Colors.white,
          elevation: 0,
          leadingWidth: 38,
          leading: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
            onPressed: _onBackPress,
          ),
          titleSpacing: 2,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserAvatar(isDark),
              const SizedBox(width: 6),
              Flexible(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAudiencePickerSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C2028) : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedAudience == 'Public'
                                ? Icons.public
                                : (_selectedAudience == 'Friends' ? Icons.group_outlined : Icons.lock_outline),
                            color: textSecondary,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _selectedAudience == 'Public'
                                  ? ('community.public'.tr.isNotEmpty && 'community.public'.tr != 'community.public'
                                      ? 'community.public'.tr
                                      : 'Public')
                                  : (_selectedAudience == 'Friends'
                                      ? ('community.friendsOnly'.tr.isNotEmpty && 'community.friendsOnly'.tr != 'community.friendsOnly'
                                          ? 'community.friendsOnly'.tr
                                          : 'Friends')
                                      : ('community.onlyMe'.tr.isNotEmpty && 'community.onlyMe'.tr != 'community.onlyMe'
                                          ? 'community.onlyMe'.tr
                                          : 'Only Me')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.expand_more_rounded, color: textSecondary, size: 13),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              icon: Icon(Icons.schedule_outlined, color: textSecondary, size: 20),
              tooltip: 'Schedule Post',
              onPressed: _showScheduleDialog,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 10, bottom: 10, left: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _canPost && !_isSubmitting
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? const Color(0xFF22262E) : const Color(0xFFE4E7EC)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _canPost && !_isSubmitting ? _submitPost : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: _canPost
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? Colors.white30 : Colors.black38),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              child: Text(
                                _isEditing
                                    ? ('common.save'.tr.isNotEmpty && 'common.save'.tr != 'common.save'
                                        ? 'common.save'.tr
                                        : 'Save')
                                    : ('community.post'.tr.isNotEmpty && 'community.post'.tr != 'community.post'
                                        ? 'community.post'.tr
                                        : 'Post'),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _textController,
                        focusNode: _editorFocusNode,
                        autofocus: !_isEditing,
                        minLines: 6,
                        maxLines: null,
                        maxLength: _maxCharacters,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          hintText: 'community.whatsOnYourMind'.tr.isNotEmpty &&
                                  'community.whatsOnYourMind'.tr != 'community.whatsOnYourMind'
                              ? 'community.whatsOnYourMind'.tr
                              : "What's on your mind?",
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                            fontSize: 18,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      if (charCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "$charCount / $_maxCharacters",
                              style: TextStyle(
                                color: textSecondary.withValues(alpha: 0.7),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ─── Step 3B-Frontend: Video preview ────────────────────
                      if (_attachedVideo != null) _buildVideoPreview(isDark, cardBg, cardBorder, textSecondary),
                      if (_attachedVideo != null) const SizedBox(height: 12),
                      // ────────────────────────────────────────────────────────

                      if (_attachedImages.isNotEmpty ||

                          _pollQuestion != null ||
                          _attachedEvent != null ||
                          _attachedLink != null ||
                          _selectedLocation != null ||
                          _selectedFeeling != null ||
                          _taggedPeople.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ..._attachedImages.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final imgPath = entry.value;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: cardBorder, width: 0.8),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      imgPath.startsWith('http')
                                          ? Image.network(
                                              imgPath,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Icon(Icons.broken_image_outlined, color: textSecondary),
                                            )
                                          : imgPath.startsWith('assets/')
                                              ? Image.asset(imgPath, fit: BoxFit.cover)
                                              : Image.file(File(imgPath), fit: BoxFit.cover),
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                            colors: [Color(0x99000000), Colors.transparent],
                                            stops: [0.0, 0.5],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: GestureDetector(
                                          onTap: () => _removeImageAt(idx),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xCC000000),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            if (_selectedLocation != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cardBorder, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on_outlined, color: textPrimary, size: 16),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _selectedLocation!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedLocation = null),
                                      child: Icon(Icons.close, color: textSecondary, size: 15),
                                    ),
                                  ],
                                ),
                              ),

                            if (_selectedFeeling != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cardBorder, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sentiment_satisfied_alt_outlined, color: textPrimary, size: 16),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _selectedFeeling!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedFeeling = null),
                                      child: Icon(Icons.close, color: textSecondary, size: 15),
                                    ),
                                  ],
                                ),
                              ),

                            if (_attachedEvent != null)
                              _buildAttachedEventCard(isDark, cardBg, cardBorder),

                            if (_pollQuestion != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cardBorder, width: 0.8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.bar_chart_rounded, color: textPrimary, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _pollQuestion!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            '${_pollOptionsList.length} options · $_pollDuration',
                                            style: TextStyle(color: textSecondary, fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _pollQuestion = null;
                                        _pollOptionsList = [];
                                      }),
                                      child: Icon(Icons.close, color: textSecondary, size: 18),
                                    ),
                                  ],
                                ),
                              ),

                            if (_attachedLink != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cardBorder, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.link_rounded, color: textPrimary, size: 16),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _linkDomain ?? _attachedLink!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _attachedLink = null;
                                        _linkTitle = null;
                                        _linkDomain = null;
                                      }),
                                      child: Icon(Icons.close, color: textSecondary, size: 15),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bottomBarBg,
                  border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
                ),
                child: Row(
                  children: [
                    _ToolbarBtn(
                      icon: Icons.image_outlined,
                      tooltip: 'Media / Image',
                      color: textPrimary.withValues(alpha: 0.85),
                      onPressed: _showMediaPickerSheet,
                    ),
                    _ToolbarBtn(
                      icon: Icons.gif_box_outlined,
                      tooltip: 'GIF',
                      color: textPrimary.withValues(alpha: 0.85),
                      onPressed: _showGifPickerSheet,
                    ),
                    _ToolbarBtn(
                      icon: Icons.sentiment_satisfied_alt_outlined,
                      tooltip: 'Feeling / Activity',
                      color: textPrimary.withValues(alpha: 0.85),
                      onPressed: _showFeelingActivitySheet,
                    ),
                    _ToolbarBtn(
                      icon: Icons.event_outlined,
                      tooltip: 'Event',
                      color: textPrimary.withValues(alpha: 0.85),
                      onPressed: () async {
                        final event = await Get.to<EventModel>(
                          () => const CreateEventScreen(returnCreatedEvent: true),
                        );
                        if (event != null) {
                          setState(() {
                            _attachedEvent = event;
                          });
                        }
                      },
                    ),
                    _ToolbarBtn(
                      icon: Icons.location_on_outlined,
                      tooltip: 'Location',
                      color: textPrimary.withValues(alpha: 0.85),
                      onPressed: _showLocationPickerSheet,
                    ),

                    const Spacer(),

                    Tooltip(
                      message: 'create.title'.tr.isNotEmpty && 'create.title'.tr != 'create.title'
                          ? 'create.title'.tr
                          : 'Create',
                      child: Material(
                        color: isDark ? const Color(0xFF1C2028) : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            GlobalCreateSheet.show(context, fromPostComposer: true);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 38,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2E3440) : const Color(0xFFD6DAE2),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(Icons.add_rounded, color: textPrimary, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachedEventCard(bool isDark, Color cardBg, Color cardBorder) {
    if (_attachedEvent == null) return const SizedBox.shrink();
    final ev = _attachedEvent!;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 0.8),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () => Get.to(() => EventDetailsScreen(event: ev)),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8),
                      child: ev.coverImageFile != null
                          ? Image.file(ev.coverImageFile!, fit: BoxFit.cover)
                          : (ev.imageUrl.isNotEmpty
                              ? Image.network(
                                  ev.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.event, color: textSecondary, size: 24),
                                )
                              : Icon(Icons.event, color: textSecondary, size: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ev.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2E36) : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ev.category,
                              style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Text(
                          ev.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.calendar_month_outlined, color: textSecondary, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ev.dateString,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textSecondary, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _attachedEvent = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2E36) : const Color(0xFFDDDDDD),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: textPrimary, size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3B-Frontend: Video preview widget ───────────────────────────────
  Widget _buildVideoPreview(bool isDark, Color cardBg, Color cardBorder, Color textSecondary) {
    final ctrl = _previewVideoController;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16181C) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Video area ──────────────────────────────────────────────
            AspectRatio(
              aspectRatio: (ctrl != null && _videoInitialized)
                  ? ctrl.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Video or placeholder background
                  if (ctrl != null && _videoInitialized)
                    VideoPlayer(ctrl)
                  else
                    Container(
                      color: isDark ? const Color(0xFF0C0E12) : const Color(0xFFE0E0E0),
                    ),

                  // Loading spinner
                  if (_attachedVideo != null && !_videoInitialized && !_videoInitError)
                    const CircularProgressIndicator(strokeWidth: 2),

                  // Error state
                  if (_videoInitError)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
                        const SizedBox(height: 6),
                        Text(
                          'community.videoLoadError'.tr != 'community.videoLoadError'
                              ? 'community.videoLoadError'.tr
                              : 'Unable to play video',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ],
                    ),

                  // Play / pause overlay
                  if (ctrl != null && _videoInitialized)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
                          });
                        },
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: ctrl.value.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0x88000000),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Icon(
                                ctrl.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Footer: label + remove ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.videocam_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'community.videoReady'.tr != 'community.videoReady'
                          ? 'community.videoReady'.tr
                          : 'Video ready to post',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearVideo,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xCC000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ──────────────────────────────────────────────────────────────────────────
}

class _ToolbarBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ToolbarBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_ToolbarBtn> createState() => _ToolbarBtnState();
}

class _ToolbarBtnState extends State<_ToolbarBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _pressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
            child: Icon(widget.icon, size: 23, color: widget.color),
          ),
        ),
      ),
    );
  }
}
