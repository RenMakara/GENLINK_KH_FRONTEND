import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/shared/utils/current_user.dart';
import '../../domain/models/chat_models.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_avatar.dart';

class GroupProfileScreen extends StatefulWidget {
  final ChatConversationModel conversation;

  const GroupProfileScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  late ChatConversationModel _conversation;
  List<ChatMemberModel> _members = [];
  bool _isLoading = false;
  File? _previewImageFile;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _members = widget.conversation.members;
    _loadRoomDetails();
  }

  Future<void> _loadRoomDetails() async {
    if (!Get.isRegistered<ChatController>()) return;
    final chatController = Get.find<ChatController>();

    setState(() => _isLoading = true);
    try {
      final room = await chatController.repository.getRoom(_conversation.id);
      if (mounted) {
        setState(() {
          _conversation = room;
          _members = room.members;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _currentUserId => CurrentUser.id;

  ChatMemberModel? get _currentMember {
    final uid = _currentUserId.trim();
    if (uid.isEmpty) return null;
    return _members.firstWhereOrNull((m) => m.userId == uid);
  }

  bool get _canManageGroup {
    final member = _currentMember;
    if (member != null) {
      return member.isAdmin;
    }
    // Default to true if not found to allow creator access in demo/offline mode
    return true;
  }

  Future<void> _pickAndChangePhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _previewImageFile = File(picked.path);
        });

        if (Get.isRegistered<MediaUploadService>()) {
          try {
            final uploadService = Get.find<MediaUploadService>();
            final bytes = await _previewImageFile!.readAsBytes();
            final media = await uploadService.upload(
              bytes: bytes,
              contentType: 'image/jpeg',
              purpose: MediaPurpose.avatar,
            );
            if (Get.isRegistered<ChatController>()) {
              final chatController = Get.find<ChatController>();
              await chatController.renameGroup(
                _conversation.id,
                _conversation.name,
                avatarUrl: media.url,
              );
              if (mounted) {
                setState(() {
                  _conversation = _conversation.copyWith(avatar: media.url);
                });
              }
            }
          } catch (e) {
            debugPrint('[GROUP-PROFILE] avatar upload error: $e');
          }
        }

        if (mounted) {
          AppNotificationBanner.showSuccess(
            context: context,
            title: 'Group Photo Updated',
            message: 'Group photo has been changed successfully.',
            icon: Icons.check_circle_rounded,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        AppNotificationBanner.showError(
          context: context,
          title: 'Photo Update Failed',
          message: 'Could not change group photo. Please try again.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _showRenameDialog() {
    final textController = TextEditingController(text: _conversation.name);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final dialogSurface = isDark ? AppColors.darkSurfacePrimary : Colors.white;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

        return AlertDialog(
          backgroundColor: dialogSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Group Name',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: textController,
            maxLength: 50,
            autofocus: true,
            style: TextStyle(color: textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Enter new group name',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.chatPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.chatPrimary, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isEmpty) return;
                Navigator.of(ctx).pop();

                if (Get.isRegistered<ChatController>()) {
                  final chatController = Get.find<ChatController>();
                  final ok = await chatController.renameGroup(_conversation.id, newName);
                  if (ok && mounted) {
                    setState(() {
                      _conversation = _conversation.copyWith(name: newName);
                    });
                    AppNotificationBanner.showSuccess(
                      context: context,
                      title: 'Group Renamed',
                      message: 'Group name changed to "$newName".',
                      icon: Icons.check_circle_rounded,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.chatPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final dialogSurface = isDark ? AppColors.darkSurfacePrimary : Colors.white;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

        return AlertDialog(
          backgroundColor: dialogSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Leave Group',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Are you sure you want to leave this group chat? You will no longer receive messages.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
              ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (Get.isRegistered<ChatController>()) {
                  final chatController = Get.find<ChatController>();
                  final groupName = _conversation.name;
                  final ok = await chatController.leaveGroup(_conversation.id);
                  if (ok) {
                    Get.back(); // close group profile
                    Get.back(); // close chat detail
                    Get.snackbar(
                      'Left Group',
                      'You have left "$groupName".',
                      snackPosition: SnackPosition.BOTTOM,
                      icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.chatPrimary),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Leave',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surfaceColor = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : const Color(0xFFEDF0F4);

    final displayMemberCount = _members.isNotEmpty
        ? _members.length
        : (_conversation.membersCount > 0 ? _conversation.membersCount : 1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: AppBackButton(onPressed: () => Get.back()),
        ),
        leadingWidth: 72,
        centerTitle: true,
        title: Text(
          'Group Info',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.chatPrimary),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Centered Group Header
                Center(
                  child: Column(
                    children: [
                      // Large Avatar with Camera/Edit Button
                      GestureDetector(
                        onTap: _pickAndChangePhoto,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.chatPrimary.withValues(alpha: 0.16)
                                    : const Color(0xFFEBF3FE),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.chatPrimary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: _previewImageFile != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _previewImageFile!,
                                        width: 92,
                                        height: 92,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : ChatAvatar(
                                      avatarUrl: _conversation.avatar,
                                      name: _conversation.name,
                                      radius: 46,
                                      showBadge: false,
                                      isEventChat: _conversation.isEventChat,
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.chatPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: surfaceColor,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Group Name
                      Text(
                        _conversation.name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Member Count
                      Text(
                        '$displayMemberCount members',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Edit Group Button (Owner/Admin)
                      if (_canManageGroup)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            onPressed: _showRenameDialog,
                            icon: const Icon(Icons.edit_rounded, size: 15),
                            label: const Text('Edit Group'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.chatPrimary,
                              side: const BorderSide(color: AppColors.chatPrimary, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 20),

                // Members Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$displayMemberCount total',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Members List
                if (_members.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        '$displayMemberCount members in this group',
                        style: TextStyle(color: textMuted, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ..._members.map((member) {
                    final isMe = member.userId == _currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          ChatAvatar(
                            avatarUrl: member.avatarUrl,
                            name: member.fullName,
                            radius: 22,
                            showBadge: false,
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        member.fullName,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(You)',
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member.username.startsWith('@')
                                      ? member.username
                                      : '@${member.username}',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Role Badge
                          if (member.isOwner)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.chatPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (member.isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 20),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 20),

                // Group Actions Section Header
                Text(
                  'Group Actions',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Action Tiles Card
                Material(
                  color: surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (_canManageGroup) ...[
                        ListTile(
                          leading: const Icon(Icons.edit_outlined, color: AppColors.chatPrimary),
                          title: Text(
                            'Edit Group Name',
                            style: TextStyle(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: _showRenameDialog,
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: const Icon(Icons.photo_camera_outlined, color: AppColors.chatPrimary),
                          title: Text(
                            'Change Group Photo',
                            style: TextStyle(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: _pickAndChangePhoto,
                        ),
                        Divider(height: 1, color: borderColor),
                      ],
                      ListTile(
                        leading: const Icon(Icons.exit_to_app_rounded, color: AppColors.danger),
                        title: const Text(
                          'Leave Group',
                          style: TextStyle(color: AppColors.danger, fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
                        onTap: _showLeaveConfirmDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
