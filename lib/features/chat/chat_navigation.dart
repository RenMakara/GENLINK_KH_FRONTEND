import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import 'domain/models/chat_models.dart';
import 'presentation/bindings/chat_binding.dart';
import 'presentation/controllers/chat_controller.dart';
import 'presentation/screens/chat_detail_screen.dart';

/// Canonical chat navigation helper ensuring uniform routing and state initialization.
class ChatNavigation {
  ChatNavigation._();

  /// Opens the Chat Detail screen with the specified [roomId].
  ///
  /// Optionally accepts an existing [conversation] model to populate the header
  /// synchronously without waiting for a backend room lookup.
  static void openChatDetail(
    String roomId, {
    ChatConversationModel? conversation,
  }) {
    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) return;

    if (!Get.isRegistered<ChatController>()) {
      ChatBinding().dependencies();
    }

    final controller = Get.find<ChatController>();
    debugPrint('[CHAT-NAV] openChatDetail roomId = $cleanRoomId, currentRoute = ${Get.currentRoute}, controller = ${identityHashCode(controller)}, hasConversationArg = ${conversation != null}');
    if (conversation != null) {
      if (controller.activeConversation.value == null ||
          controller.activeConversation.value!.id != cleanRoomId) {
        controller.activeConversation.value = conversation;
      }
    }

    if (Get.currentRoute == AppRoutes.chatDetail) {
      if (controller.activeRoomId.value == cleanRoomId) {
        controller.ensureConversationLoaded(cleanRoomId, conversation: conversation);
        return;
      }
      controller.ensureConversationLoaded(cleanRoomId, conversation: conversation);
      Get.offNamed(
        AppRoutes.chatDetail,
        arguments: {'roomId': cleanRoomId, 'conversation': conversation},
        preventDuplicates: false,
      );
      return;
    }

    Get.to<void>(
      () => ChatDetailScreen(roomId: cleanRoomId),
      routeName: AppRoutes.chatDetail,
      arguments: {'roomId': cleanRoomId, 'conversation': conversation},
      preventDuplicates: false,
    );
  }
}
