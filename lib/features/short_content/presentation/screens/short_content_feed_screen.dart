import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../shared/utils/current_user.dart';
import '../../../profile/presentation/utils/profile_navigation.dart';
import '../../domain/models/short_content_models.dart';
import '../bindings/short_content_binding.dart';
import '../controllers/short_content_controller.dart';
import '../widgets/short_content_video_player.dart';

class ShortContentFeedScreen extends StatefulWidget {
  const ShortContentFeedScreen({super.key});

  @override
  State<ShortContentFeedScreen> createState() => _ShortContentFeedScreenState();
}

class _ShortContentFeedScreenState extends State<ShortContentFeedScreen> {
  late final ShortContentController controller;
  late final PageController _pageController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ShortContentController>();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          'shortContent.title'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'shortContent.create'.tr,
            onPressed: _openCreate,
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
          ),
        ],
      ),
      body: Obx(() => _buildBody(context, colors)),
    );
  }

  Widget _buildBody(BuildContext context, AppSemanticColors colors) {
    final items = controller.items;
    if (controller.isLoading.value && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (controller.errorMessage.value != null && items.isEmpty) {
      return _stateView(
        icon: Icons.cloud_off_outlined,
        message: controller.errorMessage.value!,
        action: FilledButton(
          onPressed: controller.loadFeed,
          child: Text('common.retry'.tr),
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.growthAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.65),
            _stateView(
              icon: Icons.video_library_outlined,
              message: 'shortContent.empty'.tr,
            ),
          ],
        ),
      );
    }

    final maxIndex = items.length - 1;
    final safeActiveIndex = _activeIndex.clamp(0, maxIndex);
    if (safeActiveIndex != _activeIndex) {
      _activeIndex = safeActiveIndex;
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.growthAccent,
      notificationPredicate: (notification) =>
          notification.depth == 0 || notification.depth == 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: items.length,
              onPageChanged: _setActiveIndex,
              itemBuilder: (context, index) {
                final item = items[index];
                return _ShortContentItem(
                  item: item,
                  colors: colors,
                  isActive: index == safeActiveIndex,
                  controller: controller,
                  onShare: () => _share(item),
                  onDelete: () => _delete(item),
                );
              },
            ),
          ),
          if (controller.isLoadingMore.value)
            const Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.lg,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            ),
          if (controller.errorMessage.value != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: _OverlayMessage(
                message: controller.errorMessage.value!,
                color: AppColors.warning,
              ),
            ),
          if (controller.loadMoreErrorMessage.value != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
              child: _OverlayMessage(
                message: controller.loadMoreErrorMessage.value!,
                color: AppColors.warning,
                action: TextButton(
                  onPressed: controller.loadMore,
                  child: Text(
                    'common.retry'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (controller.actionErrorMessage.value != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: _OverlayMessage(
                message: controller.actionErrorMessage.value!,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical ||
        notification.metrics.viewportDimension <= 0) {
      return false;
    }

    final page =
        notification.metrics.pixels / notification.metrics.viewportDimension;
    final nextIndex = page.round().clamp(0, controller.items.length - 1);
    if (nextIndex != _activeIndex && mounted) {
      _setActiveIndex(nextIndex);
    }
    return false;
  }

  void _setActiveIndex(int index) {
    if (!mounted || index < 0 || index >= controller.items.length) return;
    if (_activeIndex == index) {
      _maybeLoadMore(index);
      return;
    }
    setState(() => _activeIndex = index);
    _maybeLoadMore(index);
  }

  void _maybeLoadMore(int index) {
    if (index >= controller.items.length - 2) {
      controller.loadMore();
    }
  }

  Future<void> _refresh() async {
    if (mounted && _activeIndex != 0) {
      setState(() => _activeIndex = 0);
    }
    if (_pageController.hasClients && _pageController.page != 0) {
      _pageController.jumpToPage(0);
    }
    await controller.refreshFeed();
  }

  Future<void> _openCreate() async {
    // Do not provide a concrete generic here. GetX returns a dynamic
    // GetPageRoute, and Flutter's Navigator rejects a Route<T> cast when the
    // route itself was created as Route<dynamic>.
    await Get.toNamed(AppRoutes.shortContentCreate);
    if (!mounted) return;

    // The create route may have a different route-scoped controller. Reload
    // from the backend so the feed uses the canonical media URL from the
    // server rather than a stale local item.
    await controller.refreshFeed();
    if (!mounted || controller.items.isEmpty) return;
    setState(() => _activeIndex = 0);
    if (_pageController.hasClients && _pageController.page != 0) {
      _pageController.jumpToPage(0);
    }
  }

  Future<void> _share(ShortContentModel item) async {
    final updated = await controller.share(item.shortContentId);
    if (!mounted || updated == null) return;

    final text = updated.shareText;
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppNotificationBanner.showSuccess(
      context: context,
      title: 'shortContent.share'.tr,
      message: 'shortContent.shareCopied'.tr,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _delete(ShortContentModel item) async {
    final confirmed = await AppDialog.confirm(
      title: 'shortContent.deleteConfirm'.trParams({
        'title': item.title.trim().isEmpty ? 'Short content' : item.title,
      }),
      confirmLabel: 'common.delete'.tr,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final deleted = await controller.delete(item.shortContentId);
    if (!mounted || !deleted) return;

    final nextIndex = controller.items.isEmpty
        ? 0
        : _activeIndex.clamp(0, controller.items.length - 1);
    setState(() => _activeIndex = nextIndex);
    if (_pageController.hasClients && controller.items.isNotEmpty) {
      _pageController.jumpToPage(nextIndex);
    }
    AppNotificationBanner.showSuccess(
      context: context,
      title: 'shortContent.delete'.tr,
      message: 'shortContent.deleteSuccess'.tr,
      icon: Icons.delete_outline,
    );
  }

  Widget _stateView({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white60, size: 50),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class ShortContentDetailScreen extends StatefulWidget {
  const ShortContentDetailScreen({super.key});

  @override
  State<ShortContentDetailScreen> createState() =>
      _ShortContentDetailScreenState();
}

class _ShortContentDetailScreenState extends State<ShortContentDetailScreen> {
  late final ShortContentController controller;
  String? _contentId;
  ShortContentModel? _loadedItem;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ShortContentController>(
      tag: ShortContentDetailBinding.tag,
    );
    final argument = Get.arguments;
    _contentId = argument?.toString().trim();
    unawaited(_load());
  }

  Future<void> _load() async {
    final id = _contentId;
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _loadErrorMessage();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final item = await controller.loadById(id);
    if (!mounted) return;
    setState(() {
      _loadedItem = item;
      _isLoading = false;
      _errorMessage = item == null
          ? controller.errorMessage.value ?? _loadErrorMessage()
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          'shortContent.title'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Obx(() {
        final item = _contentId == null
            ? _loadedItem
            : controller.itemById(_contentId!) ?? _loadedItem;
        if (_isLoading && item == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          );
        }
        if (item == null) {
          return _detailStateView(
            icon: Icons.cloud_off_outlined,
            message: _errorMessage ?? _loadErrorMessage(),
            action: FilledButton(
              onPressed: _load,
              child: Text('common.retry'.tr),
            ),
          );
        }

        return _ShortContentItem(
          item: item,
          colors: colors,
          isActive: true,
          controller: controller,
          onShare: () => _share(item),
          onDelete: () => _delete(item),
        );
      }),
    );
  }

  Future<void> _share(ShortContentModel item) async {
    final updated = await controller.share(item.shortContentId);
    if (!mounted || updated == null || updated.shareText.trim().isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: updated.shareText));
    if (!mounted) return;
    AppNotificationBanner.showSuccess(
      context: context,
      title: 'shortContent.share'.tr,
      message: 'shortContent.shareCopied'.tr,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _delete(ShortContentModel item) async {
    final confirmed = await AppDialog.confirm(
      title: 'shortContent.deleteConfirm'.trParams({
        'title': item.title.trim().isEmpty ? 'Short content' : item.title,
      }),
      confirmLabel: 'common.delete'.tr,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    if (await controller.delete(item.shortContentId) && mounted) {
      Get.back();
    }
  }

  Widget _detailStateView({
    required IconData icon,
    required String message,
    required Widget action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white60, size: 50),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.md),
            action,
          ],
        ),
      ),
    );
  }

  String _loadErrorMessage() {
    final translated = 'shortContent.loadFailed'.tr;
    return translated == 'shortContent.loadFailed'
        ? 'Unable to load this short content.'
        : translated;
  }
}

class _ShortContentItem extends StatelessWidget {
  const _ShortContentItem({
    required this.item,
    required this.colors,
    required this.isActive,
    required this.controller,
    required this.onShare,
    required this.onDelete,
  });

  final ShortContentModel item;
  final AppSemanticColors colors;
  final bool isActive;
  final ShortContentController controller;
  final VoidCallback onShare;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.hasVideo)
          ShortContentVideoPlayer(
            videoUrl: item.videoUrl!,
            thumbnailUrl: item.thumbnailUrl,
            isActive: isActive,
          )
        else
          _ShortContentImage(
            url: item.thumbnailUrl,
            errorMessage: 'shortContent.mediaError'.tr,
          ),
        const Positioned.fill(child: _ShortContentGradient()),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: _CreatorHeader(
            item: item,
            isDeleting: controller.isDeleting(item.shortContentId),
            onDelete: () => unawaited(onDelete()),
          ),
        ),
        Positioned(
          top: 68,
          right: AppSpacing.md,
          child: _CategoryChip(label: item.category, colors: colors),
        ),
        Positioned(
          right: AppSpacing.sm,
          bottom: 112,
          child: _ActionRail(
            item: item,
            controller: controller,
            onShare: onShare,
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: 84,
          bottom: AppSpacing.lg,
          child: SafeArea(top: false, child: _ContentDescription(item: item)),
        ),
      ],
    );
  }
}

