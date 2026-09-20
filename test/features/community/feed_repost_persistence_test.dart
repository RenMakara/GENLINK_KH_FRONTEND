import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/data/datasources/community_remote_datasource.dart';
import 'package:genlink_frontend/features/community/data/repositories/community_repository_impl.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSecureStorage implements SecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalizationService extends GetxService implements LocalizationService {
  @override
  final language = 'en'.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({
    required this.handler,
  });

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(dynamic data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late AuthController authController;

  setUp(() {
    Get.reset();
    Get.testMode = true;

    authController = AuthController(
      authRepository: _FakeAuthRepository(),
      secureStorage: _FakeSecureStorage(),
      localization: _FakeLocalizationService(),
    );
    authController.currentUser.value = const UserEntity(
      id: 'user-uuid-me',
      fullName: 'Sokny Enat',
      username: 'soknyenat',
      email: 'sokny@genlink.kh',
      active: true,
      emailVerified: true,
      accountStatus: 'ACTIVE',
      preferredLanguage: 'en',
      role: 'USER',
      totalXp: 100,
      level: 1,
    );
    Get.put<AuthController>(authController);
  });

  tearDown(() {
    Get.reset();
  });

  group('GENLINK KH HOME FEED Repost Persistence & Contract Tests', () {
    test('1. CommunityPostModel correctly parses repost metadata from backend response', () {
      final backendJson = {
        'postId': 'post-uuid-101',
        'author': {
          'userId': 'author-uuid-2',
          'fullName': 'Ren Makara',
          'username': 'renmakara',
          'avatarUrl': 'https://example.com/avatar.png',
        },
        'contentText': 'Learn Spring Boot Microservices and Flutter',
        'imageUrl': null,
        'videoUrl': null,
        'postType': 'TEXT',
        'visibility': 'PUBLIC',
        'language': 'ENGLISH',
        'likeCount': 10,
        'commentCount': 4,
        'repostCount': 3,
        'likedByMe': false,
        'savedByMe': false,
        'repostedByMe': true,
        'repostedBy': 'You',
        'repostCaption': 'Insightful read for developers!',
        'reposterId': 'user-uuid-me',
        'originalPostId': 'post-uuid-101',
        'hashtags': ['#SpringBoot', '#Flutter'],
        'poll': null,
        'createdAt': '2026-09-18T10:00:00Z',
      };

      final post = CommunityPostModel.fromJson(backendJson);

      expect(post.id, 'post-uuid-101');
      expect(post.sharesCount, 3);
      expect(post.repostsCount, 3);
      expect(post.isRepostedByMe, isTrue);
      expect(post.repostedBy, 'You');
      expect(post.repostCaption, 'Insightful read for developers!');
      expect(post.originalPostId, 'post-uuid-101');
      expect(post.reposterId, 'user-uuid-me');

      final serialized = post.toJson();
      expect(serialized['repostCount'], 3);
      expect(serialized['repostsCount'], 3);
      expect(serialized['repostedByMe'], isTrue);
      expect(serialized['isRepostedByMe'], isTrue);
    });

    test('2. Repost creation: User taps Repost -> Sends POST request with caption -> Backend persists', () async {
      RequestOptions? capturedOptions;
      bool serverPersistedRepost = false;
      int serverRepostCount = 0;

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async {
            capturedOptions = options;
            if (options.method == 'POST' && options.path.contains('/repost')) {
              serverPersistedRepost = true;
              serverRepostCount = 1;
              final data = options.data as Map<String, dynamic>? ?? {};
              return _jsonResponse({
                'status': 200,
                'message': 'Post reposted',
                'data': {
                  'postId': 'post-uuid-200',
                  'repostCount': serverRepostCount,
                  'repostedByMe': true,
                  'repostedBy': 'You',
                  'repostCaption': data['caption'],
                  'reposterId': 'user-uuid-me',
                  'originalPostId': 'post-uuid-200',
                },
              });
            }
            return _jsonResponse({'status': 400, 'message': 'Unknown route'}, statusCode: 400);
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repo = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      final initialPost = CommunityPostModel(
        id: 'post-uuid-200',
        userId: 'other-author-id',
        authorName: 'Other Author',
        authorTag: '@other',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'Original content to repost',
        sharesCount: 0,
        isRepostedByMe: false,
      );
      controller.posts.assignAll([initialPost]);

      // Trigger repost
      controller.repostPost('post-uuid-200', caption: 'Check this out!');

      // Immediate optimistic update
      expect(controller.posts.first.isRepostedByMe, isTrue);
      expect(controller.posts.first.repostsCount, 1);
      expect(controller.posts.first.sharesCount, 1);
      expect(controller.posts.first.repostCaption, 'Check this out!');

      // Allow async dio request to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify network request was sent to correct endpoint
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.method, 'POST');
      expect(capturedOptions!.path, contains('/community/posts/post-uuid-200/repost'));
      expect((capturedOptions!.data as Map<String, dynamic>)['caption'], 'Check this out!');

      // Verify backend state
      expect(serverPersistedRepost, isTrue);
      expect(serverRepostCount, 1);
    });

    test('3. Duplicate prevention: Cannot repost own post, and cannot duplicate already reposted post', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async => _jsonResponse({'status': 200, 'message': 'OK', 'data': {}}),
        );
      final mockRepo = CommunityRepositoryImpl(remoteDataSource: CommunityRemoteDataSource(dio: dio));
      final controller = CommunityController(repository: mockRepo);
      Get.put<CommunityController>(controller);

      final ownPost = CommunityPostModel(
        id: 'post-own-1',
        userId: 'user-uuid-me',
        authorName: 'Sokny Enat',
        authorTag: '@soknyenat',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'My own post',
        sharesCount: 0,
        isOwner: true,
      );

      final otherPost = CommunityPostModel(
        id: 'post-other-2',
        userId: 'user-other-99',
        authorName: 'Other Person',
        authorTag: '@otherperson',
        authorAvatar: '',
        timeAgo: '30m ago',
        content: 'Other post',
        sharesCount: 2,
        isRepostedByMe: false,
      );

      controller.posts.assignAll([ownPost, otherPost]);

      // Attempt 1: Reposting own post is prevented by controller guard
      controller.repostPost('post-own-1');
      expect(controller.posts[0].isRepostedByMe, isFalse);
      expect(controller.posts[0].repostsCount, 0);

      // Attempt 2: Reposting other post succeeds
      controller.repostPost('post-other-2', caption: 'Initial quote');
      expect(controller.posts[1].isRepostedByMe, isTrue);
      expect(controller.posts[1].repostsCount, 3);

      // Attempt 3: Reposting same post again is blocked (duplicate prevention)
      controller.repostPost('post-other-2', caption: 'Duplicate quote');
      expect(controller.posts[1].repostsCount, 3);
      expect(controller.posts[1].repostCaption, 'Initial quote');

      await Future<void>.delayed(const Duration(milliseconds: 30));
    });

    test('4. Feed re-fetch & Persistence after refresh: Refreshing the feed preserves repost state and count', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async {
            if (options.method == 'GET' && options.path.contains('/feed')) {
              return _jsonResponse({
                'status': 200,
                'message': 'Feed retrieved',
                'data': {
                  'content': [
                    {
                      'postId': 'post-uuid-300',
                      'author': {
                        'userId': 'author-3',
                        'fullName': 'Dara Roth',
                        'username': 'dararoth',
                        'avatarUrl': '',
                      },
                      'contentText': 'Important campus announcement',
                      'repostCount': 1,
                      'repostedByMe': true,
                      'repostedBy': 'You',
                      'repostCaption': 'Please share with classmates',
                      'reposterId': 'user-uuid-me',
                      'originalPostId': 'post-uuid-300',
                      'likeCount': 5,
                      'commentCount': 2,
                      'likedByMe': false,
                      'savedByMe': false,
                      'createdAt': '2026-09-18T09:00:00Z',
                    }
                  ],
                  'page': 0,
                  'size': 10,
                  'totalElements': 1,
                  'totalPages': 1,
                  'hasNext': false,
                },
              });
            }
            return _jsonResponse({'status': 400, 'message': 'Unknown route'}, statusCode: 400);
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repo = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // 1. Initial feed fetch
      await controller.fetchPosts();
      expect(controller.posts.length, 1);
      expect(controller.posts.first.id, 'post-uuid-300');
      expect(controller.posts.first.isRepostedByMe, isTrue);
      expect(controller.posts.first.repostsCount, 1);
      expect(controller.posts.first.repostedBy, 'You');
      expect(controller.posts.first.repostCaption, 'Please share with classmates');

      // 2. User refreshes the Feed (e.g. pull to refresh)
      await controller.refreshFeed();

      // Repost MUST persist after refresh
      expect(controller.posts.length, 1);
      final refreshedPost = controller.posts.first;
      expect(refreshedPost.isRepostedByMe, isTrue);
      expect(refreshedPost.repostsCount, 1);
      expect(refreshedPost.sharesCount, 1);
      expect(refreshedPost.repostedBy, 'You');
      expect(refreshedPost.repostCaption, 'Please share with classmates');
      expect(refreshedPost.reposterId, 'user-uuid-me');
    });

    test('5. Unrepost / Undo: User unreposts -> Sends DELETE -> count decrements -> persists after refresh', () async {
      int serverRepostCount = 1;
      bool isRepostedOnServer = true;
      String? deleteMethod;
      String? deletePath;

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async {
            if (options.method == 'DELETE' && options.path.contains('/repost')) {
              deleteMethod = options.method;
              deletePath = options.path;
              serverRepostCount = 0;
              isRepostedOnServer = false;
              return _jsonResponse({
                'status': 200,
                'message': 'Post unreposted',
                'data': {
                  'postId': 'post-uuid-400',
                  'repostCount': 0,
                  'repostedByMe': false,
                  'repostedBy': null,
                  'repostCaption': null,
                  'reposterId': null,
                },
              });
            }
            if (options.method == 'GET' && options.path.contains('/feed')) {
              return _jsonResponse({
                'status': 200,
                'message': 'Feed retrieved',
                'data': {
                  'content': [
                    {
                      'postId': 'post-uuid-400',
                      'author': {
                        'userId': 'author-4',
                        'fullName': 'Bopha Chea',
                        'username': 'bophachea',
                        'avatarUrl': '',
                      },
                      'contentText': 'Post that was previously reposted',
                      'repostCount': serverRepostCount,
                      'repostedByMe': isRepostedOnServer,
                      'repostedBy': isRepostedOnServer ? 'You' : null,
                      'repostCaption': null,
                      'likeCount': 3,
                      'commentCount': 1,
                      'likedByMe': false,
                      'savedByMe': false,
                      'createdAt': '2026-09-18T08:00:00Z',
                    }
                  ],
                  'page': 0,
                  'size': 10,
                  'totalElements': 1,
                  'totalPages': 1,
                  'hasNext': false,
                },
              });
            }
            return _jsonResponse({'status': 400, 'message': 'Unknown route'}, statusCode: 400);
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repo = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Load initial feed where post is reposted
      await controller.fetchPosts();
      expect(controller.posts.first.isRepostedByMe, isTrue);
      expect(controller.posts.first.repostsCount, 1);

      // User triggers unrepost
      controller.unrepostPost('post-uuid-400');

      // Immediate optimistic update
      expect(controller.posts.first.isRepostedByMe, isFalse);
      expect(controller.posts.first.repostsCount, 0);
      expect(controller.posts.first.repostedBy, isNull);

      // Wait for async delete request
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(deleteMethod, 'DELETE');
      expect(deletePath, contains('/community/posts/post-uuid-400/repost'));
      expect(serverRepostCount, 0);
      expect(isRepostedOnServer, isFalse);

      // Refresh feed from server
      await controller.refreshFeed();

      // Post must remain unreposted after refresh
      expect(controller.posts.first.isRepostedByMe, isFalse);
      expect(controller.posts.first.repostsCount, 0);
      expect(controller.posts.first.repostedBy, isNull);
    });

    testWidgets('6. PostCardWidget displays active repost icon and banner based on persisted state', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async => _jsonResponse({'status': 200, 'message': 'OK', 'data': {}}),
        );
      final mockRepo = CommunityRepositoryImpl(remoteDataSource: CommunityRemoteDataSource(dio: dio));
      final controller = CommunityController(repository: mockRepo);
      Get.put<CommunityController>(controller);

      final repostedPost = CommunityPostModel(
        id: 'post-card-test-1',
        userId: 'other-user',
        authorName: 'Heng Chansela',
        authorTag: '@hengchansela',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Campus life at ACLEDA University',
        sharesCount: 4,
        isRepostedByMe: true,
        repostedBy: 'You',
        repostCaption: 'Great campus memories!',
        originalPostId: 'post-card-test-1',
        reposterId: 'user-uuid-me',
      );

      controller.posts.assignAll([repostedPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: repostedPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify repost banner
      expect(find.text('You reposted'), findsOneWidget);
      expect(find.text('Great campus memories!'), findsOneWidget);

      // Verify repost count display
      expect(find.text('4'), findsOneWidget);

      // Verify menu shows "Unrepost" since isRepostedByMe is true
      await tester.tap(find.byTooltip('Options'));
      await tester.pumpAndSettle();
      expect(find.text('Unrepost'), findsOneWidget);
    });
  });
}
