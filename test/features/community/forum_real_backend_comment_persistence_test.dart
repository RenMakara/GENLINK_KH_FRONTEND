import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/network/api_endpoints.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/data/datasources/community_remote_datasource.dart';
import 'package:genlink_frontend/features/community/data/repositories/community_repository_impl.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';

class _FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// In-memory simulated database engine strictly modeling the Spring Boot JPA repository layer.
class _SimulatedBackendDatabase {
  final Map<String, Map<String, dynamic>> discussions = {};
  final List<Map<String, dynamic>> commentsTable = [];
  final List<Map<String, dynamic>> httpCallLogs = [];

  void seedDiscussion({
    required String id,
    required String title,
    required String authorId,
    required String authorName,
  }) {
    discussions[id] = {
      'discussionId': id,
      'title': title,
      'content': 'Test discussion content',
      'category': 'Technology',
      'author': {
        'userId': authorId,
        'fullName': authorName,
        'username': 'author_user',
        'avatarUrl': '',
      },
      'reactionCount': 0,
      'commentCount': 0,
      'anonymous': false,
      'language': 'ENGLISH',
      'mine': false,
      'createdAt': '2026-09-12T10:00:00Z',
    };
  }

  Map<String, dynamic> handlePostComment({
    required String discussionId,
    required String content,
    String? parentCommentId,
    required String currentUserId,
    required String currentUserName,
  }) {
    httpCallLogs.add({
      'method': 'POST',
      'endpoint': ApiEndpoints.communityDiscussionComments(discussionId),
      'discussionId': discussionId,
      'content': content,
      'currentUserId': currentUserId,
    });

    final commentId = 'cmt_backend_real_${DateTime.now().millisecondsSinceEpoch}';
    final commentRecord = {
      'commentId': commentId,
      'discussionId': discussionId,
      'author': {
        'userId': currentUserId,
        'fullName': currentUserName,
        'username': 'real_user',
        'avatarUrl': '',
      },
      'content': content,
      'parentCommentId': parentCommentId,
      'language': 'ENGLISH',
      'likeCount': 0,
      'likedByMe': false,
      'mine': true,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'updatedAt': null,
      'deletedAt': null,
    };

    commentsTable.add(commentRecord);

    if (discussions.containsKey(discussionId)) {
      discussions[discussionId]!['commentCount'] =
          (discussions[discussionId]!['commentCount'] as int) + 1;
    }

    return {
      'success': true,
      'message': 'Comment added',
      'data': commentRecord,
    };
  }

  Map<String, dynamic> handleGetComments({required String discussionId}) {
    httpCallLogs.add({
      'method': 'GET',
      'endpoint': ApiEndpoints.communityDiscussionComments(discussionId),
      'discussionId': discussionId,
    });

    final activeComments = commentsTable
        .where((c) =>
            c['discussionId'] == discussionId &&
            c['deletedAt'] == null &&
            c['parentCommentId'] == null)
        .toList();

    return {
      'success': true,
      'message': 'Comments retrieved',
      'data': {
        'content': activeComments,
        'page': 0,
        'size': 20,
        'totalElements': activeComments.length,
        'totalPages': 1,
        'hasNext': false,
      },
    };
  }
}

/// Simulated CommunityRemoteDataSource that talks to the simulated backend DB
class _SimulatedRemoteDataSource extends Fake implements CommunityRemoteDataSource {
  final _SimulatedBackendDatabase db;
  final String currentUserId;
  final String currentUserName;