class _CreatorHeader extends StatelessWidget {
  const _CreatorHeader({
    required this.item,
    required this.isDeleting,
    required this.onDelete,
  });

  final ShortContentModel item;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fullName = item.creatorFullName?.trim();
    final username = item.creatorUsername?.trim();
    final name = fullName == null || fullName.isEmpty
        ? username == null || username.isEmpty
              ? 'shortContent.creatorUnknown'.tr
              : username
        : fullName;
    final avatarUrl = item.creatorAvatarUrl?.trim();
    final currentUserId = CurrentUser.id.trim();
    final creatorId = item.creatorId?.trim();
    final isOwner =
        currentUserId.isNotEmpty &&
        creatorId != null &&
        creatorId.isNotEmpty &&
        currentUserId == creatorId;
    final canOpenProfile = (username != null && username.isNotEmpty) || isOwner;

    return Row(
      children: [
        GestureDetector(
          onTap: canOpenProfile
              ? () => unawaited(
                  ProfileNavigation.open(username: username, userId: creatorId),
                )
              : null,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                ? null
                : NetworkImage(avatarUrl),
            onBackgroundImageError: avatarUrl == null || avatarUrl.isEmpty
                ? null
                : (_, _) {},
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: canOpenProfile
                ? () => unawaited(
                    ProfileNavigation.open(
                      username: username,
                      userId: creatorId,
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (username != null && username.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isOwner)
          PopupMenuButton<String>(
            enabled: !isDeleting,
            tooltip: 'shortContent.more'.tr,
            icon: isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('common.delete'.tr),
              ),
            ],
          ),
      ],
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _ShortContentGradient extends StatelessWidget {
  const _ShortContentGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.28),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.82),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

class _ContentDescription extends StatelessWidget {
  const _ContentDescription({required this.item});

  final ShortContentModel item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.title.trim().isNotEmpty)
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        if (item.description.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.item,
    required this.controller,
    required this.onShare,
  });

