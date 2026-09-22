import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../../../shared/utils/current_user.dart';
import '../../../../shared/widgets/global_create_sheet.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';
import 'create_discussion_screen.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'story_gallery_screen.dart';
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
  bool _isInnerPopupOpen = false;
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

  @visibleForTesting
  MediaPicker get mediaPicker => _mediaPicker;

  static bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.m4v');
  }

  /// Unified handler to attach selected media paths with mutual exclusion and no silent drops.
  Future<void> _handleSelectedMediaPaths(List<String> paths) async {
    if (paths.isEmpty) return;

    final videoPaths = paths.where((p) => _isVideoPath(p)).toList();
    final imagePaths = paths.where((p) => !videoPaths.contains(p)).toList();

    if (videoPaths.isNotEmpty) {
      if (_attachedImages.isNotEmpty) {
        final replace = await _showMediaConflictDialog(videoReplacingImages: true);
        if (!replace) return;
      }
      await _setVideoFile(videoPaths.first);
    } else if (imagePaths.isNotEmpty) {
      if (_attachedVideo != null) {
        final replace = await _showMediaConflictDialog(videoReplacingImages: false);
        if (!replace) return;
        await _clearVideo();
      }
      setState(() {
        _attachedImages.addAll(imagePaths);
      });
    }
  }

  /// Unified gallery picker: opens in-app media gallery with thumbnails and albums,
  /// falling back gracefully to system picker if needed.
  Future<void> _pickGalleryMedia() async {
    try {
      final selected = await Get.to<List<String>>(
        () => StoryGalleryScreen(
          onPhotosSelected: (paths) {
            // Returned by gallery
          },
        ),
        routeName: '/StoryGalleryScreen',
        transition: Transition.fadeIn,
      );
      if (selected != null && selected.isNotEmpty) {
        await _handleSelectedMediaPaths(selected);
        return;
      }
    } catch (e) {
      debugPrint('[CreatePostScreen] StoryGallery pick fallback: $e');
    }

    // Fallback: pick using system ImagePicker with bounded resolution
    try {
      List<XFile> selected = [];
      try {
        selected = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
      } catch (e) {
        debugPrint('[CreatePostScreen] pickMultiImage fallback to pickImage: $e');
        final single = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        if (single != null) selected = [single];
      }
      if (selected.isNotEmpty) {
        await _handleSelectedMediaPaths(selected.map((e) => e.path).toList());
      }
    } on PlatformException catch (e) {
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
                    : 'Please allow media access in your device settings.')
            : ('community.galleryUnavailableMsg'.tr.isNotEmpty &&
                'community.galleryUnavailableMsg'.tr != 'community.galleryUnavailableMsg'
                    ? 'community.galleryUnavailableMsg'.tr
                    : 'Could not open media gallery. Please try again.'),
      );
    } catch (e) {
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
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
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

  @visibleForTesting
  void setPollForTesting(String question, List<String> options) {
    setState(() {
      _pollQuestion = question;
      _pollOptionsList = List.from(options);
    });
  }

  @visibleForTesting
  String? get pollQuestion => _pollQuestion;

  @visibleForTesting
  List<String> get pollOptionsList => _pollOptionsList;

  /// Shows a conflict dialog when the user tries to switch between media types.
  /// Returns true if the user confirms the replacement.
  Future<bool> _showMediaConflictDialog({required bool videoReplacingImages}) async {
    final title = videoReplacingImages
        ? ('community.videoReplaceImages'.tr != 'community.videoReplaceImages'
            ? 'community.videoReplaceImages'.tr
            : 'Replace photos with video?')
        : ('community.imagesReplaceVideo'.tr != 'community.imagesReplaceVideo'
            ? 'community.imagesReplaceVideo'.tr
            : 'Replace video with photos?');

    final message = videoReplacingImages
        ? ('community.videoReplaceImagesMsg'.tr != 'community.videoReplaceImagesMsg'
            ? 'community.videoReplaceImagesMsg'.tr
            : 'Selecting a video will remove your selected photos. Continue?')
        : ('community.imagesReplaceVideoMsg'.tr != 'community.imagesReplaceVideoMsg'
            ? 'community.imagesReplaceVideoMsg'.tr
            : 'Selecting photos will remove your selected video. Continue?');

    final cancelLabel = 'community.keepEditing'.tr != 'community.keepEditing'
        ? 'community.keepEditing'.tr
        : 'Cancel';

    final confirmLabel = 'community.done'.tr != 'community.done'
        ? 'community.done'.tr
        : 'Replace';

    final result = await GenLinkConfirmDialog.showWarning(
      context: context,
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      icon: Icons.swap_horiz_rounded,
    );

    return result == true;
  }

  // ──────────────────────────────────────────────────────────────────────────

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

  void _showDocumentAttachmentNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'community.documentNotice'.tr.isNotEmpty &&
                  'community.documentNotice'.tr != 'community.documentNotice'
              ? 'community.documentNotice'.tr
              : 'Documents and files can be attached as media or shared via links.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPollCreatorSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16181C) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF8E9297) : const Color(0xFF65676B);
    final borderColor = isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8);
    final inputBg = isDark ? const Color(0xFF1E2228) : const Color(0xFFF2F4F7);

    final questionController = TextEditingController(text: _pollQuestion ?? '');
    final List<TextEditingController> optionControllers = [];
    if (_pollOptionsList.isNotEmpty) {
      for (final opt in _pollOptionsList) {
        optionControllers.add(TextEditingController(text: opt));
      }
    } else {
      optionControllers.add(TextEditingController());
      optionControllers.add(TextEditingController());
    }

    String? validationError;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void validateAndSave() {
            final question = questionController.text.trim();
            if (question.isEmpty) {
              setSheetState(() {
                validationError = 'community.pollEmptyQuestion'.tr.isNotEmpty &&
                        'community.pollEmptyQuestion'.tr != 'community.pollEmptyQuestion'
                    ? 'community.pollEmptyQuestion'.tr
                    : 'Please enter a poll question';
              });
              return;
            }

            final cleanOptions = optionControllers
                .map((c) => c.text.trim())
                .where((t) => t.isNotEmpty)
                .toList();

            if (cleanOptions.length < 2) {
              setSheetState(() {
                validationError = 'community.pollMinOptions'.tr.isNotEmpty &&
                        'community.pollMinOptions'.tr != 'community.pollMinOptions'
                    ? 'community.pollMinOptions'.tr
                    : 'Please provide at least 2 options';
              });
              return;
            }

            final uniqueOptions = <String>{};
            for (final opt in cleanOptions) {
              if (!uniqueOptions.add(opt.toLowerCase())) {
                setSheetState(() {
                  validationError = 'community.pollDuplicateOptions'.tr.isNotEmpty &&
                          'community.pollDuplicateOptions'.tr != 'community.pollDuplicateOptions'
                      ? 'community.pollDuplicateOptions'.tr
                      : 'Poll options must be unique';
                });
                return;
              }
            }

            setState(() {
              _pollQuestion = question;
              _pollOptionsList = cleanOptions;
            });
            Navigator.pop(ctx);
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Material(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: SingleChildScrollView(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.poll_rounded, color: textPrimary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'community.createPoll'.tr.isNotEmpty &&
                                        'community.createPoll'.tr != 'community.createPoll'
                                    ? 'community.createPoll'.tr
                                    : 'Create Poll',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: validateAndSave,
                            style: TextButton.styleFrom(
                              foregroundColor: textPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'common.done'.tr.isNotEmpty && 'common.done'.tr != 'common.done'
                                  ? 'common.done'.tr
                                  : 'Done',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (validationError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Text(
                        'community.pollQuestion'.tr.isNotEmpty &&
                                'community.pollQuestion'.tr != 'community.pollQuestion'
                            ? 'community.pollQuestion'.tr
                            : 'Question',
                        style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: questionController,
                        cursorColor: textPrimary,
                        onChanged: (_) {
                          if (validationError != null) {
                            setSheetState(() => validationError = null);
                          }
                        },
                        style: TextStyle(color: textPrimary, fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: 'community.pollQuestionHint'.tr.isNotEmpty &&
                                  'community.pollQuestionHint'.tr != 'community.pollQuestionHint'
                              ? 'community.pollQuestionHint'.tr
                              : 'Ask a question...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13.5),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor, width: 0.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor, width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white70 : Colors.black87,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'community.pollOptions'.tr.isNotEmpty &&
                                'community.pollOptions'.tr != 'community.pollOptions'
                            ? 'community.pollOptions'.tr
                            : 'Options',
                        style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      ...optionControllers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final ctrl = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: ctrl,
                                  cursorColor: textPrimary,
                                  onChanged: (_) {
                                    if (validationError != null) {
                                      setSheetState(() => validationError = null);
                                    }
                                  },
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Option ${idx + 1}',
                                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
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
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (optionControllers.length > 2)
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline_rounded, color: textSecondary, size: 20),
                                  tooltip: 'Remove Option',
                                  onPressed: () {
                                    setSheetState(() {
                                      optionControllers.removeAt(idx);
                                      if (validationError != null) validationError = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),

                      if (optionControllers.length < 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                optionControllers.add(TextEditingController());
                                if (validationError != null) validationError = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: textPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'community.pollAddOption'.tr.isNotEmpty &&
                                            'community.pollAddOption'.tr != 'community.pollAddOption'
                                        ? 'community.pollAddOption'.tr
                                        : 'Add Option',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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

  Future<void> _onBackPress() async {
    if (_isInnerPopupOpen) {
      setState(() => _isInnerPopupOpen = false);
      return;
    }
    if (_canPost) {
      final confirmed = await GenLinkConfirmDialog.showDiscard(
        context: context,
        title: 'community.discardDraft'.tr.isNotEmpty &&
                'community.discardDraft'.tr != 'community.discardDraft'
            ? 'community.discardDraft'.tr
            : 'Discard Draft?',
        message: 'community.discardMessage'.tr.isNotEmpty &&
                'community.discardMessage'.tr != 'community.discardMessage'
            ? 'community.discardMessage'.tr
            : 'You have unsaved changes. Discard them?',
        confirmLabel: 'community.discard'.tr.isNotEmpty &&
                'community.discard'.tr != 'community.discard'
            ? 'community.discard'.tr
            : 'Discard',
        cancelLabel: 'community.keepEditing'.tr.isNotEmpty &&
                'community.keepEditing'.tr != 'community.keepEditing'
            ? 'community.keepEditing'.tr
            : 'Keep Editing',
      );
      if (confirmed && mounted) {
        Navigator.pop(context);
      }
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
      bool success = false;
      if (_pollQuestion != null && _pollOptionsList.length >= 2) {
        success = await controller.createPollPost(
          question: _pollQuestion!,
          options: _pollOptionsList,
          caption: _textController.text.trim().isNotEmpty
              ? _textController.text.trim()
              : null,
          visibility: visibilityValue,
        );
      } else {
        success = await controller.createPost(
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
      }

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
          AppNotificationBanner.showDanger(
            context: context,
            title: 'common.error'.tr.isNotEmpty && 'common.error'.tr != 'common.error'
                ? 'common.error'.tr
                : 'Failed',
            message: 'Could not publish your post. Please try again.',
          );
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
    final bottomBarBg = isDark ? const Color(0xFF0C0E12) : Colors.white;

    final charCount = _textController.text.length;

    return PopScope(
      canPop: (!_canPost || _isSubmitting) && !_isInnerPopupOpen,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_editorFocusNode.hasFocus) {
                      _editorFocusNode.requestFocus();
                    }
                  },
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
                          minLines: 1,
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
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
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

                        // ─── Poll Preview (Compact & naturally placed directly under text) ───
                        if (_pollQuestion != null) ...[
                          const SizedBox(height: 8),
                          _buildPollPreviewCard(isDark, cardBg, cardBorder, textPrimary, textSecondary),
                        ],

                        // ─── Video preview ──────────────────────────────────────
                        if (_attachedVideo != null) ...[
                          const SizedBox(height: 8),
                          _buildVideoPreview(isDark, cardBg, cardBorder, textSecondary),
                        ],

                        // ─── Multiple Image Preview: Horizontal Scrollable Strip ───
                        if (_attachedImages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 104,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _attachedImages.length + (_attachedImages.length < 10 ? 1 : 0),
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                if (idx == _attachedImages.length) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Material(
                                      color: cardBg,
                                      child: InkWell(
                                        onTap: _pickGalleryMedia,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          width: 104,
                                          height: 104,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: cardBorder, width: 0.8),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_photo_alternate_outlined, color: textSecondary, size: 26),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Add more',
                                                style: TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final imgPath = _attachedImages[idx];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 104,
                                    height: 104,
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
                              },
                            ),
                          ),
                        ],

                        // ─── Other Attachment Chips ─────────────────────────────
                        if (_attachedEvent != null ||
                            _attachedLink != null ||
                            _selectedLocation != null ||
                            _selectedFeeling != null ||
                            _taggedPeople.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
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
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Bottom Attachment Toolbar ────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bottomBarBg,
                  border: Border(
                    top: BorderSide(
                      color: cardBorder.withValues(alpha: isDark ? 0.5 : 0.7),
                      width: 0.8,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Camera
                      _ToolbarBtn(
                        icon: Icons.camera_alt_outlined,
                        tooltip: 'community.camera'.tr.isNotEmpty && 'community.camera'.tr != 'community.camera'
                            ? 'community.camera'.tr
                            : 'Camera',
                        color: textPrimary.withValues(alpha: 0.85),
                        onPressed: _pickCameraImage,
                      ),
                      // 2. Gallery (Images or Video)
                      _ToolbarBtn(
                        icon: Icons.photo_library_outlined,
                        tooltip: 'community.gallery'.tr.isNotEmpty && 'community.gallery'.tr != 'community.gallery'
                            ? 'community.gallery'.tr
                            : 'Gallery',
                        color: textPrimary.withValues(alpha: 0.85),
                        onPressed: _pickGalleryMedia,
                      ),
                      // 3. GIF
                      _ToolbarBtn(
                        icon: Icons.gif_box_outlined,
                        tooltip: 'GIF',
                        color: textPrimary.withValues(alpha: 0.85),
                        onPressed: _showGifPickerSheet,
                      ),
                      // 4. Poll
                      _ToolbarBtn(
                        icon: Icons.poll_outlined,
                        tooltip: 'community.poll'.tr.isNotEmpty && 'community.poll'.tr != 'community.poll'
                            ? 'community.poll'.tr
                            : 'Poll',
                        color: textPrimary.withValues(alpha: 0.85),
                        onPressed: _showPollCreatorSheet,
                      ),
                      // 5. Emoji / Feeling
                      _ToolbarBtn(
                        icon: Icons.sentiment_satisfied_alt_outlined,
                        tooltip: 'Feeling / Activity',
                        color: textPrimary.withValues(alpha: 0.85),
                        onPressed: _showFeelingActivitySheet,
                      ),
                      // 6. Event
                      _ToolbarBtn(
                        icon: Icons.event_outlined,
                        tooltip: 'Event',
                        color: textPrimary.withValues(alpha: 0.85),
                        onPressed: () async {
                          final event = await Get.to<EventModel>(
                            () => const CreateEventScreen(returnCreatedEvent: true),
                          );
                          if (event != null && mounted) {
                            Get.back();
                            Get.to(() => EventDetailsScreen(event: event));
                          }
                        },
                      ),
                      // 7. Location
                      _ToolbarBtn(
                        icon: Icons.location_on_outlined,
                        tooltip: 'Location',
                        color: textPrimary.withValues(alpha: 0.85),
                        onPressed: _showLocationPickerSheet,
                      ),

                      const SizedBox(width: 6),

                      // 8. Inner "+" Button
                      Tooltip(
                        message: 'create.title'.tr.isNotEmpty && 'create.title'.tr != 'create.title'
                            ? 'create.title'.tr
                            : 'Create',
                        child: Builder(
                          builder: (btnContext) => Material(
                            color: _isInnerPopupOpen
                                ? (isDark ? const Color(0xFF282D37) : const Color(0xFFE2E6EE))
                                : (isDark ? const Color(0xFF1C2028) : const Color(0xFFF0F2F5)),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              canRequestFocus: false,
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _isInnerPopupOpen = true;
                                });
                                try {
                                  await GlobalCreateSheet.show(
                                    context,
                                    fromPostComposer: true,
                                    onSelectMedia: _pickGalleryMedia,
                                    onSelectPoll: _showPollCreatorSheet,
                                    onSelectCelebration: () {
                                      setState(() {
                                        _selectedFeeling = '🥳 Celebrating';
                                      });
                                    },
                                    onSelectDocument: _showDocumentAttachmentNotice,
                                    onSelectEvent: () async {
                                      final event = await Get.to<EventModel>(
                                        () => const CreateEventScreen(returnCreatedEvent: true),
                                      );
                                      if (event != null && mounted) {
                                        Get.back();
                                        Get.to(() => EventDetailsScreen(event: event));
                                      }
                                    },
                                    onSelectDiscussion: () async {
                                      final created = await Get.to<bool>(
                                        () => CreateDiscussionScreen(),
                                        routeName: '/CreateDiscussionScreen',
                                        transition: Transition.cupertino,
                                      );
                                      if (created == true && mounted) {
                                        Get.back();
                                      }
                                    },
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isInnerPopupOpen = false;
                                    });
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _isInnerPopupOpen
                                        ? (isDark ? const Color(0xFF485160) : const Color(0xFFB8C0CC))
                                        : (isDark ? const Color(0xFF2E3440) : const Color(0xFFD6DAE2)),
                                    width: 0.8,
                                  ),
                                ),
                                child: Icon(Icons.add_rounded, color: textPrimary, size: 21),
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildPollPreviewCard(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showPollCreatorSheet,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF22262E) : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.poll_rounded,
                    color: textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pollQuestion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_pollOptionsList.length} options · $_pollDuration',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textSecondary, size: 18),
                tooltip: 'Remove Poll',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() {
                  _pollQuestion = null;
                  _pollOptionsList = [];
                }),
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
      behavior: HitTestBehavior.opaque,
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
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 22, color: widget.color),
          ),
        ),
      ),
    );
  }
}
