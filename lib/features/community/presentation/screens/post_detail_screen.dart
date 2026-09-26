import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';
import '../widgets/post_card_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final CommunityPostModel? initialPost;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final CommunityController _controller;
  CommunityPostModel? _post;
  bool _isLoading = true;
  bool _isNotFound = false;
  bool _isForbidden = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CommunityController>()) {
      _controller = Get.find<CommunityController>();
    } else {
      _controller = Get.put(CommunityController());
    }

    if (widget.initialPost != null) {
      _post = widget.initialPost;
      _isLoading = false;
      _loadPost(background: true);
    } else {
      _loadPost(background: false);
    }
  }

  Future<void> _loadPost({bool background = false}) async {
    if (!background) {
      setState(() {
        _isLoading = true;
        _isNotFound = false;
        _isForbidden = false;
        _errorMessage = '';
      });
    }

    try {
      final fetched = await _controller.fetchPostDetails(widget.postId);
      if (mounted) {
        setState(() {
          _post = fetched;
          _isLoading = false;
          _isNotFound = fetched == null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e is AppError) {
          if (e.statusCode == 403 || e.errorCode == 'FORBIDDEN') {
            _isForbidden = true;
            _errorMessage = 'chat.contentUnavailable'.tr.isNotEmpty &&
                    'chat.contentUnavailable'.tr != 'chat.contentUnavailable'
                ? 'chat.contentUnavailable'.tr
                : 'Content unavailable';
          } else {
            _isNotFound = true;
            _errorMessage = 'chat.contentNoLongerAvailable'.tr.isNotEmpty &&
                    'chat.contentNoLongerAvailable'.tr !=
                        'chat.contentNoLongerAvailable'
                ? 'chat.contentNoLongerAvailable'.tr
                : 'This content is no longer available.';
          }
        } else {
          _isNotFound = true;
          _errorMessage = 'chat.contentNoLongerAvailable'.tr.isNotEmpty &&
                  'chat.contentNoLongerAvailable'.tr !=
                      'chat.contentNoLongerAvailable'
              ? 'chat.contentNoLongerAvailable'.tr
              : 'This content is no longer available.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : AppColors.lightBgPrimary,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 56,
        leading: Center(
          child: AppBackButton(
            size: 36.0,
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.back<void>();
              }
            },
          ),
        ),
        title: Text(
          'Post',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(context, isDark, textPrimary, textMuted),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.chatPrimary),
      );
    }

    if (_isForbidden) {
      return _buildUnavailableState(
        icon: Icons.lock_outline_rounded,
        title: _errorMessage.isNotEmpty ? _errorMessage : 'Content unavailable',
        subtitle: 'You do not have permission to view this content.',
        textPrimary: textPrimary,
        textMuted: textMuted,
        isDark: isDark,
      );
    }

    if (_isNotFound || _post == null) {
      return _buildUnavailableState(
        icon: Icons.search_off_rounded,
        title: _errorMessage.isNotEmpty
            ? _errorMessage
            : 'This content is no longer available.',
        subtitle: 'The original post may have been removed or deleted.',
        textPrimary: textPrimary,
        textMuted: textMuted,
        isDark: isDark,
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostCardWidget(
            key: ValueKey('post_detail_${_post!.id}'),
            post: _post!,
            controller: _controller,
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.chatPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
