import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../bindings/chat_binding.dart';
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
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  bool _isCreating = false;

  final List<Map<String, dynamic>> _contacts = [
    {
      'id': 'user_sokny',
      'name': 'Sokny Enat',
      'handle': '@soknyenat',
      'avatar': 'assets/images/user_profile.png',
      'isOnline': true,
    },
    {
      'id': 'user_chansela',
      'name': 'Heng Chansela',
      'handle': '@chansela',
      'avatar': 'assets/images/heng_chansela_profile.png',
      'isOnline': true,
    },
    {
      'id': 'user_makara',
      'name': 'Ren Makara',
      'handle': '@renmakara',
      'avatar': 'assets/images/ren_makara_profile.png',
      'isOnline': true,
    },
    {
      'id': 'user_dara',
      'name': 'Dara Heng',
      'handle': '@daraheng',
      'avatar': 'assets/images/user_profile.png',
      'isOnline': false,
    },
    {
      'id': 'user_sophea',
      'name': 'Sophea Kim',
      'handle': '@sopheakim',
      'avatar': 'assets/images/user_profile.png',
      'isOnline': false,
    },
    {
      'id': 'user_visal',
      'name': 'Visal Meas',
      'handle': '@visalmeas',
      'avatar': 'assets/images/user_profile.png',
      'isOnline': true,
    },
  ];

  String _tr(String key, String fallback, [Map<String, String>? params]) {
    final res = params != null ? key.trParams(params) : key.tr;
    if (res.isEmpty || res == key) {
      if (params != null) {
        var result = fallback;
        params.forEach((k, v) => result = result.replaceAll('@$k', v));
        return result;
      }
      return fallback;
    }
    return res;
  }

  ChatController get _effectiveController {
    if (!Get.isRegistered<ChatController>()) {
      ChatBinding().dependencies();
    }
    return Get.find<ChatController>();
  }

  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _groupNameController.text.trim().isNotEmpty &&
      _selectedUserIds.isNotEmpty &&
      !_isCreating;

  Future<void> _onCreateGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      AppNotificationBanner.showWarning(
        context: context,
        title: _tr('chat.groupNameRequired', 'Group Name Required'),
        message: _tr(
          'chat.groupNameRequiredDesc',
          'Please enter a name for your group chat.',
        ),
        icon: Icons.edit_note_rounded,
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      AppNotificationBanner.showWarning(
        context: context,
        title: _tr('chat.selectMembers', 'Select Members'),
        message: _tr(
          'chat.selectMembersDesc',
          'Please select at least 1 member to add to the group.',
        ),
        icon: Icons.group_add_rounded,
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final chatController = _effectiveController;
    final newGroup = await chatController.createGroup(
      name,
      _selectedUserIds.toList(),
    );

    if (!mounted) return;

    setState(() {
      _isCreating = false;
    });

    if (newGroup != null) {
      Get.back();
      Get.to(() => const ChatDetailScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surfaceColor =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final surfaceSecondary =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final filteredContacts = _contacts.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (c['name'] as String).toLowerCase();
      final handle = (c['handle'] as String).toLowerCase();
      return name.contains(q) || handle.contains(q);
    }).toList();

    final selectedContactsList = _contacts
        .where((c) => _selectedUserIds.contains(c['id']))
        .toList();

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
          _tr('chat.newGroupChat', 'New Group Chat'),
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _canCreate ? _onCreateGroup : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.chatPrimary,
                disabledForegroundColor: textMuted.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      _tr('chat.create', 'Create'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _canCreate
                            ? AppColors.chatPrimary
                            : textMuted.withValues(alpha: 0.35),
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
              // Group Identity (Avatar + Name)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AppNotificationBanner.showInfo(
                          context: context,
                          title: _tr('chat.groupIcon', 'Group Icon'),
                          message: _tr(
                            'chat.groupIconDesc',
                            'Tap to choose or upload group picture.',
                          ),
                          icon: Icons.camera_alt_rounded,
                        );
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppColors.chatPrimary.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.group_rounded,
                              color: AppColors.chatPrimary,
                              size: 24,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
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
                          hintText: _tr(
                            'chat.groupNameHint',
                            'e.g. Flutter Study Group',
                          ),
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

              // Selected Members Preview Horizontal Strip
              if (_selectedUserIds.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tr(
                              'chat.selectedCount',
                              'Selected · @count',
                              {'count': '${_selectedUserIds.length}'},
                            ),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedUserIds.clear();
                              });
                            },
                            child: Text(
                              _tr('chat.clearAll', 'Clear all'),
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
                        height: 58,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedContactsList.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (ctx, idx) {
                            final contact = selectedContactsList[idx];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ChatAvatar(
                                      avatarUrl: contact['avatar'] as String?,
                                      name: contact['name'] as String?,
                                      radius: 18,
                                      showBadge: false,
                                    ),
                                    const SizedBox(height: 3),
                                    SizedBox(
                                      width: 44,
                                      child: Text(
                                        (contact['name'] as String)
                                            .split(' ')
                                            .first,
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 10.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedUserIds.remove(contact['id']);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkSurfaceSecondary
                                            : Colors.black87,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: surfaceColor, width: 1),
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

              // Search Bar matching ChatListScreen
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  style: TextStyle(color: textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: surfaceSecondary,
                    hintText: _tr(
                      'chat.searchStudents',
                      'Search students...',
                    ),
                    hintStyle: TextStyle(color: textMuted, fontSize: 13.5),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: textMuted,
                      size: 20,
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorderStrong
                            : AppColors.lightBorderStrong,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _tr('chat.selectMembers', 'Select Members'),
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              // Contacts List
              Expanded(
                child: filteredContacts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 48,
                                color: textMuted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _tr(
                                  'chat.noStudentsFound',
                                  'No students found',
                                ),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tr(
                                  'chat.noStudentsFoundDesc',
                                  'Try searching a different name or handle.',
                                ),
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = filteredContacts[index];
                          final contactId = contact['id'] as String;
                          final isSelected =
                              _selectedUserIds.contains(contactId);

                          return GroupMemberTile(
                            name: contact['name'] as String,
                            handle: contact['handle'] as String,
                            avatarUrl: contact['avatar'] as String?,
                            isOnline: contact['isOnline'] as bool? ?? false,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedUserIds.remove(contactId);
                                } else {
                                  _selectedUserIds.add(contactId);
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
