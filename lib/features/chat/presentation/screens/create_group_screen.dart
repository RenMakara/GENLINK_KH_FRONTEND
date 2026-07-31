import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/chat_models.dart';
import '../controllers/chat_controller.dart';
import 'chat_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedUserIds = {};

  final List<Map<String, String>> _contacts = [
    {
      'id': 'user_sokuntheara',
      'name': 'Chhaeng Sokuntheara',
      'handle': '@sokuntheara',
      'avatar': 'assets/images/sokuntheara_profile.png',
    },
    {
      'id': 'user_sambo',
      'name': 'Sum Sambo',
      'handle': '@sumsambo',
      'avatar': 'assets/images/sum_sambo_profile.png',
    },
    {
      'id': 'user_chansela',
      'name': 'Heng Chansela',
      'handle': '@chansela',
      'avatar': 'assets/images/heng_chansela_profile.png',
    },
    {
      'id': 'user_makara',
      'name': 'Ren Makara',
      'handle': '@renmakara',
      'avatar': 'assets/images/ren_makara_profile.png',
    },
  ];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _onCreateGroup() {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        "Group Name Required",
        "Please enter a name for your group chat.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      Get.snackbar(
        "Select Members",
        "Please select at least 1 member to add to the group.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.warning,
        colorText: Colors.black,
      );
      return;
    }

    final chatController = Get.find<ChatController>();

    final newGroup = ChatConversationModel(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      avatar: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200',
      isGroup: true,
      isOnline: true,
      lastMessage: 'Group created by Sokny Enat',
      lastMessageTime: 'Just now',
      unreadCount: 0,
      membersCount: _selectedUserIds.length + 1,
    );

    chatController.conversations.insert(0, newGroup);
    chatController.openConversation(newGroup);

    Get.back(); // Close CreateGroupScreen
    Get.to(() => const ChatDetailScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "New Group Chat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _onCreateGroup,
            child: const Text(
              "Create",
              style: TextStyle(
                color: AppColors.communityAccent,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Group Name & Avatar Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.darkSurfacePrimary,
                  border: Border(bottom: BorderSide(color: AppColors.darkBorderSubtle)),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.communityAccent.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.group_add_rounded,
                            color: AppColors.communityAccent,
                            size: 28,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.communityAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.black, size: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _groupNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: "Group Name (e.g. AUB Flutter Team)",
                          hintStyle: TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Selected Count Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Members (${_selectedUserIds.length})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedUserIds.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedUserIds.clear();
                          });
                        },
                        child: const Text(
                          "Clear all",
                          style: TextStyle(
                            color: AppColors.communityAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Contacts Multi-Select List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final isSelected = _selectedUserIds.contains(contact['id']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.communityAccent : AppColors.darkBorderSubtle,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: AppColors.communityAccent,
                        checkColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                          contact['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          contact['handle']!,
                          style: const TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 12,
                          ),
                        ),
                        secondary: CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(contact['avatar']!),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUserIds.add(contact['id']!);
                            } else {
                              _selectedUserIds.remove(contact['id']!);
                            }
                          });
                        },
                      ),
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
