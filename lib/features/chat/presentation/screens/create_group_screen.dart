import 'dart:async';
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

import '../controllers/chat_controller.dart';
import '../widgets/chat_avatar.dart';
import 'chat_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _groupNameFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();

  // SINGLE AUTHORITATIVE state for selected members: Map<UserId, MemberData>
  final Map<String, Map<String, dynamic>> _selectedMembers =
  <String, Map<String, dynamic>>{};

  // Real member datasets. Never populate these with mock/fake users.
  final List<Map<String, dynamic>> _realMembers = [];
  final List<Map<String, dynamic>> _searchResults = [];

  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isCreating = false;
  bool _isSearching = false;
  bool _isLoadingInitial = false;
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();

    _groupNameController.addListener(_onLocalFieldChanged);
    _groupNameFocusNode.addListener(_onLocalFieldChanged);
    _searchFocusNode.addListener(_onLocalFieldChanged);

    _initRealMembers();
  }

  void _onLocalFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _selectedCount => _selectedMembers.length;

  List<String> get _selectedMemberIds =>
      _selectedMembers.keys.toList(growable: false);

  List<Map<String, dynamic>> get _selectedMembersList =>
      _selectedMembers.values.toList(growable: false);

  bool get _canCreate =>
      _groupNameController.text.trim().isNotEmpty &&
          _selectedCount > 0 &&
          !_isCreating;

  /// Loads real contacts from existing private conversations and backend
  /// following/connections. NEVER injects mock or fake users.
  Future<void> _initRealMembers() async {
    final Set<String> seenIds = <String>{};
    final initialList = <Map<String, dynamic>>[];

    // 1. Collect real contacts from existing private 1:1 chat conversations.
    if (Get.isRegistered<ChatController>()) {
      final chatController = Get.find<ChatController>();
      for (final conv in chatController.conversations) {
        final uid = conv.profileUserId;
        if (!conv.isGroup &&
            uid != null &&
            uid.isNotEmpty &&
            seenIds.add(uid)) {
          initialList.add({
            'id': uid,
            'name': conv.name,
            'handle': conv.profileUsername?.isNotEmpty == true
                ? '@${conv.profileUsername}'
                : '@user',
            'avatar': conv.avatar,
            'isOnline': conv.isOnline,
            'isVerified': false,
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _realMembers
          ..clear()
          ..addAll(initialList);
      });
    }

    // 2. Fetch real connected/eligible users from the backend when available.
    if (Get.isRegistered<ChatController>()) {
      if (mounted) {
        setState(() => _isLoadingInitial = true);
      }

      try {
        final chatController = Get.find<ChatController>();
        final currentUid = CurrentUser.id;
        final backendUsers =
        await chatController.repository.getEligibleUsers(
          currentUserId: currentUid.isNotEmpty ? currentUid : null,
        );

        for (final user in backendUsers) {
          final uid = user['id']?.toString() ?? '';
          if (uid.isNotEmpty && seenIds.add(uid)) {
            initialList.add(user);
          }
        }
      } catch (_) {
        // Keep the real conversation-derived members when the backend
        // request is unavailable. No mock data is inserted.
      }

      if (mounted) {
        setState(() {
          _realMembers
            ..clear()
            ..addAll(initialList);
          _isLoadingInitial = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _groupNameController.removeListener(_onLocalFieldChanged);
    _groupNameFocusNode.removeListener(_onLocalFieldChanged);
    _searchFocusNode.removeListener(_onLocalFieldChanged);
    _groupNameController.dispose();
    _searchController.dispose();
    _groupNameFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleMember(Map<String, dynamic> member) {
    final id = member['id']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() {
      if (_selectedMembers.containsKey(id)) {
        _selectedMembers.remove(id);
      } else {
        _selectedMembers[id] = member;
      }
    });
  }

  Future<void> _pickGroupImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        setState(() {
          _selectedImageFile = File(picked.path);
        });
      }
    } catch (_) {
      if (mounted) {
        AppNotificationBanner.showError(
          context: context,
          title: 'chat.group.imageSelectionFailed'.tr,
          message: 'chat.group.imageSelectionFailedMsg'.tr,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _onSearchChanged(String val) {
    final q = val.trim();

    setState(() {
      _searchQuery = q;
    });

    _debounceTimer?.cancel();

    if (q.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(
      const Duration(milliseconds: 300),
          () async {
        try {
          if (!Get.isRegistered<ChatController>()) {
            if (mounted) {
              setState(() => _isSearching = false);
            }
            return;
          }

          final chatController = Get.find<ChatController>();
          final results = await chatController.repository.searchUsers(q);
          final validResults = results.where((user) {
            final id = user['id']?.toString() ?? '';
            return id.isNotEmpty;
          }).toList();

          // Ignore stale responses if the query changed while this request
          // was in flight.
          if (!mounted || _searchQuery.trim() != q) return;

          setState(() {
            _searchResults
              ..clear()
              ..addAll(validResults);
            _isSearching = false;
          });
        } catch (_) {
          if (mounted && _searchQuery.trim() == q) {
            setState(() {
              _isSearching = false;
            });
          }
        }
      },
    );
  }

  Future<void> _onCreateGroup() async {
    final name = _groupNameController.text.trim();

    if (name.isEmpty) {
      AppNotificationBanner.showWarning(
        context: context,
        title: 'chat.group.groupNameRequired'.tr,
        message: 'chat.group.groupNameRequiredMsg'.tr,
        icon: Icons.edit_note_rounded,
      );
      return;
    }

    final validMemberIds = _selectedMemberIds;

    if (validMemberIds.isEmpty) {
      AppNotificationBanner.showWarning(
        context: context,
        title: 'chat.group.selectMembersWarningTitle'.tr,
        message: 'chat.group.selectMembersWarningMsg'.tr,
        icon: Icons.group_add_rounded,
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      if (!Get.isRegistered<ChatController>()) {
        if (mounted) {
          setState(() => _isCreating = false);
        }
        return;
      }

      final chatController = Get.find<ChatController>();

      String? uploadedAvatarUrl;

      // Upload group photo if picked and the existing media service is available.
      if (_selectedImageFile != null &&
          Get.isRegistered<MediaUploadService>()) {
        try {
          final uploadService = Get.find<MediaUploadService>();
          final bytes = await _selectedImageFile!.readAsBytes();

          final media = await uploadService.upload(
            bytes: bytes,
            contentType: 'image/jpeg',
            purpose: MediaPurpose.avatar,
          );

          uploadedAvatarUrl = media.url;
        } catch (e) {
          debugPrint('[CREATE-GROUP] Avatar upload warning: $e');
        }
      }

      final newGroup = await chatController.createGroup(
        name,
        validMemberIds,
        avatarUrl: uploadedAvatarUrl,
      );

      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }

      if (newGroup != null && mounted) {
        Get.back();
        Get.to(() => ChatDetailScreen(roomId: newGroup.id));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });

        AppNotificationBanner.showError(
          context: context,
          title: 'common.error'.tr,
          message: 'chat.group.createGroupErrorMsg'.tr,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor =
    isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surfaceColor =
    isDark ? AppColors.darkSurfacePrimary : Colors.white;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor =
    isDark ? AppColors.darkBorderSubtle : const Color(0xFFE4E7EC);

    // IMPORTANT:
    // Search changes ONLY the visible subset. It never mutates
    // _selectedMembers, so selections remain intact while searching.
    final List<Map<String, dynamic>> displayContacts;

    if (_searchQuery.trim().isEmpty) {
      displayContacts = List<Map<String, dynamic>>.unmodifiable(
        _realMembers,
      );
    } else {
      final query = _searchQuery.trim().toLowerCase();
      final seenIds = <String>{};
      final combined = <Map<String, dynamic>>[];

      for (final member in _realMembers) {
        final id = member['id']?.toString() ?? '';
        final name =
        (member['name'] as String? ?? '').trim().toLowerCase();
        final handle =
        (member['handle'] as String? ?? '').trim().toLowerCase();

        if (id.isNotEmpty &&
            (name.contains(query) || handle.contains(query)) &&
            seenIds.add(id)) {
          combined.add(member);
        }
      }

      for (final member in _searchResults) {
        final id = member['id']?.toString() ?? '';
        if (id.isNotEmpty && seenIds.add(id)) {
          combined.add(member);
        }
      }

      displayContacts = combined;
    }

    final selectedCount = _selectedCount;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Center(
            child: AppBackButton(
              onPressed: () => Get.back(),
            ),
          ),
        ),
        centerTitle: false,
        title: Text(
          'chat.group.newGroupChat'.tr,
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _canCreate ? 1 : 0.42,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _canCreate ? _onCreateGroup : null,
                  child: Text(
                    'chat.group.create'.tr,
                    style: TextStyle(
                      color: _canCreate
                          ? AppColors.chatPrimary
                          : textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      28,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildGroupSetup(
                            context,
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 24),
                          _buildMemberSearch(
                            context,
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 26),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'chat.group.members'.tr,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration:
                                const Duration(milliseconds: 180),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.92,
                                        end: 1,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: selectedCount > 0
                                    ? Container(
                                  key: ValueKey(selectedCount),
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.chatPrimary
                                        .withValues(alpha: 0.10),
                                    borderRadius:
                                    BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'chat.group.selectedCount'.trParams(
                                        {'count': selectedCount.toString()}),
                                    style: TextStyle(
                                      color: AppColors.chatPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                                    : Text(
                                  'chat.group.zeroSelected'.tr,
                                  key: const ValueKey('zero'),
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_isLoadingInitial || _isSearching)
                            _buildLoadingMembers(
                              context,
                              isDark: isDark,
                              surfaceColor: surfaceColor,
                            )
                          else if (displayContacts.isEmpty)
                            _buildEmptyMembers(
                              context,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                            )
                          else
                            ...displayContacts.map(
                                  (member) {
                                final id =
                                    member['id']?.toString() ?? '';
                                final isSelected =
                                _selectedMembers.containsKey(id);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildMemberCard(
                                    context,
                                    member: member,
                                    isSelected: isSelected,
                                    isDark: isDark,
                                    surfaceColor: surfaceColor,
                                    textPrimary: textPrimary,
                                    textMuted: textMuted,
                                    borderColor: borderColor,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomCreateBar(
              context,
              isDark: isDark,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
              borderColor: borderColor,
              selectedCount: selectedCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSetup(
      BuildContext context, {
        required bool isDark,
        required Color surfaceColor,
        required Color textPrimary,
        required Color textMuted,
        required Color borderColor,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickGroupImage,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.chatPrimary.withValues(alpha: 0.14)
                      : const Color(0xFFEAF2FF),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.20 : 0.07,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _selectedImageFile != null
                      ? Image.file(
                    _selectedImageFile!,
                    fit: BoxFit.cover,
                  )
                      : Icon(
                    Icons.group_rounded,
                    size: 40,
                    color: AppColors.chatPrimary,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: AppColors.chatPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: surfaceColor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.chatPrimary.withValues(
                          alpha: 0.20,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'chat.group.groupName'.tr,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _groupNameController,
          builder: (context, value, _) {
            return Container(
              height: 54,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _groupNameController,
                focusNode: _groupNameFocusNode,
                maxLength: 50,
                textCapitalization: TextCapitalization.words,
                cursorColor: AppColors.chatPrimary,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'chat.group.groupNameHint'.tr,
                  hintStyle: TextStyle(
                    color: textMuted.withValues(alpha: 0.68),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _groupNameController,
            builder: (context, value, _) {
              return Text(
                '${value.text.length}/50',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSearch(
      BuildContext context, {
        required bool isDark,
        required Color surfaceColor,
        required Color textPrimary,
        required Color textMuted,
        required Color borderColor,
      }) {
    final isActive =
        _searchFocusNode.hasFocus || _searchQuery.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 52,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.chatPrimary,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14.5,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'chat.group.searchHint'.tr,
          hintStyle: TextStyle(
            color: textMuted.withValues(alpha: 0.70),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 21,
            color: isActive
                ? AppColors.chatPrimary
                : textMuted,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            tooltip: 'chat.group.clearSearch'.tr,
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              _searchFocusNode.requestFocus();
            },
            icon: Icon(
              Icons.cancel_rounded,
              size: 19,
              color: textMuted,
            ),
          )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(
      BuildContext context, {
        required Map<String, dynamic> member,
        required bool isSelected,
        required bool isDark,
        required Color surfaceColor,
        required Color textPrimary,
        required Color textMuted,
        required Color borderColor,
      }) {
    final name = (member['name'] as String?)?.isNotEmpty == true
        ? member['name'] as String
        : 'chat.group.student'.tr;
    final handle = member['handle'] as String? ?? '@user';
    final avatar = member['avatar'] as String?;
    final isOnline = member['isOnline'] as bool? ?? false;
    final isVerified = member['isVerified'] as bool? ?? false;

    final selectedBackground = AppColors.chatPrimary.withValues(
      alpha: isDark ? 0.12 : 0.065,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? selectedBackground : surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppColors.chatPrimary.withValues(alpha: 0.20)
              : borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _toggleMember(member),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ChatAvatar(
                      avatarUrl: avatar,
                      name: name,
                      radius: 24,
                      showBadge: false,
                    ),
                    if (isOnline)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: surfaceColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 5),
                            Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppColors.chatPrimary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.chatPrimary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.chatPrimary
                          : textMuted.withValues(alpha: 0.30),
                      width: isSelected ? 0 : 1.5,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: isSelected
                        ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('selected'),
                      color: Colors.white,
                      size: 18,
                    )
                        : const SizedBox(
                      key: ValueKey('unselected'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMembers(
      BuildContext context, {
        required bool isDark,
        required Color surfaceColor,
      }) {
    final skeletonColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFF0F2F5);

    return Column(
      children: List.generate(
        5,
            (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 125,
                          height: 12,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 90,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF5F6F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
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

  Widget _buildEmptyMembers(
      BuildContext context, {
        required bool isDark,
        required Color textPrimary,
        required Color textMuted,
      }) {
    final hasSearch = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 56,
        horizontal: 24,
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF1F4F8),
            ),
            child: Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.groups_outlined,
              size: 31,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'chat.group.noStudentsFound'.tr,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'chat.group.tryDifferentSearch'.tr
                : 'chat.group.searchDifferentHint'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCreateBar(
      BuildContext context, {
        required bool isDark,
        required Color surfaceColor,
        required Color textPrimary,
        required Color textMuted,
        required Color borderColor,
        required int selectedCount,
      }) {
    final selectedList = _selectedMembersList;
    final previewAvatars = selectedList.take(3).toList();
    final remaining = selectedCount - previewAvatars.length;

    final canCreate = _canCreate;

    final buttonBackground = canCreate
        ? (isDark
        ? const Color(0xFFF2F4F7)
        : const Color(0xFF15171A))
        : (isDark
        ? AppColors.darkSurfaceSecondary
        : const Color(0xFFE7E9ED));

    final buttonForeground = canCreate
        ? (isDark
        ? const Color(0xFF15171A)
        : Colors.white)
        : (isDark
        ? AppColors.darkTextMuted
        : const Color(0xFF9AA0A6));

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.25 : 0.05,
            ),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ===========================================================
          // SELECTED AVATARS
          // ===========================================================
          if (previewAvatars.isNotEmpty)
            SizedBox(
              width: remaining > 0 ? 82 : 64,
              height: 38,
              child: Stack(
                children: [
                  for (int index = 0;
                  index < previewAvatars.length;
                  index++)
                    Positioned(
                      left: index * 19.0,
                      top: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: surfaceColor,
                            width: 2,
                          ),
                        ),
                        child: ChatAvatar(
                          avatarUrl:
                          previewAvatars[index]['avatar'] as String?,
                          name:
                          previewAvatars[index]['name'] as String?,
                          radius: 17,
                          showBadge: false,
                        ),
                      ),
                    ),
                  if (remaining > 0)
                    Positioned(
                      left: previewAvatars.length * 19.0,
                      top: 1,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.darkSurfaceSecondary
                              : const Color(0xFFF0F2F5),
                          border: Border.all(
                            color: surfaceColor,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '+$remaining',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            const SizedBox(width: 4),

          const SizedBox(width: 10),

          // ===========================================================
          // COUNT / HINT
          // ===========================================================
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                selectedCount == 0
                    ? 'chat.group.selectMembers'.tr
                    : selectedCount == 1
                    ? 'chat.group.oneMemberSelected'.tr
                    : 'chat.group.membersSelectedCount'.trParams(
                    {'count': selectedCount.toString()}),
                key: ValueKey(selectedCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selectedCount == 0
                      ? textMuted
                      : textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ===========================================================
          // CREATE BUTTON
          // ===========================================================
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            decoration: BoxDecoration(
              color: buttonBackground,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canCreate ? _onCreateGroup : null,
                borderRadius: BorderRadius.circular(17),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  child: Center(
                    child: _isCreating
                        ? SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: buttonForeground,
                      ),
                    )
                        : Text(
                      'chat.group.createGroupButton'.tr,
                      style: TextStyle(
                        color: buttonForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
