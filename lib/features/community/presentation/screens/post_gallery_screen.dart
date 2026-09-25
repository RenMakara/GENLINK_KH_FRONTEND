import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';

/// Result returned from [PostGalleryScreen] to [CreatePostScreen].
class PostGalleryResult {
  final List<String> images;
  final String? video;
  final List<String> orderedMedia;

  const PostGalleryResult({
    required this.images,
    this.video,
    required this.orderedMedia,
  });

  int get totalCount => orderedMedia.length;
}

/// Unified media picker for GenLink Post Composer.
///
/// Features:
/// - Single unified session for both images and video.
/// - Multi-select enabled by default.
/// - Allows multiple images.
/// - Strictly enforces maximum 1 video with a compact validation message.
/// - Preserves already-selected media when reopening via "+ Add".
/// - Preserves selection order.
class PostGalleryScreen extends StatefulWidget {
  final List<String> initialSelectedImages;
  final String? initialSelectedVideo;
  final List<String>? initialMediaOrder;

  /// Optional test injection to bypass platform photo_manager in unit/widget tests.
  final List<AssetEntity>? mockAssetsForTesting;
  final bool? mockHasPermissionForTesting;
  final Future<List<String>> Function()? mockSystemPickerForTesting;

  const PostGalleryScreen({
    super.key,
    this.initialSelectedImages = const [],
    this.initialSelectedVideo,
    this.initialMediaOrder,
    this.mockAssetsForTesting,
    this.mockHasPermissionForTesting,
    this.mockSystemPickerForTesting,
  });

  @override
  State<PostGalleryScreen> createState() => PostGalleryScreenState();
}

