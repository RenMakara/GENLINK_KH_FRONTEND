import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'widgets/author_row.dart';

/// Create / Edit Discussion Screen — Forum tab creation & editing flow.
///
/// Production-ready, theme-aware, Khmer/English typography friendly.
/// Fields: Author identity, Category selector, Title, Auto-expanding Content, Character counter.
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
      return currentTitle != initialTitle ||
          currentContent != initialContent ||
          _selectedCategory != initialCat;
    }
    return currentTitle.isNotEmpty ||
        currentContent.isNotEmpty ||
        _selectedCategory != null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialDiscussion != null) {
      _titleController.text = widget.initialDiscussion!.title;
      _contentController.text = widget.initialDiscussion!.content;
      _selectedCategory = widget.initialDiscussion!.category;
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

  void _onBackPress() {
    if (_hasUnsavedChanges) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dialogBg = isDark ? const Color(0xFF1E2228) : Colors.white;
      final textPrimary =
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
      final textSecondary =
          isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'community.discardChanges'.tr.isNotEmpty &&
                    'community.discardChanges'.tr != 'community.discardChanges'
                ? 'community.discardChanges'.tr
                : ('community.discardDraft'.tr.isNotEmpty &&
                        'community.discardDraft'.tr != 'community.discardDraft'
                    ? 'community.discardDraft'.tr
                    : 'Discard changes?'),
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'community.discardChangesMsg'.tr.isNotEmpty &&
                    'community.discardChangesMsg'.tr !=
                        'community.discardChangesMsg'
                ? 'community.discardChangesMsg'.tr
                : ('community.discardMessage'.tr.isNotEmpty &&
                        'community.discardMessage'.tr !=
                            'community.discardMessage'
                    ? 'community.discardMessage'.tr
                    : 'Your discussion has not been published yet.'),
            style: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'community.keepEditing'.tr.isNotEmpty &&
                        'community.keepEditing'.tr != 'community.keepEditing'
                    ? 'community.keepEditing'.tr
                    : 'Keep Editing',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'community.discard'.tr.isNotEmpty &&
                        'community.discard'.tr != 'community.discard'
                    ? 'community.discard'.tr
                    : 'Discard',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showCategorySheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161B22) : Colors.white;
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
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
                const SizedBox(height: 14),
                ..._categoryKeys.map((key) {
                  final isSelected = _selectedCategory == key;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedCategory = key);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? textPrimary : textSecondary,
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              key.tr,
                              style: TextStyle(
                                color: isSelected ? textPrimary : textSecondary,
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
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
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;

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
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark
                            ? const Color(0xFF222222)
                            : const Color(0xFFE2E8F0)),
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF222222)
                      : const Color(0xFFE2E8F0),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(
                        actionButtonText,
                        style: TextStyle(
                          color: _canPublish
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white30 : Colors.black38),
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
              // ── Author identity row ────────────────────────────────────
              AuthorRow(
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 20),

              // ── Category Selector ──────────────────────────────────────
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
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

              // ── Title ──────────────────────────────────────────────────
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
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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

              // ── Content ────────────────────────────────────────────────
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
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textPrimary, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),

              // ── Character counter ──────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$charCount / $maxChars',
                    style: TextStyle(
                      color: charCount >= maxChars
                          ? Colors.redAccent
                          : (charCount >= 4800
                              ? Colors.orangeAccent
                              : textMuted),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

