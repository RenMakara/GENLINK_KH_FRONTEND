import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../shared/utils/current_user.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';

class CreatePostScreen extends StatefulWidget {
  final CommunityPostModel? initialPost;

  const CreatePostScreen({super.key, this.initialPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  String _selectedAudience = 'Public';
  List<String> _attachedImages = [];
  String? _selectedEventDate;

  // Poll state
  String? _pollQuestion;
  List<String> _pollOptionsList = [];
  final String _pollDuration = '3 Days';

  // Link state
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
      _selectedEventDate = widget.initialPost!.location;
      _attachedLink = widget.initialPost!.linkUrl;
      _linkTitle = widget.initialPost!.linkPreviewTitle;
      _linkDomain = widget.initialPost!.linkPreviewDomain;
      _pollQuestion = widget.initialPost!.pollQuestion;
      if (widget.initialPost!.pollOptions != null) {
        _pollOptionsList = widget.initialPost!.pollOptions!.map((o) => o.text).toList();
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
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickGalleryImages() async {
    try {
      final List<XFile> selected = await _picker.pickMultiImage();
      if (selected.isNotEmpty) {
        setState(() {
          _attachedImages.addAll(selected.map((e) => e.path));
        });
      }
    } catch (_) {}
  }

  void _removeImageAt(int index) {
    if (index >= 0 && index < _attachedImages.length) {
      setState(() {
        _attachedImages.removeAt(index);
      });
    }
  }

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final textSelection = _textController.selection;
    if (textSelection.isValid && textSelection.start >= 0) {
      final newText = text.replaceRange(textSelection.start, textSelection.end, emoji);
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: textSelection.start + emoji.length),
      );
    } else {
      _textController.text = text + emoji;
    }
  }