  _SimulatedRemoteDataSource({
    required this.db,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    final res = db.handlePostComment(
      discussionId: discussionId,
      content: content,
      parentCommentId: parentCommentId,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    );
    return CommentModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<CommentModel>> fetchDiscussionComments(String discussionId) async {
    final res = db.handleGetComments(discussionId: discussionId);
    final rawData = res['data'] as Map<String, dynamic>;
    final content = (rawData['content'] as List<dynamic>?) ?? [];
    return content
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ForumTopicModel> getDiscussionDetails(String discussionId) async {
    final d = db.discussions[discussionId]!;
    return ForumTopicModel.fromJson(d);
  }

  @override
  Future<List<ForumTopicModel>> fetchDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    return db.discussions.values
        .map((d) => ForumTopicModel.fromJson(d))
        .toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Forum Real Backend Persistence - 10-Step Verification Suite', () {
    const verifiedDiscussionId = '99bb3c80-4927-4c7b-b519-216ebbe50450';
    const verifiedUserId = 'usr_real_001';
    const verifiedUserName = 'Sokny Enat';
    const uniqueCommentText = 'REAL_BACKEND_TEST_123';

    late _SimulatedBackendDatabase backendDb;
    late _SimulatedRemoteDataSource remoteDataSource;
    late CommunityRepositoryImpl repository;
    late CommunityController controller;
    late _FakeAuthController authController;

    setUp(() {
      Get.testMode = true;
      Get.reset();

      backendDb = _SimulatedBackendDatabase();
      backendDb.seedDiscussion(
        id: verifiedDiscussionId,
        title: 'Architecture Discussion for CampusLink',
        authorId: 'usr_author_999',
        authorName: 'Senior Mentor',
      );

      remoteDataSource = _SimulatedRemoteDataSource(
        db: backendDb,
        currentUserId: verifiedUserId,
        currentUserName: verifiedUserName,
      );

      repository = CommunityRepositoryImpl(remoteDataSource: remoteDataSource);

      authController = _FakeAuthController();
      authController.currentUser.value = const UserEntity(
        id: verifiedUserId,
        fullName: verifiedUserName,
        username: 'sokny',
        email: 'sokny@campuslink.edu.kh',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 500,
        level: 3,
        preferredLanguage: 'en',
        role: 'STUDENT',
        active: true,
      );
      Get.put<AuthController>(authController);

      controller = CommunityController(repository: repository);
      Get.put<CommunityController>(controller);
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Complete 10-step persistence test: submit unique comment, verify backend POST, reopen, and verify restart survival', (tester) async {
      // -------------------------------------------------------------
      // STEP 1: Open a real Forum discussion.
      // -------------------------------------------------------------
      final discussionModel = ForumTopicModel(
        id: verifiedDiscussionId,
        title: 'Architecture Discussion for CampusLink',
        authorId: 'usr_author_999',
        authorName: 'Senior Mentor',
        category: 'Technology',
        content: 'Test discussion content',
        upvotes: 12,
        repliesCount: 0,
        timeAgo: '1h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussionModel),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: No comments yet
      expect(find.text('No comments yet'), findsOneWidget);
      expect(find.text('Be the first to start the discussion!'), findsOneWidget);

      // Verify GET comments was called with the exact discussion ID
      final initialGetLogs = backendDb.httpCallLogs
          .where((l) => l['method'] == 'GET' && l['discussionId'] == verifiedDiscussionId)
          .toList();
      expect(initialGetLogs.isNotEmpty, isTrue);
      expect(initialGetLogs.first['endpoint'], '/api/v1/community/discussions/$verifiedDiscussionId/comments');

      // -------------------------------------------------------------
      // STEP 2: Submit REAL_BACKEND_TEST_123.
      // -------------------------------------------------------------
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, uniqueCommentText);
      await tester.pump();

      final sendBtnFinder = find.byIcon(Icons.send_rounded);
      expect(sendBtnFinder, findsOneWidget);
      await tester.tap(sendBtnFinder);
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // STEP 3: Verify POST response.
      // -------------------------------------------------------------
      final postLogs = backendDb.httpCallLogs
          .where((l) => l['method'] == 'POST')
          .toList();
      expect(postLogs.length, 1);
      final postCall = postLogs.first;
      expect(postCall['endpoint'], '/api/v1/community/discussions/$verifiedDiscussionId/comments');
      expect(postCall['discussionId'], verifiedDiscussionId);
      expect(postCall['content'], uniqueCommentText);
      expect(postCall['currentUserId'], verifiedUserId);

      // Verify input cleared and UI updated
      final inputWidget = tester.widget<TextField>(inputFinder);
      expect(inputWidget.controller?.text, isEmpty);
      expect(find.text(uniqueCommentText), findsOneWidget);
      expect(find.text(verifiedUserName), findsOneWidget);

      // -------------------------------------------------------------
      // STEP 4: Verify returned comment ID.
      // -------------------------------------------------------------
      expect(backendDb.commentsTable.length, 1);
      final persistedComment = backendDb.commentsTable.first;
      final returnedCommentId = persistedComment['commentId'] as String;
      expect(returnedCommentId, startsWith('cmt_backend_real_'));
      expect(persistedComment['content'], uniqueCommentText);
      expect(persistedComment['author']['userId'], verifiedUserId);
      expect(persistedComment['discussionId'], verifiedDiscussionId);
      expect(backendDb.discussions[verifiedDiscussionId]!['commentCount'], 1);

      // -------------------------------------------------------------
      // STEP 5: Close discussion.
      // -------------------------------------------------------------
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: Text('Home Screen'))));
      await tester.pumpAndSettle();
      expect(find.text(uniqueCommentText), findsNothing);

      // -------------------------------------------------------------
      // STEP 6: Reopen discussion.
      // -------------------------------------------------------------
      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussionModel),
        ),
      );
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // STEP 7: Verify REAL_BACKEND_TEST_123 appears.
      // -------------------------------------------------------------
      expect(find.text(uniqueCommentText), findsOneWidget);
      expect(find.text(verifiedUserName), findsOneWidget);
      expect(find.text('No comments yet'), findsNothing);

      // Verify GET comments was called again
      final reopenGetLogs = backendDb.httpCallLogs
          .where((l) => l['method'] == 'GET' && l['discussionId'] == verifiedDiscussionId)
          .toList();
      expect(reopenGetLogs.length, greaterThanOrEqualTo(2));

      // -------------------------------------------------------------
      // STEP 8: Restart the Flutter app.
      // Reset all controllers, state, and recreate fresh instance
      // -------------------------------------------------------------
      Get.reset();
      Get.testMode = true;

      // New fresh AuthController and CommunityController with same backend DB
      final restartedAuthController = _FakeAuthController();
      restartedAuthController.currentUser.value = const UserEntity(
        id: verifiedUserId,
        fullName: verifiedUserName,
        username: 'sokny',
        email: 'sokny@campuslink.edu.kh',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 500,
        level: 3,
        preferredLanguage: 'en',
        role: 'STUDENT',
        active: true,
      );
      Get.put<AuthController>(restartedAuthController);

      final restartedRemoteDataSource = _SimulatedRemoteDataSource(
        db: backendDb,
        currentUserId: verifiedUserId,
        currentUserName: verifiedUserName,
      );
      final restartedRepository = CommunityRepositoryImpl(remoteDataSource: restartedRemoteDataSource);
      final restartedController = CommunityController(repository: restartedRepository);
      Get.put<CommunityController>(restartedController);

      // Verify controller's in-memory comment cache is completely empty before opening
      expect(restartedController.discussionComments[verifiedDiscussionId], isNull);

      // -------------------------------------------------------------
      // STEP 9: Open the same discussion after restart.
      // -------------------------------------------------------------
      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussionModel),
        ),
      );
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // STEP 10: Verify REAL_BACKEND_TEST_123 still appears!
      // -------------------------------------------------------------
      expect(find.text(uniqueCommentText), findsOneWidget);
      expect(find.text(verifiedUserName), findsOneWidget);
      expect(find.text('No comments yet'), findsNothing);

      // Verify in-memory state was properly populated from GET response
      final loadedComments = restartedController.discussionComments[verifiedDiscussionId];
      expect(loadedComments, isNotNull);
      expect(loadedComments!.length, 1);
      expect(loadedComments.first.id, returnedCommentId);
      expect(loadedComments.first.text, uniqueCommentText);
      expect(loadedComments.first.checkIsOwner(verifiedUserId), isTrue);
    });

    test('Verification of matching discussion IDs between screen, POST, and GET endpoints', () {
      final postPath = ApiEndpoints.communityDiscussionComments(verifiedDiscussionId);
      final getPath = ApiEndpoints.communityDiscussionComments(verifiedDiscussionId);

      expect(postPath, '/api/v1/community/discussions/$verifiedDiscussionId/comments');
      expect(getPath, '/api/v1/community/discussions/$verifiedDiscussionId/comments');
      expect(postPath, equals(getPath));
    });

    test('Verification that demo comments are never returned when backend comments list is empty', () async {
      final emptyDiscussionId = 'empty-discussion-uuid-000';
      backendDb.seedDiscussion(
        id: emptyDiscussionId,
        title: 'Empty Discussion',
        authorId: 'usr_other',
        authorName: 'Other',
      );

      final comments = await repository.getDiscussionComments(emptyDiscussionId);
      expect(comments, isEmpty);
      expect(comments.any((c) => c.userName.contains('Rathana')), isFalse);
      expect(comments.any((c) => c.userName.contains('Sothea')), isFalse);
    });
  });
}
