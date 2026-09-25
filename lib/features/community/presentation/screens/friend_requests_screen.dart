import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../shared/utils/current_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/utils/profile_navigation.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';

typedef FriendRequestItem = FollowUserModel;

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({
    super.key,
    this.highlightUserId,
    this.repository,
    this.currentUserId,
  });

  final String? highlightUserId;
  final CommunityRepository? repository;
  final String? currentUserId;

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  late final CommunityRepository _repo;
  List<FollowUserModel> _followers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repo = widget.repository!;
    } else if (Get.isRegistered<CommunityRepository>()) {
      _repo = Get.find<CommunityRepository>();
    } else {
      final dio =
          Get.isRegistered<Dio>() ? Get.find<Dio>() : DioProvider.create();
      final remote = CommunityRemoteDataSource(dio: dio);
      _repo = CommunityRepositoryImpl(remoteDataSource: remote);
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = widget.currentUserId ??
          (CurrentUser.id.isNotEmpty
              ? CurrentUser.id
              : (Get.isRegistered<AuthController>()
                  ? Get.find<AuthController>().currentUser.value?.id ?? ''
                  : ''));

      if (currentUserId.isEmpty) {
        if (mounted) {
          setState(() {
            _followers = [];
            _isLoading = false;
          });
        }
        return;
      }

      final results = await Future.wait([
        _repo.getFollowers(currentUserId),
        _repo.getFollowing(currentUserId),
        _repo.getPendingFollowRequests(),
      ]);

      final followersList = results[0];
      final followingList = results[1];
      final pendingList = results[2];

      final followingIds = followingList.map((f) => f.userId).toSet();
      for (final f in followersList) {
        f.isFollowingBack = followingIds.contains(f.userId);
      }

      final seen = <String>{};
      final combined = <FollowUserModel>[];
      for (final item in [...pendingList, ...followersList]) {
        if (item.userId.isNotEmpty && seen.add(item.userId)) {
          combined.add(item);
        }
      }

      // If highlightUserId is provided, prioritize it to the top
      if (widget.highlightUserId != null &&
          widget.highlightUserId!.isNotEmpty) {
        final highlightIdx =
            combined.indexWhere((u) => u.userId == widget.highlightUserId);
        if (highlightIdx > 0) {
          final item = combined.removeAt(highlightIdx);
          combined.insert(0, item);
        }
      }

      if (mounted) {
        setState(() {
          _followers = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(FollowUserModel item) async {
    final willFollow = !item.isFollowingBack;
    setState(() {
      item.isFollowingBack = willFollow;
    });

    try {
      final success = willFollow
          ? await _repo.followUser(item.userId)
          : await _repo.unfollowUser(item.userId);

      if (!success) {
        setState(() {
          item.isFollowingBack = !willFollow;
        });
        if (mounted) {
          AppNotificationBanner.showError(
            context: context,
            title: 'common.error'.tr,
            message: 'common.requestFailed'.tr,
          );
        }
        return;
      }

      if (mounted) {
        if (willFollow) {
          AppNotificationBanner.showSuccess(
            context: context,
            title: 'friends.following'.tr,
            message:
                'friends.nowFollowing'.trParams({'name': item.fullName}),
          );
        } else {
          AppNotificationBanner.showInfo(
            context: context,
            title: 'friends.unfollowed'.trParams({'name': item.fullName}),
            message: '',
          );
        }
      }
    } catch (_) {
      setState(() {
        item.isFollowingBack = !willFollow;
      });
      if (mounted) {
        AppNotificationBanner.showError(
          context: context,
          title: 'common.error'.tr,
          message: 'common.requestFailed'.tr,
        );
      }
    }
  }

  void _removeFollower(FollowUserModel item) {
    setState(() {
      _followers.removeWhere((f) => f.userId == item.userId);
    });
    AppNotificationBanner.showInfo(
      context: context,
      title: 'friends.removedFollower'.trParams({'name': item.fullName}),
      message: '',
    );
  }

  Future<void> _acceptPendingRequest(FollowUserModel item) async {
    final ok = await _repo.acceptFollowRequest(item.userId);
    if (ok) {
      setState(() {
        final idx = _followers.indexWhere((f) => f.userId == item.userId);
        if (idx != -1) {
          _followers[idx] = FollowUserModel(
            userId: item.userId,
            fullName: item.fullName,
            username: item.username,
            avatarUrl: item.avatarUrl,
            status: 'ACCEPTED',
            isFollowingBack: false,
            followedAt: item.followedAt,
          );
        }
      });
      if (mounted) {
        AppNotificationBanner.showSuccess(
          context: context,
          title: 'friends.accepted'.tr,
          message: '',
        );
      }
    }
  }

  Future<void> _rejectPendingRequest(FollowUserModel item) async {
    final ok = await _repo.rejectFollowRequest(item.userId);
    if (ok) {
      setState(() {
        _followers.removeWhere((f) => f.userId == item.userId);
      });
      if (mounted) {
        AppNotificationBanner.showInfo(
          context: context,
          title: 'friends.declined'.tr,
          message: '',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final titleText = 'friends.followers'.tr.isNotEmpty &&
            'friends.followers'.tr != 'friends.followers'
        ? 'friends.followers'.tr
        : 'Followers';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 72,
        leading: const Center(child: AppBackButton()),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            if (_followers.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFE8E8E4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_followers.length}',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: borderSubtle),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _buildBody(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _followers.isEmpty) {
      return _buildErrorState(isDark);
    }

    if (_followers.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        itemCount: _followers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _followers[index];
          return _buildFollowerCard(context, item, isDark);
        },
      ),
    );
  }

  Widget _buildFollowerCard(
    BuildContext context,
    FollowUserModel item,
    bool isDark,
  ) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardBg =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
    final cardBorder =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5DF);

    final timeAgo = item.followedAt != null
        ? CommunityDateFormatter.format(item.followedAt)
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => ProfileNavigation.open(username: item.username),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                AppAvatar(
                  imageUrl: item.avatarUrl,
                  name: item.fullName,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${item.username}',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (timeAgo.isNotEmpty)
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                item.isFollowingBack
                    ? Icons.swap_horiz_rounded
                    : Icons.person_add_alt_1_outlined,
                size: 14,
                color: textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                item.status == 'PENDING'
                    ? 'friends.requests'.tr
                    : (item.isFollowingBack
                        ? 'friends.mutualFollow'.tr
                        : 'friends.followsYou'.tr),
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.status == 'PENDING')
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => _acceptPendingRequest(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF111111),
                        foregroundColor: isDark
                            ? const Color(0xFF111111)
                            : const Color(0xFFFFFFFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'friends.accept'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => _rejectPendingRequest(item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFD6D6D0),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'friends.decline'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 38,
                    child: item.isFollowingBack
                        ? OutlinedButton.icon(
                            onPressed: () => _toggleFollow(item),
                            icon: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: textSecondary,
                            ),
                            label: Text(
                              'friends.following'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFD6D6D0),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _toggleFollow(item),
                            icon: Icon(
                              Icons.person_add_rounded,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF111111)
                                  : const Color(0xFFFFFFFF),
                            ),
                            label: Text(
                              'friends.followBack'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF111111)
                                    : const Color(0xFFFFFFFF),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF111111),
                              foregroundColor: isDark
                                  ? const Color(0xFF111111)
                                  : const Color(0xFFFFFFFF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => _removeFollower(item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFD6D6D0),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'friends.remove'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary;

    final title = 'friends.noFollowers'.tr.isNotEmpty &&
            'friends.noFollowers'.tr != 'friends.noFollowers'
        ? 'friends.noFollowers'.tr
        : 'No followers yet';

    final desc = 'friends.noFollowersDesc'.tr.isNotEmpty &&
            'friends.noFollowersDesc'.tr != 'friends.noFollowersDesc'
        ? 'friends.noFollowersDesc'.tr
        : 'When people follow you, they will appear here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 52,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: textMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'common.error'.tr,
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'common.requestFailed'.tr,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF111111),
                foregroundColor: isDark
                    ? const Color(0xFF111111)
                    : const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('common.retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
