import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';

class ForumLikedBySheet extends StatefulWidget {
  final String discussionId;
  final List<ForumLikerModel> initialLikers;

  const ForumLikedBySheet({
    super.key,
    required this.discussionId,
    this.initialLikers = const [],
  });

  static void show(
    BuildContext context, {
    required String discussionId,
    List<ForumLikerModel> initialLikers = const [],
    bool isOwner = true,
  }) {
    if (!isOwner || discussionId.trim().isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForumLikedBySheet(
        discussionId: discussionId,
        initialLikers: initialLikers,
      ),
    );
  }

  @override
  State<ForumLikedBySheet> createState() => _ForumLikedBySheetState();
}

class _ForumLikedBySheetState extends State<ForumLikedBySheet> {
  late final CommunityController _controller;
  final ScrollController _scrollController = ScrollController();
  List<ForumLikerModel> _likers = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CommunityController>()) {
      _controller = Get.find<CommunityController>();
    } else {
      _controller = Get.put(CommunityController());
    }

    final cached = _controller.discussionLikers[widget.discussionId];
    if (cached != null && cached.isNotEmpty) {
      _likers = List<ForumLikerModel>.from(cached);
    } else if (widget.initialLikers.isNotEmpty) {
      _likers = List<ForumLikerModel>.from(widget.initialLikers);
    } else {
      _likers = [];
    }

    _scrollController.addListener(_onScroll);
    _loadLikers();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 40 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading &&
        !_hasError) {
      _loadMore();
    }
  }

  Future<void> _loadLikers() async {
    setState(() {
      _isLoading = _likers.isEmpty;
      _hasError = false;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final fetched = await _controller.fetchDiscussionLikers(
        widget.discussionId,
        page: 0,
      );
      if (mounted) {
        setState(() {
          _likers = fetched;
          _isLoading = false;
          _hasError = false;
          _hasMore = fetched.length >= 20;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final more = await _controller.fetchDiscussionLikers(
        widget.discussionId,
        page: nextPage,
      );
      if (mounted) {
        setState(() {
          if (more.isEmpty) {
            _hasMore = false;
          } else {
            _currentPage = nextPage;
            for (final liker in more) {
              if (!_likers.any((l) => l.id == liker.id)) {
                _likers.add(liker);
              }
            }
            _hasMore = more.length >= 20;
          }
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final title = 'community.likedBy'.tr.isNotEmpty &&
            'community.likedBy'.tr != 'community.likedBy'
        ? 'community.likedBy'.tr
        : 'Liked by';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    key: const Key('close_liked_by_sheet'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: borderSubtle, height: 1),
            // Content
            Flexible(
              child: _buildBody(isDark, textPrimary, textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color textPrimary, Color textSecondary) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.communityAccent,
          ),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: textSecondary, size: 36),
              const SizedBox(height: 10),
              Text(
                'Failed to load likes',
                style: TextStyle(color: textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                key: const Key('retry_load_likers_button'),
                onPressed: _loadLikers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  foregroundColor: isDark
                      ? AppColors.darkTextInverse
                      : AppColors.lightTextInverse,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: Text(
                  'common.retry'.tr.isNotEmpty &&
                          'common.retry'.tr != 'common.retry'
                      ? 'common.retry'.tr
                      : 'Retry',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_likers.isEmpty) {
      final emptyText = 'community.noLikesYet'.tr.isNotEmpty &&
              'community.noLikesYet'.tr != 'community.noLikesYet'
          ? 'community.noLikesYet'.tr
          : 'No likes yet';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: textSecondary.withValues(alpha: 0.4),
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                emptyText,
                style: TextStyle(color: textSecondary, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _likers.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _likers.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.communityAccent,
                ),
              ),
            ),
          );
        }

        final liker = _likers[index];
        final hasAvatar = liker.avatarUrl.isNotEmpty &&
            !liker.avatarUrl.contains('default_avatar');

        return ListTile(
          key: Key('liker_tile_${liker.id}'),
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: CircleAvatar(
            radius: 18,
            backgroundImage: hasAvatar
                ? (liker.avatarUrl.startsWith('assets/')
                    ? AssetImage(liker.avatarUrl) as ImageProvider
                    : NetworkImage(liker.avatarUrl))
                : null,
            backgroundColor:
                AppColors.communityAccent.withValues(alpha: 0.15),
            child: !hasAvatar
                ? Text(
                    liker.fullName.isNotEmpty
                        ? (liker.fullName.startsWith('@') &&
                                liker.fullName.length > 1
                            ? liker.fullName.substring(1, 2).toUpperCase()
                            : liker.fullName.substring(0, 1).toUpperCase())
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.communityAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
          title: Text(
            liker.fullName,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            liker.username,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
