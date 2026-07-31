import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/notification_model.dart';
import '../controllers/notification_controller.dart';
import '../bindings/notification_binding.dart';

class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  NotificationController get _effectiveController {
    if (!Get.isRegistered<NotificationController>()) {
      NotificationBinding().dependencies();
    }
    return Get.find<NotificationController>();
  }

  @override
  Widget build(BuildContext context) {
    final notifController = _effectiveController;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            const Text(
              "Notifications",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final count = notifController.unreadCount;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.communityAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => notifController.markAllAsRead(),
            child: const Text(
              "Mark all read",
              style: TextStyle(
                color: AppColors.communityAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
              const SizedBox(height: 4),

              // Category Filter Tabs
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: notifController.tabs.map((tab) {
                        final isSelected = notifController.selectedTab.value == tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => notifController.selectTab(tab),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.darkTextPrimary
                                    : AppColors.darkSurfaceSecondary,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.darkTextPrimary
                                      : AppColors.darkBorderSubtle,
                                ),
                              ),
                              child: Text(
                                tab,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )),

              const SizedBox(height: 8),

              // Notifications List
              Expanded(
                child: Obx(() {
                  if (notifController.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.communityAccent),
                    );
                  }

                  final list = notifController.filteredNotifications;

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 56,
                            color: AppColors.darkTextMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "No notifications yet",
                            style: TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "When you get reactions, comments or updates, they'll show up here.",
                            style: TextStyle(
                              color: AppColors.darkTextMuted,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => notifController.fetchNotifications(),
                    color: AppColors.communityAccent,
                    backgroundColor: AppColors.darkSurfaceSecondary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final notif = list[index];
                        return _buildNotificationCard(context, notif, notifController);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    NotificationController controller,
  ) {
    IconData getIcon() {
      switch (notif.type) {
        case NotificationType.like:
          return Icons.favorite_rounded;
        case NotificationType.comment:
          return Icons.chat_bubble_rounded;
        case NotificationType.mention:
          return Icons.alternate_email_rounded;
        case NotificationType.follow:
          return Icons.person_add_rounded;
        case NotificationType.group:
          return Icons.groups_rounded;
        case NotificationType.event:
          return Icons.event_rounded;
        case NotificationType.system:
          return Icons.notifications_rounded;
      }
    }

    Color getIconColor() {
      switch (notif.type) {
        case NotificationType.like:
          return const Color(0xFFFF4B4B);
        case NotificationType.comment:
          return AppColors.communityAccent;
        case NotificationType.mention:
          return const Color(0xFF8B7CF6);
        case NotificationType.follow:
          return AppColors.success;
        case NotificationType.event:
          return AppColors.warning;
        case NotificationType.group:
        case NotificationType.system:
          return AppColors.info;
      }
    }


    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => controller.deleteNotification(notif.id),
      child: InkWell(
        onTap: () {
          controller.markAsRead(notif.id);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead
                ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6)
                : AppColors.darkSurfaceSecondary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notif.isRead
                  ? AppColors.darkBorderSubtle
                  : AppColors.communityAccent.withValues(alpha: 0.4),
              width: notif.isRead ? 1.0 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with badge overlay
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.darkBorderSubtle,
                    backgroundImage: notif.senderAvatar != null
                        ? (notif.senderAvatar!.startsWith('http')
                            ? NetworkImage(notif.senderAvatar!) as ImageProvider
                            : AssetImage(notif.senderAvatar!))
                        : const AssetImage('assets/images/user_profile.png'),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        getIcon(),
                        size: 11,
                        color: getIconColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Notification Body Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          notif.timeAgo,
                          style: const TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(
                        color: notif.isRead ? AppColors.darkTextSecondary : Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (!notif.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.communityAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