  final ShortContentModel item;
  final ShortContentController controller;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final id = item.shortContentId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShortContentAction(
          icon: item.liked ? Icons.favorite_rounded : Icons.favorite_border,
          label: '${item.likeCount}',
          color: item.liked ? AppColors.likedAccent : Colors.white,
          loading: controller.isLiking(id),
          onPressed: () => controller.toggleLike(id),
        ),
        const SizedBox(height: AppSpacing.md),
        _ShortContentAction(
          icon: item.saved ? Icons.bookmark_rounded : Icons.bookmark_border,
          label: '${item.saveCount}',
          color: item.saved ? AppColors.growthAccent : Colors.white,
          loading: controller.isSaving(id),
          onPressed: () => controller.toggleSave(id),
        ),
        const SizedBox(height: AppSpacing.md),
        _ShortContentAction(
          icon: Icons.ios_share_rounded,
          label: '${item.shareCount}',
          color: Colors.white,
          loading: controller.isSharing(id),
          onPressed: onShare,
        ),
      ],
    );
  }
}

class _ShortContentAction extends StatelessWidget {
  const _ShortContentAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.black.withValues(alpha: 0.32),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: loading ? null : onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                    : Icon(icon, color: color, size: 26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.colors});

  final String? label;
  final AppSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final value = label?.trim();
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          value,
          style: TextStyle(
            color: colors.primaryText == Colors.white
                ? Colors.white
                : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ShortContentImage extends StatelessWidget {
  const _ShortContentImage({required this.url, required this.errorMessage});

  final String? url;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return _fallback(errorMessage);
    return Image.network(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(errorMessage),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const ColoredBox(color: Colors.black),
    );
  }

  Widget _fallback(String message) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          message == 'shortContent.mediaError'
              ? 'Unable to load media'
              : message,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _OverlayMessage extends StatelessWidget {
  const _OverlayMessage({
    required this.message,
    required this.color,
    this.action,
  });

  final String message;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
