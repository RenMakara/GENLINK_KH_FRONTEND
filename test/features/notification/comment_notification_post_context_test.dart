import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/community/presentation/screens/post_detail_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/comments_bottom_sheet.dart';

class MockNotificationRepo extends Mock implements NotificationRepositoryImpl {}
class MockCommunityRepo extends Mock implements CommunityRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNotificationRepo mockNotifRepo;
  late MockCommunityRepo mockCommunityRepo;
  late NotificationController notifController;
  late CommunityController communityController;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    mockNotifRepo = MockNotificationRepo();
    mockCommunityRepo = MockCommunityRepo();

    when(() => mockNotifRepo.getNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        )).thenAnswer((_) async => NotificationPage(
          items: [],
          page: 0,
          size: 20,
          totalElements: 0,
          totalPages: 0,
          hasNext: false,
        ));
    when(() => mockNotifRepo.getUnreadCount()).thenAnswer((_) async => 0);
    when(() => mockNotifRepo.markAsRead(any())).thenAnswer((_) async => true);

    when(() => mockCommunityRepo.getPosts(page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);

    notifController = NotificationController(repository: mockNotifRepo);
    Get.put<NotificationController>(notifController);

    communityController = CommunityController(repository: mockCommunityRepo);
    Get.put<CommunityController>(communityController);
  });

  tearDown(() {
    Get.reset();
  });

  group('NotificationModel Comment/Reply Serialization & Resolution', () {
    test('Comment notification parses postId and commentId from parameters and dedupeKey', () {
      final json = {
        'id': 'notif_comment_1',
        'type': 'COMMUNITY',
        'title': 'New Comment',
        'body': 'User B commented on your post.',
        'recipientId': 'user_a',
        'actorId': 'user_b',
        'actorName': 'User B',
        'actorAvatarUrl': 'https://example.com/avatar.jpg',
        'targetId': 'post_100',
        'targetType': 'POST',
        'dedupeKey': 'post-comment:comment_200:user_b',
        'parameters': {
          'action': 'COMMENT',
          'postId': 'post_100',
          'commentId': 'comment_200',
        },
        'read': false,
        'createdAt': '2026-09-27T10:00:00Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.type, NotificationType.comment);
      expect(notif.targetId, 'post_100');
      expect(notif.postId, 'post_100');
      expect(notif.commentId, 'comment_200');
      expect(notif.parentCommentId, isNull);
    });

    test('Reply notification parses postId, commentId (reply), and parentCommentId', () {
      final json = {
        'id': 'notif_reply_1',
        'type': 'COMMUNITY',
        'title': 'New Reply',
        'body': 'User A replied to your comment.',
        'recipientId': 'user_b',
        'actorId': 'user_a',
        'actorName': 'User A',
        'targetId': 'post_100',
        'targetType': 'POST',
        'dedupeKey': 'comment-reply:reply_300:comment_200',
        'parameters': {
          'action': 'REPLY',
          'postId': 'post_100',
          'commentId': 'reply_300',
          'parentCommentId': 'comment_200',
        },
        'read': false,
        'createdAt': '2026-09-27T10:05:00Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.type, NotificationType.reply);
      expect(notif.targetId, 'post_100');
      expect(notif.postId, 'post_100');
      expect(notif.commentId, 'reply_300');
      expect(notif.parentCommentId, 'comment_200');
    });

    test('Falls back to dedupeKey parsing if parameters are absent', () {
      final json = {
        'id': 'notif_legacy_reply',
        'type': 'COMMUNITY',
        'title': 'Reply',
        'body': 'Someone replied to your comment',
        'targetId': 'post_555',
        'dedupeKey': 'comment-reply:reply_888:comment_777',
        'createdAt': '2026-09-27T10:00:00Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.type, NotificationType.reply);
      expect(notif.targetId, 'post_555');
      expect(notif.commentId, 'reply_888');
      expect(notif.parentCommentId, 'comment_777');
    });
  });

  group('Notification Navigation with Original Post Context', () {
    testWidgets('Comment notification tap navigates to PostDetailScreen with autoOpenComments and highlightCommentId', (tester) async {
      final notif = NotificationModel(
        id: 'notif_comment_tap',
        type: NotificationType.comment,
        title: 'Comment Notification',
        body: 'User B commented on your post',
        senderName: 'User B',
        timeAgo: 'Just now',
        timestamp: DateTime.now(),
        targetId: 'post_100',
        targetType: 'POST',
        metadata: {
          'postId': 'post_100',
          'commentId': 'comment_200',
        },
      );

      final dummyPost = CommunityPostModel(
        id: 'post_100',
        userId: 'user_heng',
        authorName: 'Heng Chansela',
        authorTag: '@heng',
        authorAvatar: '',
        timeAgo: '2h',
        content: 'Original post about architecture',
        likesCount: 10,
        commentsCount: 2,
        isLiked: false,
      );

      when(() => mockCommunityRepo.getPostDetails('post_100')).thenAnswer((_) async => dummyPost);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    notifController.handleNotificationTap(notif, context);
                  },
                  child: const Text('Tap Comment Notif'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Tap Comment Notif'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must navigate to PostDetailScreen
      final postDetailFinder = find.byType(PostDetailScreen);
      expect(postDetailFinder, findsOneWidget);

      final postDetailWidget = tester.widget<PostDetailScreen>(postDetailFinder);
      expect(postDetailWidget.postId, 'post_100');
      expect(postDetailWidget.autoOpenComments, isTrue);
      expect(postDetailWidget.highlightCommentId, 'comment_200');
    });

    testWidgets('Reply notification tap navigates to PostDetailScreen with reply highlightCommentId', (tester) async {
      final notif = NotificationModel(
        id: 'notif_reply_tap',
        type: NotificationType.reply,
        title: 'Reply Notification',
        body: 'User A replied to your comment',
        senderName: 'User A',
        timeAgo: 'Just now',
        timestamp: DateTime.now(),
        targetId: 'post_100',
        targetType: 'POST',
        metadata: {
          'postId': 'post_100',
          'commentId': 'reply_300',
          'parentCommentId': 'comment_200',
        },
      );

      final dummyPost = CommunityPostModel(
        id: 'post_100',
        userId: 'user_heng',
        authorName: 'Heng Chansela',
        authorTag: '@heng',
        authorAvatar: '',
        timeAgo: '2h',
        content: 'Original post about architecture',
        likesCount: 10,
        commentsCount: 2,
        isLiked: false,
      );

      when(() => mockCommunityRepo.getPostDetails('post_100')).thenAnswer((_) async => dummyPost);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    notifController.handleNotificationTap(notif, context);
                  },
                  child: const Text('Tap Reply Notif'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Tap Reply Notif'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must navigate to PostDetailScreen with highlightCommentId = reply_300
      final postDetailFinder = find.byType(PostDetailScreen);
      expect(postDetailFinder, findsOneWidget);

      final postDetailWidget = tester.widget<PostDetailScreen>(postDetailFinder);
      expect(postDetailWidget.postId, 'post_100');
      expect(postDetailWidget.autoOpenComments, isTrue);
      expect(postDetailWidget.highlightCommentId, 'reply_300');
    });

    testWidgets('Missing targetId does NOT navigate to PostDetailScreen and does not crash', (tester) async {
      final notif = NotificationModel(
        id: 'notif_missing_target',
        type: NotificationType.comment,
        title: 'Comment Notification',
        body: 'Someone commented',
        senderName: 'User B',
        timeAgo: 'Just now',
        timestamp: DateTime.now(),
        targetId: null,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    notifController.handleNotificationTap(notif, context);
                  },
                  child: const Text('Tap Missing Notif'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Tap Missing Notif'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must NOT navigate to PostDetailScreen
      expect(find.byType(PostDetailScreen), findsNothing);
      expect(find.byType(CommentsBottomSheet), findsNothing);
    });
  });

  group('Original Post Context in CommentsBottomSheet', () {
    testWidgets('CommentsBottomSheet displays Original Post preview when post is supplied', (tester) async {
      final post = CommunityPostModel(
        id: 'post_preview_1',
        userId: 'user_heng',
        authorName: 'Heng Chansela',
        authorTag: '@heng',
        authorAvatar: '',
        timeAgo: '1h',
        content: 'Today I learned something interesting about Flutter!',
        likesCount: 15,
        commentsCount: 3,
        isLiked: false,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: CommentsBottomSheet(
              postId: 'post_preview_1',
              post: post,
              highlightCommentId: 'comment_99',
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify "Original Post" badge/label is rendered
      expect(find.text('Original Post'), findsOneWidget);
      // Verify author name is rendered
      expect(find.text('Heng Chansela'), findsOneWidget);
      // Verify post content is rendered in the preview
      expect(find.text('Today I learned something interesting about Flutter!'), findsOneWidget);
    });

    testWidgets('PostDetailScreen displays unavailable state when post is deleted or 404', (tester) async {
      when(() => mockCommunityRepo.getPostDetails('deleted_post_999'))
          .thenThrow(const AppError(message: 'Post not found', errorCode: 'NOT_FOUND', statusCode: 404));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const PostDetailScreen(
            postId: 'deleted_post_999',
            autoOpenComments: true,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Shows unavailable state
      expect(find.text('This content is no longer available.'), findsOneWidget);
      // Does NOT show comments bottom sheet
      expect(find.byType(CommentsBottomSheet), findsNothing);
    });

    testWidgets('CommentsBottomSheet renders comments and replies with nonexistent highlight without error', (tester) async {
      final reply = CommentModel(
        id: 'reply_500',
        postId: 'post_100',
        userId: 'user_reply',
        userName: 'Heng Chansela',
        userAvatar: '',
        text: 'This is a reply to comment 1',
        timeAgo: '1m',
        parentCommentId: 'comment_1',
      );

      final parentComment = CommentModel(
        id: 'comment_1',
        postId: 'post_100',
        userId: 'user_c1',
        userName: 'Ren Makara',
        userAvatar: '',
        text: 'This is the main comment',
        timeAgo: '5m',
        replies: [reply],
      );

      when(() => mockCommunityRepo.getComments('post_100')).thenAnswer((_) async => [parentComment]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: CommentsBottomSheet(
              postId: 'post_100',
              highlightCommentId: 'non_existent_comment_id',
            ),
          ),
        ),
      );

      await tester.pump();

      // Comments sheet should render comments cleanly without crashing even if highlight ID does not match
      expect(find.text('This is the main comment'), findsOneWidget);
      expect(find.text('This is a reply to comment 1'), findsOneWidget);
    });
  });
}