class PostGalleryScreenState extends State<PostGalleryScreen>
    with WidgetsBindingObserver {
  final List<String> _selectedMediaPaths = [];
  final Set<String> _selectedImagePaths = {};
  String? _selectedVideoPath;

  final Map<String, String> _assetIdToPath = {};
  final Map<String, Uint8List> _thumbCache = {};

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _assets = [];

  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isLimited = false;
  bool _isPermanentlyDenied = false;
  bool _isCheckingPermission = false;
  bool _isProcessingTap = false;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  static const int _pageSize = 80;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Initialize existing selections
    if (widget.initialMediaOrder != null && widget.initialMediaOrder!.isNotEmpty) {
      _selectedMediaPaths.addAll(widget.initialMediaOrder!);
    } else {
      _selectedMediaPaths.addAll(widget.initialSelectedImages);
      if (widget.initialSelectedVideo != null) {
        _selectedMediaPaths.add(widget.initialSelectedVideo!);
      }
    }

    _selectedImagePaths.addAll(widget.initialSelectedImages);
    _selectedVideoPath = widget.initialSelectedVideo;

    // 2. Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // 3. Load media assets
    if (widget.mockAssetsForTesting != null) {
      _hasPermission = widget.mockHasPermissionForTesting ?? true;
      _assets = List.from(widget.mockAssetsForTesting!);
      _isLoading = false;
    } else if (widget.mockHasPermissionForTesting != null) {
      _hasPermission = widget.mockHasPermissionForTesting!;
      _isLoading = false;
    } else if (Get.testMode) {
      _hasPermission = true;
      _isLoading = false;
    } else {
      _initGallery();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !Get.testMode) {
      _initGallery(isResumed: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 400 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreAssets();
    }
  }

  Future<void> _initGallery({bool isResumed = false}) async {
    if (_isCheckingPermission) return;
    _isCheckingPermission = true;

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;

      if (ps.isAuth || ps.hasAccess) {
        setState(() {
          _hasPermission = true;
          _isLimited = ps.isLimited;
          _isPermanentlyDenied = false;
          _isLoading = true;
        });
        await _loadAlbums();
      } else {
        final bool permDenied = await _isMediaPermissionPermanentlyDenied(ps);
        if (!mounted) return;
        setState(() {
          _hasPermission = false;
          _isLimited = false;
          _isPermanentlyDenied = permDenied;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PostGalleryScreen] Init gallery error: $e');
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLimited = false;
          _isLoading = false;
        });
      }
    } finally {
      _isCheckingPermission = false;
    }
  }

  Future<bool> _isMediaPermissionPermanentlyDenied(PermissionState ps) async {
    if (Get.testMode) return false;
    if (ps == PermissionState.restricted) {
      return true;
    }
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          return await Permission.photos.isPermanentlyDenied;
        } else {
          return await Permission.storage.isPermanentlyDenied;
        }
      } else if (Platform.isIOS) {
        return await Permission.photos.isPermanentlyDenied;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<void> _openSettings() async {
    try {
      final opened = await openAppSettings();
      if (!opened) {
        await PhotoManager.openSetting();
      }
    } catch (_) {
      try {
        await PhotoManager.openSetting();
      } catch (_) {}
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // Common includes both images & videos
        filterOption: FilterOptionGroup(
          orders: const [
            OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );

      if (!mounted) return;

      if (albums.isNotEmpty) {
        _albums = albums;
        _currentAlbum = albums.first;
        await _loadFirstPageOfAssets();
      } else {
        setState(() {
          _albums = [];
          _assets = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PostGalleryScreen] Load albums error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFirstPageOfAssets() async {
    if (_currentAlbum == null) return;
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final List<AssetEntity> pageAssets =
          await _currentAlbum!.getAssetListPaged(page: 0, size: _pageSize);
      if (!mounted) return;

      setState(() {
        _assets = pageAssets;
        _isLoading = false;
        _hasMore = pageAssets.length >= _pageSize;
      });
    } catch (e) {
      debugPrint('[PostGalleryScreen] Load first page error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreAssets() async {
    if (_currentAlbum == null || !_hasMore) return;
    final nextPage = _currentPage + 1;

    try {
      final List<AssetEntity> pageAssets =
          await _currentAlbum!.getAssetListPaged(page: nextPage, size: _pageSize);
      if (!mounted) return;

      setState(() {
        _currentPage = nextPage;
        _assets.addAll(pageAssets);
        _hasMore = pageAssets.length >= _pageSize;
      });
    } catch (e) {
      debugPrint('[PostGalleryScreen] Load more error: $e');
    }
  }

  Future<String?> _resolvePath(AssetEntity asset) async {
    if (_assetIdToPath.containsKey(asset.id)) {
      return _assetIdToPath[asset.id];
    }
    try {
      final file = (await asset.file) ?? (await asset.originFile);
      if (file != null) {
        _assetIdToPath[asset.id] = file.path;
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _toggleAssetSelection(AssetEntity asset) async {
    if (_isProcessingTap) return;
    _isProcessingTap = true;

    try {
      final path = await _resolvePath(asset);
      if (path == null) {
        _isProcessingTap = false;
        return;
      }

      final isVideo = asset.type == AssetType.video;

      if (isVideo) {
        if (_selectedVideoPath == path) {
          // Unselect current video
          setState(() {
            _selectedVideoPath = null;
            _selectedMediaPaths.remove(path);
          });
        } else if (_selectedVideoPath != null) {
          // Attempt to select second video:
          // Rule: DO NOT show large confirmation dialog. Keep existing video.
          // Show compact validation message.
          if (mounted) {
            AppNotificationBanner.showWarning(
              context: context,
              title: 'community.videoLimit'.tr.isNotEmpty &&
                      'community.videoLimit'.tr != 'community.videoLimit'
                  ? 'community.videoLimit'.tr
                  : 'Video limit reached',
              message: 'community.onlyOneVideoAllowed'.tr.isNotEmpty &&
                      'community.onlyOneVideoAllowed'.tr !=
                          'community.onlyOneVideoAllowed'
                  ? 'community.onlyOneVideoAllowed'.tr
                  : 'Only one video can be added to a post.',
            );
          }
        } else {
          // Select video
          setState(() {
            _selectedVideoPath = path;
            _selectedMediaPaths.add(path);
          });
        }
      } else {
        // Image asset
        if (_selectedImagePaths.contains(path)) {
          // Unselect image
          setState(() {
            _selectedImagePaths.remove(path);
            _selectedMediaPaths.remove(path);
          });
        } else {
          // Select image
          setState(() {
            _selectedImagePaths.add(path);
            _selectedMediaPaths.add(path);
          });
        }
      }
    } finally {
      _isProcessingTap = false;
    }
  }

  /// Manually add media path for testing or direct fallback.
  @visibleForTesting
  void togglePathForTesting(String path, {required bool isVideo}) {
    if (isVideo) {
      if (_selectedVideoPath == path) {
        setState(() {
          _selectedVideoPath = null;
          _selectedMediaPaths.remove(path);
        });
      } else if (_selectedVideoPath != null) {
        AppNotificationBanner.showWarning(
          context: context,
          title: 'Video Limit',
          message: 'Only one video can be added to a post.',
        );
      } else {
        setState(() {
          _selectedVideoPath = path;
          _selectedMediaPaths.add(path);
        });
      }
    } else {
      if (_selectedImagePaths.contains(path)) {
        setState(() {
          _selectedImagePaths.remove(path);
          _selectedMediaPaths.remove(path);
        });
      } else {
        setState(() {
          _selectedImagePaths.add(path);
          _selectedMediaPaths.add(path);
        });
      }
    }
  }

  @visibleForTesting
  bool get hasPermission => _hasPermission;

  @visibleForTesting
  bool get isLimited => _isLimited;

  @visibleForTesting
  bool get isPermanentlyDenied => _isPermanentlyDenied;

  void _finishAndReturn() {
    final result = PostGalleryResult(
      images: _selectedImagePaths.toList(),
      video: _selectedVideoPath,
      orderedMedia: List.unmodifiable(_selectedMediaPaths),
    );
    Navigator.of(context).pop(result);
  }

  static bool isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.m4v');
  }

  Future<void> _pickFromSystemPicker({bool autoReturnIfDenied = true}) async {
    try {
      List<String> pickedPaths = [];
      if (widget.mockSystemPickerForTesting != null) {
        pickedPaths = await widget.mockSystemPickerForTesting!();
      } else {
        final picker = ImagePicker();
        List<XFile> picked = [];
        try {
          picked = await picker.pickMultipleMedia(imageQuality: 85);
        } catch (e) {
          debugPrint('[PostGalleryScreen] pickMultipleMedia fallback to pickMultiImage: $e');
          try {
            picked = await picker.pickMultiImage(imageQuality: 85);
          } catch (e2) {
            debugPrint('[PostGalleryScreen] pickMultiImage fallback to pickImage: $e2');
            final single = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
            );
            if (single != null) picked = [single];
          }
        }
        pickedPaths = picked.map((e) => e.path).toList();
      }

      if (pickedPaths.isEmpty) return;

      bool addedAny = false;
      for (final path in pickedPaths) {
        final isVideo = isVideoPath(path);

        if (isVideo) {
          if (_selectedVideoPath == path) {
            continue;
          } else if (_selectedVideoPath != null) {
            if (mounted) {
              AppNotificationBanner.showWarning(
                context: context,
                title: 'community.videoLimit'.tr.isNotEmpty &&
                        'community.videoLimit'.tr != 'community.videoLimit'
                    ? 'community.videoLimit'.tr
                    : 'Video limit reached',
                message: 'community.onlyOneVideoAllowed'.tr.isNotEmpty &&
                        'community.onlyOneVideoAllowed'.tr !=
                            'community.onlyOneVideoAllowed'
                    ? 'community.onlyOneVideoAllowed'.tr
                    : 'Only one video can be added to a post.',
              );
            }
          } else {
            _selectedVideoPath = path;
            if (!_selectedMediaPaths.contains(path)) {
              _selectedMediaPaths.add(path);
            }
            addedAny = true;
          }
        } else {
          if (!_selectedImagePaths.contains(path)) {
            _selectedImagePaths.add(path);
            _selectedMediaPaths.add(path);
            addedAny = true;
          }
        }
      }

      if (!mounted) return;
      setState(() {});

      if (autoReturnIfDenied && !_hasPermission && (addedAny || _selectedMediaPaths.isNotEmpty)) {
        _finishAndReturn();
      }
    } catch (e) {
      debugPrint('[PostGalleryScreen] System picker error: $e');
    }
  }

  Future<void> _pickVideoFromSystemPicker({bool autoReturnIfDenied = false}) async {
    if (_selectedVideoPath != null) {
      AppNotificationBanner.showWarning(
        context: context,
        title: 'Video Limit',
        message: 'Only one video can be added to a post.',
      );
      return;
    }
    try {
      final picker = ImagePicker();
      final XFile? vid = await picker.pickVideo(source: ImageSource.gallery);
      if (vid != null) {
        setState(() {
          _selectedVideoPath = vid.path;
          _selectedMediaPaths.add(vid.path);
        });
        if (autoReturnIfDenied && !_hasPermission) {
          _finishAndReturn();
        }
      }
    } catch (e) {
      debugPrint('[PostGalleryScreen] System video picker error: $e');
    }
  }

  void _showAlbumPickerSheet() {
    if (_albums.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2228) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Albums',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _albums.length,
                  itemBuilder: (context, idx) {
                    final album = _albums[idx];
                    final isSelected = album.id == _currentAlbum?.id;
                    return ListTile(
                      title: Text(
                        album.name == 'isAll' ? 'Recent' : album.name,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.blueAccent : AppColors.lightPrimary)
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: isDark ? Colors.blueAccent : AppColors.lightPrimary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!isSelected) {
                          setState(() {
                            _currentAlbum = album;
                          });
                          _loadFirstPageOfAssets();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final totalSelected = _selectedMediaPaths.length;

    final currentAlbumName = _currentAlbum?.name;
    final albumDisplayName = (currentAlbumName == null ||
            currentAlbumName.isEmpty ||
            currentAlbumName == 'isAll')
        ? 'Recent'
        : currentAlbumName;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          key: const Key('gallery_close_btn'),
          icon: Icon(Icons.close_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          key: const Key('gallery_album_dropdown_btn'),
          behavior: HitTestBehavior.opaque,
          onTap: _showAlbumPickerSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                albumDisplayName,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: textPrimary,
                size: 20,
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'System Picker',
            icon: Icon(Icons.photo_library_outlined, color: textPrimary, size: 22),
            onPressed: () {
              // Action sheet for system picker fallback
              _showSystemPickerSheet();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              key: const Key('gallery_done_btn'),
              onPressed: totalSelected > 0 ? _finishAndReturn : null,
              style: TextButton.styleFrom(
                backgroundColor: totalSelected > 0
                    ? (isDark ? Colors.blueAccent : AppColors.lightPrimary)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: Text(
                totalSelected > 0 ? 'Add ($totalSelected)' : 'Done',
                style: TextStyle(
                  color: totalSelected > 0
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black26),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasPermission && !_isLoading)
            _buildPermissionDeniedView(isDark)
          else if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_assets.isEmpty)
            _buildEmptyView(isDark)
          else
            Column(
              children: [
                if (_isLimited)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Limited photo access active',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () async {
                            await PhotoManager.presentLimited();
                            await _loadAlbums();
                          },
                          child: const Text('Manage', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildAssetGrid(isDark)),
              ],
            ),

          // Floating Bottom Bar when items selected
          if (totalSelected > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildBottomBar(isDark, totalSelected),
            ),
        ],
      ),
    );
  }

  void _showSystemPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2228) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick Photos from System'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromSystemPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Pick Video from System'),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideoFromSystemPicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, int totalSelected) {
    final imageCount = _selectedImagePaths.length;
    final hasVideo = _selectedVideoPath != null;

    final String countLabel;
    if (imageCount > 0 && hasVideo) {
      countLabel = '$imageCount photo${imageCount > 1 ? 's' : ''}, 1 video';
    } else if (hasVideo) {
      countLabel = '1 video';
    } else {
      countLabel = '$imageCount photo${imageCount > 1 ? 's' : ''}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2228) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? Colors.blueAccent : AppColors.lightPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                countLabel,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ElevatedButton(
            key: const Key('gallery_bottom_add_btn'),
            onPressed: _finishAndReturn,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.blueAccent : AppColors.lightPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'Add ($totalSelected)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 56,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            _isLimited
                ? 'No photos in limited selection'
                : 'No photos or videos found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 15,
            ),
          ),
          if (_isLimited) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Select More Photos'),
              onPressed: () async {
                await PhotoManager.presentLimited();
                await _loadAlbums();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 14),
            Text(
              'Access to Photos & Videos Needed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please allow GenLink to access photos and videos so you can attach them to your post.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('gallery_open_settings_btn'),
              onPressed: _openSettings,
              child: const Text('Open Settings'),
            ),
            const SizedBox(height: 10),
            TextButton(
              key: const Key('gallery_system_picker_fallback_btn'),
              onPressed: () => _pickFromSystemPicker(autoReturnIfDenied: true),
              child: const Text('Use System Picker Instead'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetGrid(bool isDark) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _assets.length,
      itemBuilder: (context, idx) {
        final asset = _assets[idx];
        return _buildAssetTile(asset, isDark);
      },
    );
  }

  Widget _buildAssetTile(AssetEntity asset, bool isDark) {
    final cachedPath = _assetIdToPath[asset.id];
    final isVideo = asset.type == AssetType.video;

    // Check selection state
    bool isSelected = false;
    int selectionIndex = 0;

    if (cachedPath != null) {
      if (isVideo) {
        isSelected = _selectedVideoPath == cachedPath;
      } else {
        isSelected = _selectedImagePaths.contains(cachedPath);
      }
      if (isSelected) {
        selectionIndex = _selectedMediaPaths.indexOf(cachedPath) + 1;
      }
    }

    return GestureDetector(
      key: Key('gallery_tile_${asset.id}'),
      onTap: () => _toggleAssetSelection(asset),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Thumbnail image
          _buildThumbnailWidget(asset),

          // 2. Selection highlight border
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.blueAccent : AppColors.lightPrimary,
                  width: 2.5,
                ),
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),

          // 3. Video duration indicator
          if (isVideo)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatDuration(asset.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Selection badge
          Positioned(
            top: 6,
            right: 6,
            child: isSelected
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blueAccent : AppColors.lightPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$selectionIndex',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailWidget(AssetEntity asset) {
    if (Get.testMode) {
      return Container(
        color: asset.type == AssetType.video ? Colors.blueGrey : Colors.grey,
        child: Center(
          child: Icon(
            asset.type == AssetType.video ? Icons.videocam : Icons.image,
            color: Colors.white30,
            size: 28,
          ),
        ),
      );
    }

    final cached = _thumbCache[asset.id];
    if (cached != null) {
      return Image.memory(cached, fit: BoxFit.cover);
    }

    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize.square(250), quality: 80),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _thumbCache[asset.id] = snapshot.data!;
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(color: const Color(0xFF1E2228));
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
