import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/group_member_tile.dart';
import 'chat_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _selectedMembers = {};
  final List<Map<String, dynamic>> _defaultContacts = [];
  final List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isCreating = false;
  bool _isSearching = false;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static final List<Map<String, dynamic>> _initialSuggestedContacts = [
    // {
    //   'id': 'a0000000-0000-0000-0000-000000000001',
    //   'name': 'Sokny Enat',
    //   'handle': '@soknyenat',
    //   'avatar': 'assets/images/user_profile.png',
    //   'isOnline': true,
    // },
    // {
    //   'id': 'a0000000-0000-0000-0000-000000000002',
    //   'name': 'Heng Chansela',
    //   'handle': '@chansela',
    //   'avatar': 'assets/images/heng_chansela_profile.png',
    //   'isOnline': true,
    // },
    // {
    //   'id': 'a0000000-0000-0000-0000-000000000003',
    //   'name': 'Ren Makara',
    //   'handle': '@renmakara',
    //   'avatar': 'assets/images/ren_makara_profile.png',
    //   'isOnline': true,
    // },
  ];

  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(() => setState(() {}));
    _initDefaultContacts();
  }

  void _initDefaultContacts() {
    final Set<String> seenIds = {};

    if (Get.isRegistered<ChatController>()) {
      final chatController = Get.find<ChatController>();
      for (final conv in chatController.conversations) {
        final uid = conv.profileUserId;
        if (!conv.isGroup &&
            uid != null &&
            _uuidRegex.hasMatch(uid) &&
            !seenIds.contains(uid)) {
          seenIds.add(uid);
          _defaultContacts.add({
            'id': uid,
            'name': conv.name,
            'handle': conv.profileUsername?.isNotEmpty == true
                ? '@${conv.profileUsername}'
                : '@user',
            'avatar': conv.avatar,
            'isOnline': conv.isOnline,
          });
        }
      }
    }

    for (final c in _initialSuggestedContacts) {
      if (seenIds.add(c['id'] as String)) {
        _defaultContacts.add(c);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _groupNameController.text.trim().isNotEmpty &&
      _selectedMembers.isNotEmpty &&
      !_isCreating;

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

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        if (!Get.isRegistered<ChatController>()) {
          if (mounted) setState(() => _isSearching = false);
          return;
        }
        final chatController = Get.find<ChatController>();
        final results = await chatController.repository.searchUsers(q);
        final validResults = results.where((u) {
          final id = u['id']?.toString() ?? '';
          return _uuidRegex.hasMatch(id);
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults.clear();
            _searchResults.addAll(validResults);
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _onCreateGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      AppNotificationBanner.showWarning(
        context: context,
        title: 'chat.groupNameRequired'.tr.isNotEmpty &&
                'chat.groupNameRequired'.tr != 'chat.groupNameRequired'
            ? 'chat.groupNameRequired'.tr
            : 'Group Name Required',
        message: 'chat.groupNameRequiredDesc'.tr.isNotEmpty &&
                'chat.groupNameRequiredDesc'.tr != 'chat.groupNameRequiredDesc'
            ? 'chat.groupNameRequiredDesc'.tr
            : 'Please enter a name for your group chat.',
        icon: Icons.edit_note_rounded,
      );
      return;
    }

    final validMemberIds = _selectedMembers.keys
        .where((id) => _uuidRegex.hasMatch(id))
        .toList();

    if (validMemberIds.isEmpty) {
      AppNotificationBanner.showWarning(
        context: context,
        title: 'chat.selectMembers'.tr.isNotEmpty &&
                'chat.selectMembers'.tr != 'chat.selectMembers'
            ? 'chat.selectMembers'.tr
            : 'Select Members',
        message: 'chat.selectMembersDesc'.tr.isNotEmpty &&
                'chat.selectMembersDesc'.tr != 'chat.selectMembersDesc'
            ? 'chat.selectMembersDesc'.tr
            : 'Please select at least 1 member to add to the group.',
        icon: Icons.group_add_rounded,
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      if (!Get.isRegistered<ChatController>()) {
        setState(() => _isCreating = false);
        return;
      }
      final chatController = Get.find<ChatController>();
      final newGroup = await chatController.createGroup(
        name,
        validMemberIds,
      );

      setState(() {
        _isCreating = false;
      });

      if (newGroup != null) {
        Get.back();
        Get.to(() => const ChatDetailScreen());
      }
    } catch (_) {
      setState(() {
        _isCreating = false;
      });
      if (mounted) {
        AppNotificationBanner.showError(
          context: context,
          title: 'Error',
          message: 'Failed to create group. Please check your connection and try again.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surfaceColor = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final selectedContactsList = _selectedMembers.values.toList();

    final List<Map<String, dynamic>> displayContacts;
    if (_searchQuery.isEmpty) {
      displayContacts = _defaultContacts;
    } else {
      final seenIds = <String>{};
      final combined = <Map<String, dynamic>>[];
      final q = _searchQuery.toLowerCase();
      for (final c in _defaultContacts) {
        final id = c['id'] as String;
        final name = (c['name'] as String).toLowerCase();
        final handle = (c['handle'] as String).toLowerCase();
        if (name.contains(q) || handle.contains(q)) {
          if (seenIds.add(id)) combined.add(c);
        }
      }
      for (final c in _searchResults) {
        final id = c['id'] as String;
        if (seenIds.add(id)) combined.add(c);
      }
      displayContacts = combined;
    }

    final titleText = 'chat.newGroupChat'.tr.isNotEmpty && 'chat.newGroupChat'.tr != 'chat.newGroupChat'
        ? 'chat.newGroupChat'.tr
        : 'New Group Chat';

    final createButtonText = 'chat.create'.tr.isNotEmpty && 'chat.create'.tr != 'chat.create'
        ? 'chat.create'.tr
        : 'Create';

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
        title: Text(
          titleText,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _canCreate ? _onCreateGroup : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.chatPrimary,
                disabledForegroundColor: textMuted.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.chatPrimary,
                      ),
                    )
                  : Text(
                      createButtonText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _canCreate
                            ? AppColors.chatPrimary
                            : textMuted.withValues(alpha: 0.4),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AppNotificationBanner.showInfo(
                          context: context,
                          title: 'Group Icon',
                          message: 'Tap to choose or upload group picture.',
                          icon: Icons.camera_alt_rounded,
                        );
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.chatPrimary.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.group_rounded,
                              color: AppColors.chatPrimary,
                              size: 26,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                color: AppColors.chatPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(color: surfaceColor, width: 1.5),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: TextField(
                        controller: _groupNameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'chat.groupNameHint'.tr.isNotEmpty &&
                                  'chat.groupNameHint'.tr != 'chat.groupNameHint'
                              ? 'chat.groupNameHint'.tr
                              : 'e.g. Flutter Study Group',
                          hintStyle: TextStyle(
                            color: textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedMembers.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'chat.selectedCount'.tr.isNotEmpty &&
                                    'chat.selectedCount'.tr != 'chat.selectedCount'
                                ? 'chat.selectedCount'.trParams({'count': '${_selectedMembers.length}'})
                                : 'Selected · ${_selectedMembers.length}',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMembers.clear();
                              });
                            },
                            child: Text(
                              'chat.clearAll'.tr.isNotEmpty && 'chat.clearAll'.tr != 'chat.clearAll'
                                  ? 'chat.clearAll'.tr
                                  : 'Clear all',
                              style: const TextStyle(
                                color: AppColors.chatPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedContactsList.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (ctx, idx) {
                            final contact = selectedContactsList[idx];
                            return Stack(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ChatAvatar(
                                      avatarUrl: contact['avatar'] as String?,
                                      name: contact['name'] as String?,
                                      radius: 19,
                                      showBadge: false,
                                    ),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      width: 42,
                                      child: Text(
                                        (contact['name'] as String).split(' ').first,
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMembers.remove(contact['id']);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceSecondary : Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search_rounded, color: textMuted, size: 18),
                      hintText: 'chat.searchStudents'.tr.isNotEmpty &&
                              'chat.searchStudents'.tr != 'chat.searchStudents'
                          ? 'chat.searchStudents'.tr
                          : 'Search students...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 13),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, size: 16, color: textMuted),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'chat.selectMembers'.tr.isNotEmpty && 'chat.selectMembers'.tr != 'chat.selectMembers'
                        ? 'chat.selectMembers'.tr
                        : 'Select Members',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _isSearching
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.chatPrimary,
                          ),
                        ),
                      )
                    : displayContacts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty
                                        ? Icons.search_off_rounded
                                        : Icons.person_search_rounded,
                                    size: 38,
                                    color: textMuted.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No students found for "$_searchQuery"'
                                        : 'Search students to add to your group',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            itemCount: displayContacts.length,
                            itemBuilder: (context, index) {
                              final contact = displayContacts[index];
                              final contactId = contact['id'] as String;
                              final isSelected =
                                  _selectedMembers.containsKey(contactId);

                              return GroupMemberTile(
                                name: contact['name'] as String,
                                handle: contact['handle'] as String,
                                avatarUrl: contact['avatar'] as String?,
                                isOnline:
                                    contact['isOnline'] as bool? ?? false,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedMembers.remove(contactId);
                                    } else {
                                      _selectedMembers[contactId] = contact;
                                    }
                                  });
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
