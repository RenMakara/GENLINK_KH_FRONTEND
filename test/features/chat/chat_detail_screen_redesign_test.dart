import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:mocktail/mocktail.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_avatar.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/message_bubble.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/message_composer.dart';

class MockDio extends Mock implements Dio {}

class MockChatRepository extends Mock implements ChatRepositoryImpl {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatController controller;
  late MockChatRepository mockRepo;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    Get.fallbackLocale = const Locale('en', 'US');

    mockRepo = MockChatRepository();
    when(() => mockRepo.getMessages(any()))
        .thenAnswer((_) async => []);
    when(() => mockRepo.markConversationRead(any()))
        .thenAnswer((_) async => true);
    when(() => mockRepo.deleteMessage(any(), any()))
        .thenAnswer((_) async => true);
    when(() => mockRepo.getConversations())
        .thenAnswer((_) async => []);
    when(() => mockRepo.sendMessage(
          any(),
          any(),
          messageType: any(named: 'messageType'),
          mediaUrl: any(named: 'mediaUrl'),
          replyTo: any(named: 'replyTo'),
        )).thenAnswer((invocation) async {
      final convId = invocation.positionalArguments[0] as String;
      final content = invocation.positionalArguments[1] as String;
      final type = invocation.namedArguments[#messageType] as String? ?? 'text';
      return ChatMessageModel(
        id: 'sent-msg-1',
        conversationId: convId,
        senderId: 'user-me',
        senderName: 'Me',
        content: content,
        messageType: type,
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
        deliveryStatus: 'sent',
      );
    });

    controller = ChatController(repository: mockRepo);
    Get.put<ChatController>(controller, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp({required Widget home, ThemeMode themeMode = ThemeMode.dark}) {
    return GetMaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.lightBgPrimary,
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.darkBgPrimary,
      ),
      home: home,
    );
  }

  ChatConversationModel makeConversation({
    required String id,
    required String name,
    bool isOnline = false,
    bool isGroup = false,
    int membersCount = 2,
  }) {
    return ChatConversationModel(
      id: id,
      name: name,
      avatar: 'assets/images/user_profile.png',
      lastMessage: 'Hello!',
      lastMessageTime: 'Just now',
      isOnline: isOnline,
      isGroup: isGroup,
      membersCount: membersCount,
    );
  }