  void _insertHashtag() {
    final text = _textController.text;
    final textSelection = _textController.selection;
    if (textSelection.isValid && textSelection.start >= 0) {
      final newText = text.replaceRange(textSelection.start, textSelection.end, "#");
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: textSelection.start + 1),
      );
    } else {
      _textController.text = "$text#";
    }
    _editorFocusNode.requestFocus();
  }

  void _insertMention() {
    final text = _textController.text;
    final textSelection = _textController.selection;
    if (textSelection.isValid && textSelection.start >= 0) {
      final newText = text.replaceRange(textSelection.start, textSelection.end, "@");
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: textSelection.start + 1),
      );
    } else {
      _textController.text = "$text@";
    }
    _editorFocusNode.requestFocus();
  }

  void _showEmojiPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161616) : Colors.white;
    final emojis = ['🔥', '✨', '👏', '💡', '🎓', '🎉', '🚀', '❤️', '🤝', '🇰🇭'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: isDark ? const Color(0xFF282828) : Colors.black12, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: emojis.map((e) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _insertEmoji(e);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedEventDate = "Event on ${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _showAudiencePickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final surface = isDark ? const Color(0xFF161616) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242424) : Colors.black12;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: borderColor),
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
              'community.whoCanSee'.tr,
              style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...['Public', 'Friends', 'Only Me'].map((aud) {
              final isSelected = _selectedAudience == aud;
              final labelKey = aud == 'Public'
                  ? 'community.anyone'
                  : (aud == 'Friends' ? 'community.friendsOnly' : 'community.onlyMe');
              final icon = aud == 'Public'
                  ? Icons.public
                  : (aud == 'Friends' ? Icons.group_outlined : Icons.lock_outline);
              return ListTile(
                leading: Icon(icon, color: isSelected ? textPrimary : textSecondary),
                title: Text(
                  labelKey.tr,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check, color: textPrimary) : null,
                onTap: () {
                  setState(() {
                    _selectedAudience = aud;
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddContentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF141414) : Colors.white;
    final circleBg = isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0);
    final iconColor = isDark ? Colors.white : Colors.black87;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? const Color(0xFF282828) : Colors.black12;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'community.addToYourPost'.tr,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContentOption(
                  icon: Icons.image_outlined,
                  label: 'community.media'.tr,
                  circleBg: circleBg,
                  iconColor: iconColor,
                  textColor: textPrimary,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickGalleryImages();
                  },
                ),
                _buildContentOption(
                  icon: Icons.calendar_month_outlined,
                  label: 'community.event'.tr,
                  circleBg: circleBg,
                  iconColor: iconColor,
                  textColor: textPrimary,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEventDatePicker();
                  },
                ),
                _buildContentOption(
                  icon: Icons.bar_chart_rounded,
                  label: 'community.poll'.tr,
                  circleBg: circleBg,
                  iconColor: iconColor,
                  textColor: textPrimary,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPollCreatorSheet();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentOption({
    required IconData icon,
    required String label,
    required Color circleBg,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
        title: 'community.postScheduled'.tr,
        message: 'community.postScheduledAt'.tr.replaceAll('@time', pickedTime.format(context)),
      );
    }
  }

  void _showPollCreatorSheet() {
    final qCtrl = TextEditingController(text: _pollQuestion ?? '');
    final opt1Ctrl = TextEditingController(text: _pollOptionsList.isNotEmpty ? _pollOptionsList[0] : '');
    final opt2Ctrl = TextEditingController(text: _pollOptionsList.length > 1 ? _pollOptionsList[1] : '');
    final opt3Ctrl = TextEditingController(text: _pollOptionsList.length > 2 ? _pollOptionsList[2] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final surface = isDark ? const Color(0xFF161616) : Colors.white;
          final textPrimary = isDark ? Colors.white : Colors.black87;
          final inputBg = isDark ? const Color(0xFF202020) : const Color(0xFFF5F5F5);
          final hintColor = isDark ? Colors.white38 : Colors.black38;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: isDark ? const Color(0xFF282828) : Colors.black12),
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
                    'community.createPoll'.tr,
                    style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: qCtrl,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'community.pollQuestion'.tr,
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: opt1Ctrl,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'community.pollOption1'.tr,
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: opt2Ctrl,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'community.pollOption2'.tr,
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: opt3Ctrl,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'community.pollOption3'.tr,
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        if (qCtrl.text.trim().isNotEmpty &&
                            opt1Ctrl.text.trim().isNotEmpty &&
                            opt2Ctrl.text.trim().isNotEmpty) {
                          setState(() {
                            _pollQuestion = qCtrl.text.trim();
                            _pollOptionsList = [
                              opt1Ctrl.text.trim(),
                              opt2Ctrl.text.trim(),
                              if (opt3Ctrl.text.trim().isNotEmpty) opt3Ctrl.text.trim(),
                            ];
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'community.attachPoll'.tr,
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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
        _pollQuestion != null ||
        _selectedEventDate != null;
  }

  void _onBackPress() {
    if (_canPost) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E2228),
          title: Text(
            'community.discardDraft'.tr,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'community.discardMessage'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'community.keepEditing'.tr,
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'community.discard'.tr,
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

  /// Builds the user avatar from the authenticated user's profile.
  /// Falls back to the local asset if [avatarUrl] is null/empty.
  Widget _buildUserAvatar(bool isDark) {
    final avatarUrl = CurrentUser.avatarUrl;
    final hasNetwork = avatarUrl != null && avatarUrl.isNotEmpty;
    return CircleAvatar(
      radius: 16,
      backgroundColor: isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8),
      backgroundImage: hasNetwork
          ? NetworkImage(avatarUrl) as ImageProvider
          : const AssetImage('assets/images/user_profile.png'),
    );
  }

  void _submitPost() async {
    if (!_canPost || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final controller = Get.find<CommunityController>();

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
      controller.updatePost(
        postId: widget.initialPost!.id,
        content: _textController.text.trim(),
        imageUrls: _attachedImages,
        visibility: visibilityValue,
        location: _selectedEventDate,
        linkUrl: _attachedLink,
        linkPreviewTitle: _linkTitle,
        linkPreviewDomain: _linkDomain,
        pollQuestion: _pollQuestion,
        pollOptions: pollOpts,
        pollDuration: _pollDuration,
      );

      AppNotificationBanner.showSuccess(
        context: context,
        title: 'community.postUpdated'.tr,
        message: 'community.postUpdatedMsg'.tr,
      );
    } else {
      controller.createPost(
        content: _textController.text.trim(),
        imageUrls: _attachedImages,
        visibility: visibilityValue,
        location: _selectedEventDate,
        linkUrl: _attachedLink,
        linkPreviewTitle: _linkTitle,
        linkPreviewDomain: _linkDomain,
        pollQuestion: _pollQuestion,
        pollOptions: pollOpts,
        pollDuration: _pollDuration,
      );

      AppNotificationBanner.showSuccess(
        context: context,
        title: 'community.postCreated'.tr,
        message: 'community.postCreatedMsg'.tr,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark ? const Color(0xFF181C21) : const Color(0xFFF2F4F7);
    final cardBorder = isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8);
    final bottomBarBg = isDark ? const Color(0xFF0F1115) : Colors.white;

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
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
          elevation: 0,
          leadingWidth: 44,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 12),
            icon: Icon(Icons.close, color: textPrimary, size: 24),
            onPressed: _onBackPress,
          ),
          titleSpacing: 8,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
          // Real auth user — name + avatar
                _buildUserAvatar(isDark),
                const SizedBox(width: 8),
                // Audience Capsule Selector
                InkWell(
                  onTap: _showAudiencePickerSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2228) : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public, color: Color(0xFF8E9297), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          _selectedAudience == 'Public'
                              ? 'community.anyone'.tr
                              : (_selectedAudience == 'Friends'
                                  ? 'community.friendsOnly'.tr
                                  : 'community.onlyMe'.tr),
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.expand_more, color: Color(0xFF8E9297), size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.schedule_outlined, color: Color(0xFF8E9297), size: 22),
              visualDensity: VisualDensity.compact,
              tooltip: 'community.schedulePost'.tr,
              onPressed: _showScheduleDialog,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10, left: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _canPost && !_isSubmitting
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? const Color(0xFF222222) : const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _canPost && !_isSubmitting ? _submitPost : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                fontSize: 14,
                              ),
                              child: Text(
                                _isEditing ? 'common.save'.tr : 'community.post'.tr,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text composer — clean card, no inner oval border
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder, width: 1.0),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _editorFocusNode,
                        minLines: 3,
                        maxLines: null,
                        maxLength: _maxCharacters,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'community.whatsHappening'.tr,
                          hintStyle: TextStyle(
                            color: const Color(0xFF8E95A0),
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    // Character Counter placed neatly at bottom-right of composer area
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 4, bottom: 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "$charCount / $_maxCharacters",
                          style: const TextStyle(
                            color: Color(0xFF72767D),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Attached Content Previews (Shown ONLY when user explicitly attaches)
                    if (_attachedImages.isNotEmpty || _selectedEventDate != null || _pollQuestion != null)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // 1. Photo Thumbnail Cards — with animated removal
                          ..._attachedImages.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final imgPath = entry.value;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 105,
                                height: 105,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Image
                                    imgPath.startsWith('http')
                                        ? Image.network(imgPath, fit: BoxFit.cover)
                                        : Image.file(File(imgPath), fit: BoxFit.cover),
                                    // Gradient overlay for X readability
                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                          colors: [Color(0x88000000), Colors.transparent],
                                          stops: [0.0, 0.45],
                                        ),
                                      ),
                                    ),
                                    // Remove X button
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
                                          child: const Icon(Icons.close, color: Colors.white, size: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // 2. Attached Event Card
                          if (_selectedEventDate != null)
                            Container(
                              width: 140,
                              height: 105,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 30),
                                        const SizedBox(height: 8),
                                        Text(
                                          _selectedEventDate!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedEventDate = null;
                                        });
                                      },
                                      child: const Icon(Icons.close, color: Colors.white60, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // 3. Attached Poll Card
                          if (_pollQuestion != null)
                            Container(
                              width: 140,
                              height: 105,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 30),
                                        const SizedBox(height: 8),
                                        Text(
                                          _pollQuestion!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _pollQuestion = null;
                                          _pollOptionsList = [];
                                        });
                                      },
                                      child: const Icon(Icons.close, color: Colors.white60, size: 16),
                                    ),
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

            // Bottom Action Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: bottomBarBg,
                border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _ToolbarBtn(
                      icon: Icons.image_outlined,
                      tooltip: 'community.media'.tr,
                      color: textPrimary.withValues(alpha: 0.65),
                      onPressed: _pickGalleryImages,
                    ),
                    _ToolbarBtn(
                      icon: Icons.calendar_month_outlined,
                      tooltip: 'community.event'.tr,
                      color: textPrimary.withValues(alpha: 0.65),
                      onPressed: _showEventDatePicker,
                    ),
                    _ToolbarBtn(
                      icon: Icons.bar_chart_rounded,
                      tooltip: 'community.poll'.tr,
                      color: textPrimary.withValues(alpha: 0.65),
                      onPressed: _showPollCreatorSheet,
                    ),
                    _ToolbarBtn(
                      icon: Icons.sentiment_satisfied_alt_outlined,
                      tooltip: 'Emoji',
                      color: textPrimary.withValues(alpha: 0.65),
                      onPressed: _showEmojiPickerSheet,
                    ),
                    _ToolbarBtn(
                      icon: Icons.tag_rounded,
                      tooltip: 'Hashtag',
                      color: textPrimary.withValues(alpha: 0.65),
                      onPressed: _insertHashtag,
                    ),
                    _ToolbarBtn(
                      icon: Icons.alternate_email_rounded,
                      tooltip: 'Mention',
                      color: textPrimary.withValues(alpha: 0.65),
                      onPressed: _insertMention,
                    ),
                    const Spacer(),
                    // More '+' Button — dark/black bg, white icon
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: _showAddContentSheet,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 38,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2228) : Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
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
    );
  }
}

/// Compact, theme-aware toolbar icon button with press feedback.
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Icon(widget.icon, size: 22, color: widget.color),
          ),
        ),
      ),
    );
  }
}
