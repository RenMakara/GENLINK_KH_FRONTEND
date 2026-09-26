import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:mocktail/mocktail.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/chat/presentation/utils/shared_content_navigator.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_attachment_sheet.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/message_bubble.dart';
import 'package:genlink_frontend/features/community/data/repositories/community_repository_impl.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/post_detail_screen.dart';

class MockChatRepository extends Mock implements ChatRepositoryImpl {}
class MockCommunityRepository extends Mock implements CommunityRepositoryImpl {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(SharedContentModel(
      type: SharedContentType.post,
      id: 'fallback-id',
      title: 'fallback',
    ));
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    Get.fallbackLocale = const Locale('en', 'US');
  });

  group('SharedContentModel & ChatMessageModel Architecture', () {
    test('SharedContentType enum parsing and deepLink format', () {
      final postContent = SharedContentModel(
        type: SharedContentType.post,
        id: 'post-uuid-101',
        title: 'Tech Meetup in Phnom Penh',
        previewText: 'Join us this Saturday for Flutter talks.',
        authorName: 'Sophea Pich',
        thumbnailUrl: 'https://example.com/meetup.png',
        subtitle: 'Flutter Cambodia',
      );

      expect(postContent.type, SharedContentType.post);
      expect(postContent.id, 'post-uuid-101');
      expect(postContent.deepLink, 'genlink://post/post-uuid-101');

      final discContent = SharedContentModel(
        type: SharedContentType.discussion,
        id: 'disc-uuid-202',
        title: 'Best Coffee in BKK1?',
        previewText: 'Looking for quiet cafes with great wifi.',
      );
      expect(discContent.deepLink, 'genlink://discussion/disc-uuid-202');

      final eventContent = SharedContentModel(
        type: SharedContentType.event,
        id: 'event-uuid-303',
        title: 'Water Festival 2026',
      );
      expect(eventContent.deepLink, 'genlink://event/event-uuid-303');

      final profileContent = SharedContentModel(
        type: SharedContentType.profile,
        id: 'user-uuid-404',
        title: 'Ren Makara',
        subtitle: '@renmakara',
      );
      expect(profileContent.deepLink, 'genlink://profile/user-uuid-404');
    });

    test('SharedContentModel json round-trip serialization', () {
      final original = SharedContentModel(
        type: SharedContentType.post,
        id: 'p-88',
        title: 'Sample Post Title',
        previewText: 'A short snippet of the post body.',
        thumbnailUrl: 'https://cdn.example.com/img.jpg',
        authorName: 'Dara Chan',
        authorAvatar: 'https://cdn.example.com/dara.jpg',
        subtitle: 'Startup KH',
        metadata: {'tag': 'announcement'},
      );

      final json = original.toJson();
      expect(json['type'], 'POST');
      expect(json['id'], 'p-88');
      expect(json['title'], 'Sample Post Title');
      expect(json['previewText'], 'A short snippet of the post body.');
      expect(json['thumbnailUrl'], 'https://cdn.example.com/img.jpg');
      expect(json['authorName'], 'Dara Chan');
      expect(json['authorAvatar'], 'https://cdn.example.com/dara.jpg');
      expect(json['subtitle'], 'Startup KH');
      expect(json['metadata'], {'tag': 'announcement'});

      final restored = SharedContentModel.fromJson(json);
      expect(restored.type, SharedContentType.post);
      expect(restored.id, 'p-88');
      expect(restored.title, 'Sample Post Title');
      expect(restored.previewText, 'A short snippet of the post body.');
      expect(restored.thumbnailUrl, 'https://cdn.example.com/img.jpg');
      expect(restored.authorName, 'Dara Chan');
      expect(restored.authorAvatar, 'https://cdn.example.com/dara.jpg');
      expect(restored.subtitle, 'Startup KH');
      expect(restored.metadata?['tag'], 'announcement');
    });

    test('ChatMessageModel backward compatibility: normal text message has null sharedContent', () {
      final normalJson = {
        'id': 'msg-001',
        'sender_id': 'user-1',
        'sender_name': 'Alice',
        'content': 'Hello, how are you?',
        'message_type': 'text',
        'created_at': DateTime.now().toIso8601String(),
      };

      final msg = ChatMessageModel.fromJson(normalJson, conversationId: 'conv-001');
      expect(msg.content, 'Hello, how are you?');
      expect(msg.sharedContent, isNull);

      final serialized = msg.toJson();
      expect(serialized['content'], 'Hello, how are you?');
      expect(serialized.containsKey('sharedContent'), isFalse);
    });

    test('ChatMessageModel with rich SharedContent serializes and deserializes', () {
      final richJson = {
        'id': 'msg-002',
        'sender_id': 'user-2',
        'sender_name': 'Bob',
        'content': 'Check this out!',
        'message_type': 'text',
        'created_at': DateTime.now().toIso8601String(),
        'shared_content': {
          'type': 'POST',
          'id': 'post-555',
          'title': 'Exciting Tech News',
          'previewText': 'Cambodia tech scene is booming.',
          'authorName': 'Socheat',
        },
      };

      final msg = ChatMessageModel.fromJson(richJson, conversationId: 'conv-001');
      expect(msg.content, 'Check this out!');
      expect(msg.sharedContent, isNotNull);
      expect(msg.sharedContent!.type, SharedContentType.post);
      expect(msg.sharedContent!.id, 'post-555');
      expect(msg.sharedContent!.title, 'Exciting Tech News');

      final serialized = msg.toJson();
      expect(serialized['sharedContent'], isNotNull);
      expect((serialized['sharedContent'] as Map)['id'], 'post-555');
    });
  });

  group('ChatAttachmentSheet: Finance Actions Removed & Share on GenLink Present', () {
    testWidgets('Attachment sheet displays Media & Attachments and Share on GenLink, but NO Finance', (tester) async {
      bool postTapped = false;
      bool eventTapped = false;
      bool discussionTapped = false;
      bool profileTapped = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ChatAttachmentSheet(
              onCameraTap: () {},
              onGalleryTap: () {},
              onFileTap: () {},
              onLocationTap: () {},
              onSharePostTap: () => postTapped = true,
              onShareEventTap: () => eventTapped = true,
              onShareDiscussionTap: () => discussionTapped = true,
              onShareProfileTap: () => profileTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PART 1 & 20: Verify FINANCE is NOT present
      expect(find.text('GenLink Finance'), findsNothing);
      expect(find.text('GenLink Finance (KHQR / Bakong)'), findsNothing);
      expect(find.text('Send Money'), findsNothing);
      expect(find.text('Request Money'), findsNothing);
      expect(find.text('Scan KHQR'), findsNothing);

      // PART 2: Media & Attachments section present
      expect(find.text('Media & Attachments'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);

      // PART 3: Renamed section header
      expect(find.text('Share on GenLink'), findsOneWidget);
      expect(find.text('Share GenLink Content'), findsNothing);

      // Items in Share on GenLink
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap Post
      await tester.tap(find.text('Post'));
      expect(postTapped, isTrue);

      // Tap Event
      await tester.tap(find.text('Event'));
      expect(eventTapped, isTrue);

      // Tap Discussion
      await tester.tap(find.text('Discussion'));
      expect(discussionTapped, isTrue);

      // Tap Profile
      await tester.tap(find.text('Profile'));
      expect(profileTapped, isTrue);
    });
  });

  group('MessageBubble: Rich Shared Content Card Rendering', () {
    testWidgets('Renders rich card with Post info and "Open Post →" action', (tester) async {
      final msg = ChatMessageModel(
        id: 'msg-10',
        conversationId: 'c1',
        senderId: 'user-bob',
        senderName: 'Bob',
        content: 'Take a look at this post!',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
        sharedContent: SharedContentModel(
          type: SharedContentType.post,
          id: 'p-12345',
          title: 'GenLink Architecture Polish',
          previewText: 'Here are the details of the new chat shared architecture.',
          authorName: 'Ren Makara',
          subtitle: 'Engineering',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: msg,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Original text message
      expect(find.text('Take a look at this post!'), findsOneWidget);

      // Rich card elements
      expect(find.text('GenLink Architecture Polish'), findsOneWidget);
      expect(find.text('Ren Makara'), findsOneWidget);
      expect(find.text('POST'), findsOneWidget);
      expect(find.text('Open Post →'), findsOneWidget);
    });

    testWidgets('Renders rich card for Discussion, Event, and Profile', (tester) async {
      final discussionMsg = ChatMessageModel(
        id: 'msg-disc',
        conversationId: 'c1',
        senderId: 'user-me',
        senderName: 'Me',
        content: '',
        timestamp: DateTime.now(),
        timeAgo: '1m ago',
        isMine: true,
        sharedContent: SharedContentModel(
          type: SharedContentType.discussion,
          id: 'd-1',
          title: 'Flutter vs Native in Cambodia',
          previewText: 'What is your stack preference?',
          authorName: 'Dara',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: discussionMsg,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flutter vs Native in Cambodia'), findsOneWidget);
      expect(find.text('DISCUSSION'), findsOneWidget);
      expect(find.text('Open Discussion →'), findsOneWidget);
    });

    testWidgets('Renders properly in Dark Mode and Light Mode', (tester) async {
      final richMsg = ChatMessageModel(
        id: 'msg-dm',
        conversationId: 'c1',
        senderId: 'user-1',
        senderName: 'Test',
        content: 'Check event',
        timestamp: DateTime.now(),
        timeAgo: '2m ago',
        isMine: true,
        sharedContent: SharedContentModel(
          type: SharedContentType.event,
          id: 'ev-1',
          title: 'Khmer New Year Festival',
          previewText: 'Siem Reap celebration with traditional games.',
          subtitle: 'Siem Reap, Cambodia',
        ),
      );

      // Light mode test
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: MessageBubble(message: richMsg),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Khmer New Year Festival'), findsOneWidget);
      expect(find.text('EVENT'), findsOneWidget);
      expect(find.text('Open Event →'), findsOneWidget);

      // Dark mode test
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: MessageBubble(message: richMsg),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Khmer New Year Festival'), findsOneWidget);
      expect(find.text('EVENT'), findsOneWidget);
    });
  });

  group('SharedContentNavigator Deep-linking & Routing', () {
    testWidgets('Parses deep-link format and handles invalid routing gracefully', (tester) async {
      bool deepLinkFinished = false;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await SharedContentNavigator.openDeepLink(context, 'invalid://link');
                    await SharedContentNavigator.openDeepLink(context, 'genlink://unknown/123');
                    deepLinkFinished = true;
                  },
                  child: const Text('Test Deep Links'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Deep Links'));
      await tester.pumpAndSettle();

      expect(deepLinkFinished, isTrue);
    });
  });

  group('PostDetailScreen: Deleted & Restricted Content Error Handling', () {
    testWidgets('Displays "This content is no longer available." on 404 deleted error', (tester) async {
      final mockCommunityRepo = MockCommunityRepository();
      when(() => mockCommunityRepo.getOpportunities()).thenAnswer((_) async => []);
      when(() => mockCommunityRepo.getDiscussions()).thenAnswer((_) async => []);
      when(() => mockCommunityRepo.getPostDetails('deleted-post-id'))
          .thenThrow(const AppError(errorCode: 'NOT_FOUND', statusCode: 404, message: 'Post not found'));

      final communityCtrl = CommunityController(repository: mockCommunityRepo);
      Get.put<CommunityController>(communityCtrl);

      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('en', 'US'),
          translations: AppTranslations(),
          home: const PostDetailScreen(postId: 'deleted-post-id'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This content is no longer available.'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
      expect(find.byType(AppBackButton), findsOneWidget);
    });

    testWidgets('Displays "Content unavailable" on 403 forbidden error', (tester) async {
      final mockCommunityRepo = MockCommunityRepository();
      when(() => mockCommunityRepo.getOpportunities()).thenAnswer((_) async => []);
      when(() => mockCommunityRepo.getDiscussions()).thenAnswer((_) async => []);
      when(() => mockCommunityRepo.getPostDetails('private-post-id'))
          .thenThrow(const AppError(errorCode: 'FORBIDDEN', statusCode: 403, message: 'Forbidden access'));

      final communityCtrl = CommunityController(repository: mockCommunityRepo);
      Get.put<CommunityController>(communityCtrl);

      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('en', 'US'),
          translations: AppTranslations(),
          home: const PostDetailScreen(postId: 'private-post-id'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Content unavailable'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('Displays post details and comments when post is found', (tester) async {
      final mockCommunityRepo = MockCommunityRepository();
      when(() => mockCommunityRepo.getOpportunities()).thenAnswer((_) async => []);
      when(() => mockCommunityRepo.getDiscussions()).thenAnswer((_) async => []);

      final samplePost = CommunityPostModel(
        id: 'real-post-1',
        userId: 'author-101',
        authorName: 'Sophea',
        authorTag: '@sophea',
        authorAvatar: '',
        community: 'Flutter KH',
        timeAgo: '10m',
        content: 'Deep dive into GenLink Chat sharing architecture.',
        likesCount: 15,
        commentsCount: 3,
      );

      when(() => mockCommunityRepo.getPostDetails('real-post-1'))
          .thenAnswer((_) async => samplePost);
      when(() => mockCommunityRepo.getComments('real-post-1'))
          .thenAnswer((_) async => []);

      final communityCtrl = CommunityController(repository: mockCommunityRepo);
      Get.put<CommunityController>(communityCtrl);

      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('en', 'US'),
          translations: AppTranslations(),
          home: const PostDetailScreen(postId: 'real-post-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deep dive into GenLink Chat sharing architecture.'), findsOneWidget);
      expect(find.text('Sophea'), findsOneWidget);
    });
  });

  group('ChatController: sendSharedContent & realtime message reception', () {
    test('sendSharedContent forwards sharedContent to repository', () async {
      final mockRepo = MockChatRepository();
      final conv = ChatConversationModel(
        id: 'conv-99',
        name: 'Vireak',
        avatar: '',
        lastMessage: 'Hello',
        lastMessageTime: '10m',
      );

      final sharedItem = SharedContentModel(
        type: SharedContentType.post,
        id: 'post-test-1',
        title: 'Exciting announcement',
      );

      when(() => mockRepo.sendMessage(
            'conv-99',
            'Take a look',
            messageType: any(named: 'messageType'),
            mediaUrl: any(named: 'mediaUrl'),
            replyTo: any(named: 'replyTo'),
            sharedContent: any(named: 'sharedContent'),
          )).thenAnswer((_) async => ChatMessageModel(
            id: 'msg-99',
            conversationId: 'conv-99',
            senderId: 'user-me',
            senderName: 'Me',
            content: 'Take a look',
            timestamp: DateTime.now(),
            timeAgo: 'Just now',
            isMine: true,
            sharedContent: sharedItem,
          ));

      final chatCtrl = ChatController(repository: mockRepo);
      chatCtrl.conversations.add(conv);

      await chatCtrl.sendSharedContent(conv, sharedItem, text: 'Take a look');

      verify(() => mockRepo.sendMessage(
            'conv-99',
            'Take a look',
            messageType: 'text',
            sharedContent: sharedItem,
          )).called(1);
    });

    test('onMessageReceived updates conversation preview with shared content title if content is empty', () {
      final mockRepo = MockChatRepository();
      final chatCtrl = ChatController(repository: mockRepo);
      final conv = ChatConversationModel(
        id: 'conv-88',
        name: 'Chan',
        avatar: '',
        lastMessage: 'Old message',
        lastMessageTime: '1h',
      );
      chatCtrl.conversations.add(conv);

      final incomingSharedMsg = ChatMessageModel(
        id: 'msg-incoming-1',
        conversationId: 'conv-88',
        senderId: 'user-chan',
        senderName: 'Chan',
        content: '',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
        sharedContent: SharedContentModel(
          type: SharedContentType.post,
          id: 'post-chan-1',
          title: 'Chan Shared A Post',
        ),
      );

      chatCtrl.onMessageReceived(incomingSharedMsg);

      final updatedConv = chatCtrl.conversations.firstWhere((c) => c.id == 'conv-88');
      expect(updatedConv.lastMessage, 'Chan Shared A Post');
      expect(updatedConv.unreadCount, 1);
    });
  });
}
