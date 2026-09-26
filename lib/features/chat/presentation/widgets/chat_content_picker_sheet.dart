import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/config/app_config.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../community/domain/models/community_post_model.dart';
import '../../../community/presentation/controllers/community_controller.dart';
import '../../domain/models/chat_models.dart';
import '../bindings/chat_binding.dart';
import '../controllers/chat_controller.dart';

class ChatContentPickerSheet extends StatefulWidget {
  final SharedContentType type;
  final ValueChanged<SharedContentModel> onSelected;

  const ChatContentPickerSheet({
    super.key,
    required this.type,
    required this.onSelected,
  });

  static void show(
    BuildContext context, {
    required SharedContentType type,
    required ValueChanged<SharedContentModel> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatContentPickerSheet(
        type: type,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<ChatContentPickerSheet> createState() => _ChatContentPickerSheetState();
}

class _ChatContentPickerSheetState extends State<ChatContentPickerSheet> {
  late final CommunityController _communityController;
  late final ChatController _chatController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CommunityController>()) {
      _communityController = Get.find<CommunityController>();
    } else {
      _communityController = Get.put(CommunityController());
    }

    if (Get.isRegistered<ChatController>()) {
      _chatController = Get.find<ChatController>();
    } else {
      ChatBinding().dependencies();
      _chatController = Get.find<ChatController>();
    }

    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.type == SharedContentType.post &&
        _communityController.posts.isEmpty) {
      setState(() => _isLoading = true);
      try {
        await _communityController.fetchPosts();
      } catch (_) {}
      if (mounted) setState(() => _isLoading = false);
    } else if (widget.type == SharedContentType.event &&
        _communityController.events.isEmpty) {
      setState(() => _isLoading = true);
      try {
        await _communityController.fetchEvents();
      } catch (_) {}
      if (mounted) setState(() => _isLoading = false);
    } else if (widget.type == SharedContentType.discussion &&
        _communityController.discussions.isEmpty) {
      setState(() => _isLoading = true);
      try {
        await _communityController.fetchDiscussions();
      } catch (_) {}
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Share ${widget.type.label}',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSubtle),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search ${widget.type.label.toLowerCase()}s...',
                        hintStyle: TextStyle(color: textMuted, fontSize: 14),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.chatPrimary),
                  )
                : _buildContentList(isDark, textPrimary, textMuted, borderSubtle),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderSubtle,
  ) {
    switch (widget.type) {
      case SharedContentType.post:
        return _buildPostsList(isDark, textPrimary, textMuted, borderSubtle);
      case SharedContentType.discussion:
        return _buildDiscussionsList(isDark, textPrimary, textMuted, borderSubtle);
      case SharedContentType.event:
        return _buildEventsList(isDark, textPrimary, textMuted, borderSubtle);
      case SharedContentType.profile:
        return _buildProfilesList(isDark, textPrimary, textMuted, borderSubtle);
    }
  }

  static String _resolveUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (trimmed.contains('.cdn.digitaloceanspaces.com')) {
        return trimmed.replaceFirst('.cdn.digitaloceanspaces.com', '.digitaloceanspaces.com');
      }
      return trimmed;
    }
    if (trimmed.startsWith('assets/')) return trimmed;
    final clean = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '${AppConfig.apiBaseUrl}$clean';
  }

  static String? _resolvePostThumbnail(CommunityPostModel post) {
    if (post.imageUrls.isNotEmpty) {
      final img = post.imageUrls.firstWhere(
        (u) => !CommunityPostModel.isVideoUrl(u),
        orElse: () => '',
      );
      if (img.isNotEmpty) return img;
    }
    if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) {
      final img = post.mediaUrls!.firstWhere(
        (u) => !CommunityPostModel.isVideoUrl(u),
        orElse: () => '',
      );
      if (img.isNotEmpty) return img;
    }
    return null;
  }

  static bool _isPostVideo(CommunityPostModel post) {
    if (post.isVideoPost) return true;
    if (post.videoUrl != null && post.videoUrl!.trim().isNotEmpty) return true;
    if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) {
      return post.mediaUrls!.any((u) => CommunityPostModel.isVideoUrl(u));
    }
    return false;
  }

  Widget _buildFallbackTile({required IconData icon, required bool isDark}) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.chatPrimary.withValues(alpha: 0.15),
      child: Icon(icon, color: AppColors.chatPrimary, size: 22),
    );
  }

  Widget _buildPostThumbnail(CommunityPostModel post, bool isDark) {
    final imageUrl = _resolvePostThumbnail(post);
    final isVideo = _isPostVideo(post);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final resolved = _resolveUrl(imageUrl);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: resolved.startsWith('assets/')
              ? Image.asset(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildFallbackTile(
                    icon: isVideo ? Icons.videocam_rounded : Icons.article_rounded,
                    isDark: isDark,
                  ),
                )
              : Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildFallbackTile(
                    icon: isVideo ? Icons.videocam_rounded : Icons.article_rounded,
                    isDark: isDark,
                  ),
                ),
        ),
      );
    }

    if (isVideo) {
      return _buildFallbackTile(
        icon: Icons.videocam_rounded,
        isDark: isDark,
      );
    }

    return _buildFallbackTile(
      icon: Icons.article_rounded,
      isDark: isDark,
    );
  }

  Widget _buildPostsList(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderSubtle,
  ) {
    return Obx(() {
      final allPosts = _communityController.posts;
      final filtered = _searchQuery.isEmpty
          ? allPosts
          : allPosts
              .where((p) =>
                  p.content.toLowerCase().contains(_searchQuery) ||
                  p.authorName.toLowerCase().contains(_searchQuery))
              .toList();

      if (filtered.isEmpty) {
        return _buildEmptyState('No posts found', textMuted);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: borderSubtle),
        itemBuilder: (ctx, i) {
          final post = filtered[i];
          final firstLine = post.content.trim().split('\n').first.trim();
          final title = firstLine.isNotEmpty
              ? (firstLine.length > 55 ? '${firstLine.substring(0, 52)}...' : firstLine)
              : 'Post by ${post.authorName}';
          final imageUrl = _resolvePostThumbnail(post);
          final isVideo = _isPostVideo(post);
          final thumb = imageUrl ?? (isVideo ? (post.videoUrl ?? post.mediaUrls?.first) : null);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: _buildPostThumbnail(post, isDark),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${post.authorName} • ${post.timeAgo}',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.chatPrimary),
            onTap: () {
              Navigator.of(context).pop();
              widget.onSelected(
                SharedContentModel(
                  type: SharedContentType.post,
                  id: post.id,
                  title: title,
                  previewText: post.content.trim(),
                  thumbnailUrl: thumb,
                  authorName: post.authorName,
                  authorAvatar: post.authorAvatar,
                  subtitle: post.community.isNotEmpty ? post.community : null,
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildDiscussionsList(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderSubtle,
  ) {
    return Obx(() {
      final allDiscussions = _communityController.discussions;
      final filtered = _searchQuery.isEmpty
          ? allDiscussions
          : allDiscussions
              .where((d) =>
                  d.title.toLowerCase().contains(_searchQuery) ||
                  d.authorName.toLowerCase().contains(_searchQuery))
              .toList();

      if (filtered.isEmpty) {
        return _buildEmptyState('No discussions found', textMuted);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: borderSubtle),
        itemBuilder: (ctx, i) {
          final topic = filtered[i];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.chatPrimary.withValues(alpha: 0.15),
              child: const Icon(Icons.forum_rounded, color: AppColors.chatPrimary, size: 22),
            ),
            title: Text(
              topic.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${topic.authorName} • ${topic.category}',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.chatPrimary),
            onTap: () {
              Navigator.of(context).pop();
              widget.onSelected(
                SharedContentModel(
                  type: SharedContentType.discussion,
                  id: topic.id,
                  title: topic.title.trim(),
                  previewText: topic.content.trim(),
                  authorName: topic.authorName,
                  authorAvatar: topic.authorAvatar,
                  subtitle: topic.category.isNotEmpty ? topic.category : null,
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildEventsList(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderSubtle,
  ) {
    return Obx(() {
      final allEvents = _communityController.events;
      final filtered = _searchQuery.isEmpty
          ? allEvents
          : allEvents
              .where((e) =>
                  e.title.toLowerCase().contains(_searchQuery) ||
                  e.organizerName.toLowerCase().contains(_searchQuery))
              .toList();

      if (filtered.isEmpty) {
        return _buildEmptyState('No events found', textMuted);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: borderSubtle),
        itemBuilder: (ctx, i) {
          final event = filtered[i];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: () {
              if (event.imageUrl.isEmpty) {
                return _buildFallbackTile(icon: Icons.event_rounded, isDark: isDark);
              }
              final resolved = _resolveUrl(event.imageUrl);
              if (resolved.isEmpty) {
                return _buildFallbackTile(icon: Icons.event_rounded, isDark: isDark);
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: resolved.startsWith('assets/')
                      ? Image.asset(
                          resolved,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildFallbackTile(
                            icon: Icons.event_rounded,
                            isDark: isDark,
                          ),
                        )
                      : Image.network(
                          resolved,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildFallbackTile(
                            icon: Icons.event_rounded,
                            isDark: isDark,
                          ),
                        ),
                ),
              );
            }(),
            title: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${event.organizerName} • ${event.dateString}',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.chatPrimary),
            onTap: () {
              Navigator.of(context).pop();
              widget.onSelected(
                SharedContentModel(
                  type: SharedContentType.event,
                  id: event.id,
                  title: event.title.trim(),
                  previewText: event.description.trim(),
                  thumbnailUrl: event.imageUrl,
                  authorName: event.organizerName,
                  subtitle: event.location.isNotEmpty ? event.location : event.dateString,
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildProfilesList(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderSubtle,
  ) {
    return Obx(() {
      final conversations = _chatController.conversations
          .where((c) => !c.isGroup && c.name.isNotEmpty)
          .toList();

      final filtered = _searchQuery.isEmpty
          ? conversations
          : conversations
              .where((c) => c.name.toLowerCase().contains(_searchQuery))
              .toList();

      if (filtered.isEmpty) {
        return _buildEmptyState('No profiles found', textMuted);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: borderSubtle),
        itemBuilder: (ctx, i) {
          final conv = filtered[i];

          Widget fallbackProfileAvatar() {
            return CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.chatPrimary.withValues(alpha: 0.15),
              child: Text(
                conv.name.isNotEmpty ? conv.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.chatPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          }

          final resolvedAvatar = _resolveUrl(conv.avatar);
          final hasValidAvatar = resolvedAvatar.isNotEmpty && !resolvedAvatar.contains('user_profile.png');

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: hasValidAvatar
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: resolvedAvatar.startsWith('assets/')
                          ? Image.asset(
                              resolvedAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => fallbackProfileAvatar(),
                            )
                          : Image.network(
                              resolvedAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => fallbackProfileAvatar(),
                            ),
                    ),
                  )
                : fallbackProfileAvatar(),
            title: Text(
              conv.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '@${conv.name.toLowerCase().replaceAll(' ', '')}',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.chatPrimary),
            onTap: () {
              Navigator.of(context).pop();
              final username = conv.name.toLowerCase().replaceAll(' ', '');
              widget.onSelected(
                SharedContentModel(
                  type: SharedContentType.profile,
                  id: conv.id,
                  title: conv.name,
                  subtitle: '@$username',
                  thumbnailUrl: conv.avatar,
                  authorName: conv.name,
                  authorAvatar: conv.avatar,
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildEmptyState(String text, Color textMuted) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
