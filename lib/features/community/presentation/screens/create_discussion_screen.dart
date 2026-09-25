import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'widgets/author_row.dart';

class CreateDiscussionScreen extends StatefulWidget {
  final ForumTopicModel? initialDiscussion;

  const CreateDiscussionScreen({
    super.key,
    this.initialDiscussion,
  });

  bool get isEdit => initialDiscussion != null;

  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  bool _isSubmitting = false;
  String? _selectedCategory;
  bool _isAnonymous = false;

  static const List<String> _categoryKeys = [
    'Technology',
    'Campus Life',
    'Projects',
    'Study & Education',
    'Career',
    'Events',
  ];

  bool get _canPublish =>
      _selectedCategory != null &&
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  bool get _hasUnsavedChanges {
    final currentTitle = _titleController.text.trim();
    final currentContent = _contentController.text.trim();
    if (widget.isEdit) {
      final initialTitle = widget.initialDiscussion?.title.trim() ?? '';
      final initialContent = widget.initialDiscussion?.content.trim() ?? '';
      final initialCat = widget.initialDiscussion?.category;
      final initialAnon = widget.initialDiscussion?.isAnonymous ?? false;
      return currentTitle != initialTitle ||
          currentContent != initialContent ||
          _selectedCategory != initialCat ||
          _isAnonymous != initialAnon;
    }
    return currentTitle.isNotEmpty ||
        currentContent.isNotEmpty ||
        _selectedCategory != null ||
        _isAnonymous;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialDiscussion != null) {
      _titleController.text = widget.initialDiscussion!.title;
      _contentController.text = widget.initialDiscussion!.content;
      _selectedCategory = widget.initialDiscussion!.category;
      _isAnonymous = widget.initialDiscussion!.isAnonymous;
    }
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _onBackPress() async {
    if (_hasUnsavedChanges) {
      final title = 'community.discardChanges'.tr.isNotEmpty &&
              'community.discardChanges'.tr != 'community.discardChanges'
          ? 'community.discardChanges'.tr
          : ('community.discardDraft'.tr.isNotEmpty &&
                  'community.discardDraft'.tr != 'community.discardDraft'
              ? 'community.discardDraft'.tr
              : 'Discard Changes?');

      final message = 'community.discardChangesMsg'.tr.isNotEmpty &&
              'community.discardChangesMsg'.tr != 'community.discardChangesMsg'
          ? 'community.discardChangesMsg'.tr
          : ('community.discardMessage'.tr.isNotEmpty &&
                  'community.discardMessage'.tr != 'community.discardMessage'
              ? 'community.discardMessage'.tr
              : 'Your discussion has not been published yet.');

      final confirmed = await GenLinkConfirmDialog.showDiscard(
        context: context,
        title: title,
        message: message,
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

  void _showCategorySheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorderSubtle
                          : AppColors.lightBorderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'community.discussionCategory'.tr.isNotEmpty &&
                            'community.discussionCategory'.tr !=
                                'community.discussionCategory'
                        ? 'community.discussionCategory'.tr
                        : 'Category',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._categoryKeys.map((key) {
                  final isSelected = _selectedCategory == key;
                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = key);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: isSelected
                            ? BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceSecondary
                                    : AppColors.lightBgSecondary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: borderColor,
                                  width: 0.8,
                                ),
                              )
                            : null,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSelected ? textPrimary : textSecondary,
                                  width: isSelected ? 2.0 : 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: textPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                key.tr,
                                style: TextStyle(
                                  color: isSelected ? textPrimary : textSecondary,
                                  fontSize: 14.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                color: textPrimary,
                                size: 19,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_isSubmitting) return;

    if (_selectedCategory == null) {
      AppNotificationBanner.showError(
        context: context,
        title: 'community.discussionCategory'.tr,
        message: 'community.selectCategoryPrompt'.tr.isNotEmpty &&
                'community.selectCategoryPrompt'.tr !=
                    'community.selectCategoryPrompt'
            ? 'community.selectCategoryPrompt'.tr
            : 'Please select a category.',
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppNotificationBanner.showError(
        context: context,
        title: 'community.discussionTitle'.tr,
        message: 'community.enterTitlePrompt'.tr.isNotEmpty &&
                'community.enterTitlePrompt'.tr !=
                    'community.enterTitlePrompt'
            ? 'community.enterTitlePrompt'.tr
            : 'Please enter a title.',
      );
      return;
    }

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      AppNotificationBanner.showError(
        context: context,
        title: 'community.discussionContent'.tr,
        message: 'community.enterContentPrompt'.tr.isNotEmpty &&
                'community.enterContentPrompt'.tr !=
                    'community.enterContentPrompt'
            ? 'community.enterContentPrompt'.tr
            : 'Please enter discussion content.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final category = _selectedCategory!;

    try {
      final commController = Get.isRegistered<CommunityController>()
          ? Get.find<CommunityController>()
          : Get.put(CommunityController());

      if (widget.isEdit) {
        final success = await commController.updateDiscussion(
          discussionId: widget.initialDiscussion!.id,
          title: title,
          content: content,
          category: category,
          anonymous: _isAnonymous,
        );

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (success) {
          AppNotificationBanner.showSuccess(
            context: context,
            title: 'community.discussionUpdated'.tr.isNotEmpty &&
                    'community.discussionUpdated'.tr !=
                        'community.discussionUpdated'
                ? 'community.discussionUpdated'.tr
                : 'Discussion Updated',
            message: 'community.discussionUpdatedMsg'.tr.isNotEmpty &&
                    'community.discussionUpdatedMsg'.tr !=
                        'community.discussionUpdatedMsg'
                ? 'community.discussionUpdatedMsg'.tr
                : 'Your discussion changes have been saved.',
          );
          Navigator.pop(context, true);
        } else {
          AppNotificationBanner.showError(
            context: context,
            title: 'Error',
            message: 'community.couldNotUpdateDiscussion'.tr.isNotEmpty &&
                    'community.couldNotUpdateDiscussion'.tr !=
                        'community.couldNotUpdateDiscussion'
                ? 'community.couldNotUpdateDiscussion'.tr
                : "Couldn't update your discussion. Please check your connection and try again.",
          );
        }
      } else {
        await commController.addDiscussion(
          title: title,
          content: content,
          category: category,
          anonymous: _isAnonymous,
        );

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        AppNotificationBanner.showSuccess(
          context: context,
          title: 'community.discussionPublished'.tr.isNotEmpty &&
                  'community.discussionPublished'.tr !=
                      'community.discussionPublished'
              ? 'community.discussionPublished'.tr
              : 'Discussion Published',
          message: 'community.discussionPublishedMsg'.tr.isNotEmpty &&
                  'community.discussionPublishedMsg'.tr !=
                      'community.discussionPublishedMsg'
              ? 'community.discussionPublishedMsg'.tr
              : 'Your discussion is now live in the Forum.',
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppNotificationBanner.showError(
        context: context,
        title: 'Error',
        message: widget.isEdit
            ? ('community.couldNotUpdateDiscussion'.tr.isNotEmpty &&
                    'community.couldNotUpdateDiscussion'.tr !=
                        'community.couldNotUpdateDiscussion'
                ? 'community.couldNotUpdateDiscussion'.tr
                : "Couldn't update your discussion. Please check your connection and try again.")
            : ('community.couldNotPublishDiscussion'.tr.isNotEmpty &&
                    'community.couldNotPublishDiscussion'.tr !=
                        'community.couldNotPublishDiscussion'
                ? 'community.couldNotPublishDiscussion'.tr
                : "Couldn't publish your discussion. Please check your connection and try again."),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardBorder =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final inputBg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    final charCount = _contentController.text.length;
    const maxChars = 5000;

    final screenTitle = widget.isEdit
        ? ('community.editDiscussion'.tr.isNotEmpty &&
                'community.editDiscussion'.tr != 'community.editDiscussion'
            ? 'community.editDiscussion'.tr
            : 'Edit Discussion')
        : ('community.createDiscussion'.tr.isNotEmpty &&
                'community.createDiscussion'.tr != 'community.createDiscussion'
            ? 'community.createDiscussion'.tr
            : 'Create Discussion');

    final actionButtonText = widget.isEdit
        ? ('community.saveChanges'.tr.isNotEmpty &&
                'community.saveChanges'.tr != 'community.saveChanges'
            ? 'community.saveChanges'.tr
            : 'Save Changes')
        : ('community.publishDiscussion'.tr.isNotEmpty &&
                'community.publishDiscussion'.tr !=
                    'community.publishDiscussion'
            ? 'community.publishDiscussion'.tr
            : 'Publish');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPress();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 52,
          leading: IconButton(
            icon: Icon(Icons.close, color: textPrimary, size: 24),
            tooltip: 'common.back'.tr,
            onPressed: _onBackPress,
          ),
          titleSpacing: 0,
          title: Text(
            screenTitle,
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                right: 14,
                top: 10,
                bottom: 10,
              ),
              child: ElevatedButton(
                onPressed: _canPublish && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canPublish
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)
                      : (isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightBgSecondary),
                  disabledBackgroundColor: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightBgSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark
                              ? AppColors.darkTextInverse
                              : AppColors.lightTextInverse,
                        ),
                      )
                    : Text(
                        actionButtonText,
                        style: TextStyle(
                          color: _canPublish
                              ? (isDark
                                  ? AppColors.darkTextInverse
                                  : AppColors.lightTextInverse)
                              : (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: cardBorder),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthorRow(
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                isAnonymous: _isAnonymous,
              ),
              const SizedBox(height: 20),

              Text(
                'community.discussionCategory'.tr.isNotEmpty &&
                        'community.discussionCategory'.tr !=
                            'community.discussionCategory'
                    ? 'community.discussionCategory'.tr
                    : 'Category',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showCategorySheet,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: cardBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategory != null
                              ? _selectedCategory!.tr
                              : ('community.selectCategory'.tr.isNotEmpty &&
                                      'community.selectCategory'.tr !=
                                          'community.selectCategory'
                                  ? 'community.selectCategory'.tr
                                  : 'Select a category'),
                          style: TextStyle(
                            color: _selectedCategory != null
                                ? textPrimary
                                : textMuted,
                            fontSize: 15,
                            fontWeight: _selectedCategory != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(Icons.expand_more, color: textMuted, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'community.discussionTitle'.tr.isNotEmpty &&
                        'community.discussionTitle'.tr !=
                            'community.discussionTitle'
                    ? 'community.discussionTitle'.tr
                    : 'Title',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                minLines: 1,
                maxLines: 3,
                maxLength: 150,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  hintText: 'community.discussionTitleHint'.tr.isNotEmpty &&
                          'community.discussionTitleHint'.tr !=
                              'community.discussionTitleHint'
                      ? 'community.discussionTitleHint'.tr
                      : 'What do you want to talk about?',
                  hintStyle: TextStyle(
                    color: textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: textPrimary, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _contentFocus.requestFocus(),
              ),

              const SizedBox(height: 20),

              Text(
                'community.discussionContent'.tr.isNotEmpty &&
                        'community.discussionContent'.tr !=
                            'community.discussionContent'
                    ? 'community.discussionContent'.tr
                    : 'Content',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                focusNode: _contentFocus,
                minLines: 4,
                maxLines: null,
                maxLength: maxChars,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'community.discussionContentHint'.tr.isNotEmpty &&
                          'community.discussionContentHint'.tr !=
                              'community.discussionContentHint'
                      ? 'community.discussionContentHint'.tr
                      : 'Share your thoughts, question, or idea...',
                  hintStyle: TextStyle(
                    color: textMuted,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: textPrimary, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),

              if (charCount > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$charCount / $maxChars',
                      style: TextStyle(
                        color: charCount >= maxChars
                            ? AppColors.danger
                            : (charCount >= 4800
                                ? AppColors.warning
                                : textMuted),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              Text(
                'community.anonymousQuestion'.tr.isNotEmpty &&
                        'community.anonymousQuestion'.tr !=
                            'community.anonymousQuestion'
                    ? 'community.anonymousQuestion'.tr
                    : 'Anonymous?',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),

              _buildIdentityOption(
                key: const Key('create_discussion_show_profile_option'),
                isSelected: !_isAnonymous,
                icon: Icons.account_circle_outlined,
                title: 'community.showProfile'.tr.isNotEmpty &&
                        'community.showProfile'.tr != 'community.showProfile'
                    ? 'community.showProfile'.tr
                    : 'Show User Profile',
                subtitle: 'community.showProfileDesc'.tr.isNotEmpty &&
                        'community.showProfileDesc'.tr !=
                            'community.showProfileDesc'
                    ? 'community.showProfileDesc'.tr
                    : 'Post publicly with your name and avatar',
                onTap: () {
                  if (_isAnonymous) {
                    setState(() => _isAnonymous = false);
                  }
                },
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBorder: cardBorder,
                inputBg: inputBg,
              ),
              const SizedBox(height: 10),

              _buildIdentityOption(
                key: const Key('create_discussion_hide_identity_option'),
                isSelected: _isAnonymous,
                icon: Icons.visibility_off_outlined,
                title: 'community.hideIdentity'.tr.isNotEmpty &&
                        'community.hideIdentity'.tr != 'community.hideIdentity'
                    ? 'community.hideIdentity'.tr
                    : 'Hide User Identity',
                subtitle: 'community.hideIdentityDesc'.tr.isNotEmpty &&
                        'community.hideIdentityDesc'.tr !=
                            'community.hideIdentityDesc'
                    ? 'community.hideIdentityDesc'.tr
                    : 'Post anonymously without showing your profile',
                onTap: () {
                  if (!_isAnonymous) {
                    setState(() => _isAnonymous = true);
                  }
                },
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBorder: cardBorder,
                inputBg: inputBg,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityOption({
    required Key key,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
    required Color inputBg,
  }) {
    final activeColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.lightBgSecondary)
                : inputBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? activeColor : cardBorder,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.15)
                      : (isDark
                          ? AppColors.darkBgSecondary
                          : AppColors.lightBgSecondary),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? activeColor : cardBorder,
                    width: 1.8,
                  ),
                  color: isSelected ? activeColor : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