  group('GenLink Chat Detail Screen Redesign Tests', () {
    testWidgets('Header renders clean iOS structure with avatar, name, status, search, and more icons', (tester) async {
      final conv = makeConversation(
        id: 'room-header-test',
        name: 'nat',
        isOnline: false,
      );

      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(AppBar), matching: find.text('nat')), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byType(ChatAvatar), findsWidgets);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('Online status shows Online when user is online', (tester) async {
      final conv = makeConversation(
        id: 'room-online-test',
        name: 'Sokny',
        isOnline: true,
      );

      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('Empty composer displays blue circular + button and subtle Emoji icon', (tester) async {
      final conv = makeConversation(
        id: 'room-composer-empty',
        name: 'nat',
        isOnline: false,
      );
      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(MessageComposer), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
      expect(find.byIcon(Icons.mic_rounded), findsNothing);
    });

    testWidgets('Typing transitions smoothly from Emoji to Send icon and deleting returns Emoji', (tester) async {
      final conv = makeConversation(
        id: 'room-typing-transition',
        name: 'nat',
        isOnline: true,
      );
      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      // Initially empty -> Emoji icon
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);

      // Type 1 character -> Send button appears
      await tester.enterText(find.byType(TextField), 'H');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsNothing);

      // Clear text -> Emoji icon returns
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });

    testWidgets('Tapping Send executes existing message sending flow and clears composer', (tester) async {
      final conv = makeConversation(
        id: 'room-send-exec',
        name: 'nat',
        isOnline: true,
      );
      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello nat');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      // Controller text should be cleared
      expect(controller.textController.text, isEmpty);
      // Composer returns to Emoji state
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
    });

    testWidgets('Tapping Emoji button opens quick emoji picker and selecting emoji inserts into field', (tester) async {
      final conv = makeConversation(
        id: 'room-emoji-tap',
        name: 'nat',
        isOnline: true,
      );
      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      // Tap emoji button
      await tester.tap(find.byIcon(Icons.emoji_emotions_outlined));
      await tester.pumpAndSettle();

      // Quick emojis sheet is displayed
      expect(find.text('Quick Emojis'), findsOneWidget);
      expect(find.text('😊'), findsOneWidget);

      // Tap an emoji
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();

      // Sheet dismissed, emoji inserted into text field
      expect(controller.textController.text, contains('😊'));
      // Text is now non-empty, so Send button appears
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('Tapping + button opens media & attachments bottom sheet', (tester) async {
      final conv = makeConversation(
        id: 'room-attach-test',
        name: 'nat',
        isOnline: true,
      );
      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Media & Attachments'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
    });

    testWidgets('Message bubbles render incoming (elevated dark surface) and outgoing (blue) correctly', (tester) async {
      final conv = makeConversation(
        id: 'room-bubble-test',
        name: 'nat',
        isOnline: false,
      );
      final messages = [
        ChatMessageModel(
          id: 'm1',
          conversationId: 'room-bubble-test',
          senderId: 'nat-user',
          senderName: 'nat',
          content: 'How do you stay focused while studying?',
          timestamp: DateTime.parse('2026-09-18 10:00:00'),
          timeAgo: '2026-09-18',
          isMine: false,
        ),
        ChatMessageModel(
          id: 'm2',
          conversationId: 'room-bubble-test',
          senderId: 'user-me',
          senderName: 'Me',
          content: 'Hello enat',
          timestamp: DateTime.parse('2026-09-19 11:00:00'),
          timeAgo: '2026-09-19',
          isMine: true,
          deliveryStatus: 'read',
        ),
      ];

      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.activeMessages.assignAll(messages);
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      expect(find.text('How do you stay focused while studying?'), findsOneWidget);
      expect(find.text('Hello enat'), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
      expect(find.byType(MessageBubble), findsNWidgets(2));
    });

    testWidgets('Date separators render as clean rounded pills with date labels', (tester) async {
      final conv = makeConversation(
        id: 'room-dates-test',
        name: 'nat',
        isOnline: false,
      );
      final messages = [
        ChatMessageModel(
          id: 'd1',
          conversationId: 'room-dates-test',
          senderId: 'nat-user',
          senderName: 'nat',
          content: 'First day message',
          timestamp: DateTime(2026, 9, 18, 10, 0),
          timeAgo: '10:00 AM',
          isMine: false,
        ),
        ChatMessageModel(
          id: 'd2',
          conversationId: 'room-dates-test',
          senderId: 'user-me',
          senderName: 'Me',
          content: 'Second day message',
          timestamp: DateTime(2026, 9, 21, 14, 0),
          timeAgo: '02:00 PM',
          isMine: true,
        ),
      ];

      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.activeMessages.assignAll(messages);
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      expect(find.text('18 Sep 2026'), findsOneWidget);
      expect(find.text('21 Sep 2026'), findsOneWidget);
    });

    testWidgets('Header search opens and closes in-chat search bar', (tester) async {
      final conv = makeConversation(
        id: 'room-search-test',
        name: 'nat',
        isOnline: false,
      );
      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      // Search input not visible yet
      expect(find.text('Search in conversation...'), findsNothing);

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Search input becomes visible
      expect(find.text('Search in conversation...'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsWidgets);

      // Tap close search
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Search in conversation...'), findsNothing);
    });

    testWidgets('Header More button opens popup menu with existing actions', (tester) async {
      final conv = makeConversation(
        id: 'room-more-test',
        name: 'nat',
        isOnline: false,
      );
      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(home: const ChatDetailScreen()));
      await tester.pumpAndSettle();

      // Tap More menu button
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('View Profile'), findsOneWidget);
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Archive Chat'), findsOneWidget);
      expect(find.text('Clear History'), findsOneWidget);
    });

    testWidgets('Light Mode renders with proper light design system tokens', (tester) async {
      final conv = makeConversation(
        id: 'room-light-test',
        name: 'nat',
        isOnline: false,
      );
      controller.activeConversation.value = conv;
      controller.activeRoomId.value = conv.id;
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(buildTestApp(
        home: const ChatDetailScreen(),
        themeMode: ThemeMode.light,
      ));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(AppBar), matching: find.text('nat')), findsOneWidget);
      expect(find.byType(MessageComposer), findsOneWidget);
    });
  });
}
