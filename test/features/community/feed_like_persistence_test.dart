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
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_liked_by_sheet.dart';

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
      id: 'user-me-123',
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

  group('GENLINK KH HOME FEED Like & Liked-By Persistence & Contract Tests', () {
    test('1. CommunityPostModel correctly parses likeCount and likedByMe from backend response', () {
      final backendJson = {
        'postId': 'post-100',
        'author': {
          'userId': 'author-1',
          'fullName': 'Dara Chan',
          'username': 'darachan',
          'avatarUrl': 'https://example.com/dara.jpg',
        },
        'contentText': 'Exploring Phnom Penh tech hub! #tech',
        'likeCount': 15,
        'commentCount': 3,
        'repostCount': 2,
        'likedByMe': true,
        'savedByMe': false,
        'repostedByMe': false,
        'createdAt': '2026-09-18T10:00:00Z',
      };

      final post = CommunityPostModel.fromJson(backendJson);
      expect(post.id, 'post-100');
      expect(post.likesCount, 15);
      expect(post.isLiked, isTrue);
      expect(post.authorName, 'Dara Chan');
    });

    test('2. PostLikerModel parses public user summary correctly without exposing sensitive fields', () {
      final likerJson = {
        'userId': 'liker-uuid-456',
        'fullName': 'Vannak Heng',
        'username': 'vannak',
        'avatarUrl': 'https://example.com/vannak.jpg',
      };

      final liker = PostLikerModel.fromJson(likerJson);
      expect(liker.id, 'liker-uuid-456');
      expect(liker.fullName, 'Vannak Heng');
      expect(liker.username, '@vannak');
      expect(liker.avatarUrl, 'https://example.com/vannak.jpg');

      final serialized = liker.toJson();
      expect(serialized['id'], 'liker-uuid-456');
      expect(serialized['fullName'], 'Vannak Heng');
      expect(serialized.containsKey('email'), isFalse);
      expect(serialized.containsKey('phoneNumber'), isFalse);
    });

    test('3. Like flow: User taps Like -> Sends POST /api/v1/community/posts/{id}/like', () async {
      final capturedRequests = <RequestOptions>[];
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        capturedRequests.add(options);
        if (options.path.endsWith('/like') && options.method == 'POST') {
          return _jsonResponse({
            'success': true,
            'message': 'Post liked',
            'data': {'likeCount': 6},
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);

      final initialPost = CommunityPostModel(
        id: 'post-test-1',
        userId: 'author-9',
        authorName: 'Sophea Keo',
        authorTag: '@sophea',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Clean architecture in Flutter & Spring Boot',
        likesCount: 5,
        isLiked: false,
      );
      controller.posts.assignAll([initialPost]);

      expect(controller.posts.first.isLiked, isFalse);
      expect(controller.posts.first.likesCount, 5);

      controller.toggleLike('post-test-1');

      // Optimistic state updates immediately
      expect(controller.posts.first.isLiked, isTrue);
      expect(controller.posts.first.likesCount, 6);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verifies backend received POST request
      expect(capturedRequests.length, 1);
      expect(capturedRequests.first.method, 'POST');
      expect(capturedRequests.first.path, contains('/community/posts/post-test-1/like'));
    });

    test('4. Unlike flow: User taps Like when already liked -> Sends DELETE /api/v1/community/posts/{id}/like', () async {
      final capturedRequests = <RequestOptions>[];
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        capturedRequests.add(options);
        if (options.path.endsWith('/like') && options.method == 'DELETE') {
          return _jsonResponse({
            'success': true,
            'message': 'Post unliked',
            'data': {'likeCount': 5},
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);

      final likedPost = CommunityPostModel(
        id: 'post-test-2',
        userId: 'author-9',
        authorName: 'Sophea Keo',
        authorTag: '@sophea',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Clean architecture in Flutter & Spring Boot',
        likesCount: 6,
        isLiked: true, // currently liked
      );
      controller.posts.assignAll([likedPost]);

      expect(controller.posts.first.isLiked, isTrue);
      expect(controller.posts.first.likesCount, 6);

      // User taps like to unlike
      controller.toggleLike('post-test-2');

      // Count decrements and isLiked becomes false
      expect(controller.posts.first.isLiked, isFalse);
      expect(controller.posts.first.likesCount, 5);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verifies backend received DELETE request (not POST)
      expect(capturedRequests.length, 1);
      expect(capturedRequests.first.method, 'DELETE');
      expect(capturedRequests.first.path, contains('/community/posts/post-test-2/like'));
    });

    test('5. Feed re-fetch & Persistence after refresh: Refreshing the feed preserves liked state and count', () async {
      bool isPostLikedInDb = true;
      int dbLikeCount = 12;

      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        if (options.path.endsWith('/feed')) {
          return _jsonResponse({
            'success': true,
            'data': {
              'content': [
                {
                  'postId': 'post-persistent-1',
                  'author': {
                    'userId': 'author-10',
                    'fullName': 'Visal Meas',
                    'username': 'visal',
                  },
                  'contentText': 'Persistence verified!',
                  'likeCount': dbLikeCount,
                  'commentCount': 2,
                  'repostCount': 0,
                  'likedByMe': isPostLikedInDb,
                  'savedByMe': false,
                  'repostedByMe': false,
                  'createdAt': '2026-09-18T10:00:00Z',
                }
              ],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'last': true,
            },
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);

      await controller.fetchPosts(isRefresh: true);
      expect(controller.posts.length, 1);
      expect(controller.posts.first.isLiked, isTrue);
      expect(controller.posts.first.likesCount, 12);

      // Simulate feed refresh after user unlikes in DB
      isPostLikedInDb = false;
      dbLikeCount = 11;

      await controller.fetchPosts(isRefresh: true);
      expect(controller.posts.length, 1);
      expect(controller.posts.first.isLiked, isFalse);
      expect(controller.posts.first.likesCount, 11);
    });

    test('6. Liked-user endpoint & pagination: fetchPostLikers calls GET /community/posts/{id}/likes', () async {
      final capturedRequests = <RequestOptions>[];
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        capturedRequests.add(options);
        if (options.path.endsWith('/likes')) {
          return _jsonResponse({
            'success': true,
            'data': {
              'content': [
                {
                  'userId': 'liker-1',
                  'fullName': 'Chann Sreymom',
                  'username': 'sreymom',
                  'avatarUrl': 'https://example.com/sreymom.jpg',
                },
                {
                  'userId': 'liker-2',
                  'fullName': 'Bora Bun',
                  'username': 'borabun',
                  'avatarUrl': '',
                }
              ],
              'page': 0,
              'size': 20,
              'totalElements': 2,
              'totalPages': 1,
              'last': true,
            },
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);

      final likers = await controller.fetchPostLikers('post-likes-test', page: 0, size: 20);

      expect(likers.length, 2);
      expect(likers[0].fullName, 'Chann Sreymom');
      expect(likers[0].username, '@sreymom');
      expect(likers[1].fullName, 'Bora Bun');
      expect(likers[1].username, '@borabun');

      expect(capturedRequests.length, 1);
      expect(capturedRequests.first.method, 'GET');
      expect(capturedRequests.first.path, contains('/community/posts/post-likes-test/likes'));
      expect(capturedRequests.first.queryParameters['page'], 0);
      expect(capturedRequests.first.queryParameters['size'], 20);
    });

    testWidgets('7. Bottom sheet displays real users who liked the post', (tester) async {
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        if (options.path.endsWith('/likes')) {
          return _jsonResponse({
            'success': true,
            'data': {
              'content': [
                {
                  'userId': 'user-liker-1',
                  'fullName': 'Sovan Phalla',
                  'username': 'sovanp',
                  'avatarUrl': '',
                },
                {
                  'userId': 'user-liker-2',
                  'fullName': 'Kalyan Som',
                  'username': 'kalyans',
                  'avatarUrl': '',
                },
              ],
              'page': 0,
              'size': 20,
              'totalElements': 2,
              'totalPages': 1,
              'last': true,
            },
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      Get.put(CommunityController(repository: repository));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  PostLikedBySheet.show(context, postId: 'test-post-real-users');
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(PostLikedBySheet), findsOneWidget);
      expect(find.text('Sovan Phalla'), findsOneWidget);
      expect(find.text('@sovanp'), findsOneWidget);
      expect(find.text('Kalyan Som'), findsOneWidget);
      expect(find.text('@kalyans'), findsOneWidget);
    });

    testWidgets('8. Bottom sheet displays empty state when post has no likes', (tester) async {
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        if (options.path.endsWith('/likes')) {
          return _jsonResponse({
            'success': true,
            'data': {
              'content': [],
              'page': 0,
              'size': 20,
              'totalElements': 0,
              'totalPages': 0,
              'last': true,
            },
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      Get.put(CommunityController(repository: repository));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  PostLikedBySheet.show(context, postId: 'empty-post');
                },
                child: const Text('Open Empty'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Empty'));
      await tester.pumpAndSettle();

      expect(find.byType(PostLikedBySheet), findsOneWidget);
      expect(find.text('No likes yet'), findsOneWidget);
    });

    testWidgets('9. Bottom sheet displays error state with retry on failure', (tester) async {
      bool shouldFail = true;
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        if (options.path.endsWith('/likes')) {
          if (shouldFail) {
            return _jsonResponse({'message': 'Server Error'}, statusCode: 500);
          }
          return _jsonResponse({
            'success': true,
            'data': {
              'content': [
                {
                  'userId': 'recovered-user',
                  'fullName': 'Recovered User',
                  'username': 'recovered',
                }
              ],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'last': true,
            },
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      Get.put(CommunityController(repository: repository));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  PostLikedBySheet.show(context, postId: 'error-post');
                },
                child: const Text('Open Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Error'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load likes'), findsOneWidget);
      expect(find.byKey(const Key('retry_load_post_likers_button')), findsOneWidget);

      // Now server recovers and user taps retry
      shouldFail = false;
      await tester.tap(find.byKey(const Key('retry_load_post_likers_button')));
      await tester.pumpAndSettle();

      expect(find.text('Recovered User'), findsOneWidget);
    });

    testWidgets('10. PostCardWidget: Tapping like count or "Liked by X people" opens PostLikedBySheet', (tester) async {
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        if (options.path.endsWith('/likes')) {
          return _jsonResponse({
            'success': true,
            'data': {
              'content': [
                {
                  'userId': 'liker-a',
                  'fullName': 'Arun Roth',
                  'username': 'arun',
                }
              ],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'last': true,
            },
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = Get.put(CommunityController(repository: repository));

      final testPost = CommunityPostModel(
        id: 'post-card-like-test',
        userId: 'author-8',
        authorName: 'Sok Vichea',
        authorTag: '@vichea',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Welcome to GenLink Community Feed!',
        likesCount: 8,
        isLiked: false,
      );
      controller.posts.assignAll([testPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: PostCardWidget(
              post: testPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Liked by 8 people" preview is displayed
      expect(find.byKey(const Key('post_liked_by_preview_post-card-like-test')), findsOneWidget);

      // Tapping "Liked by 8 people" opens PostLikedBySheet
      await tester.tap(find.byKey(const Key('post_liked_by_preview_post-card-like-test')));
      await tester.pumpAndSettle();

      expect(find.byType(PostLikedBySheet), findsOneWidget);
      expect(find.text('Arun Roth'), findsOneWidget);

      // Close the sheet
      await tester.tap(find.byKey(const Key('close_post_liked_by_sheet')));
      await tester.pumpAndSettle();

      // Now tap the like count text next to the heart icon
      expect(find.byKey(const Key('post_like_count_post-card-like-test')), findsOneWidget);
      await tester.tap(find.byKey(const Key('post_like_count_post-card-like-test')));
      await tester.pumpAndSettle();

      expect(find.byType(PostLikedBySheet), findsOneWidget);
      expect(find.text('Arun Roth'), findsOneWidget);
    });

    testWidgets('11. Khmer localization displays natural Khmer classifier and translated title in liked-by preview and sheet', (tester) async {
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        if (options.path.endsWith('/likes')) {
          return _jsonResponse({
            'success': true,
            'data': {
              'content': [
                {
                  'userId': 'liker-km',
                  'fullName': 'សុខ វិជ្ជា',
                  'username': 'sokvichea',
                }
              ],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'last': true,
            },
          });
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = Get.put(CommunityController(repository: repository));

      final testPost = CommunityPostModel(
        id: 'post-card-km-test',
        userId: 'author-km',
        authorName: 'ចាន់ សុភា',
        authorTag: '@sophea',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'សួស្តី GenLink KH!',
        likesCount: 5,
        isLiked: false,
      );
      controller.posts.assignAll([testPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km'),
          home: Scaffold(
            body: PostCardWidget(
              post: testPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Khmer locale: "បានចូលចិត្តដោយ 5 នាក់"
      expect(find.text('បានចូលចិត្តដោយ 5 នាក់'), findsOneWidget);

      // Open sheet and verify Khmer title "បានចូលចិត្តដោយ"
      await tester.tap(find.byKey(const Key('post_liked_by_preview_post-card-km-test')));
      await tester.pumpAndSettle();

      expect(find.byType(PostLikedBySheet), findsOneWidget);
      expect(find.text('បានចូលចិត្តដោយ'), findsWidgets);
      expect(find.text('សុខ វិជ្ជា'), findsOneWidget);
    });

    test('12. Invalidation of postLikers cache on toggleLike prevents stale liker list', () async {
      final dio = Dio();
      dio.httpClientAdapter = _CapturingAdapter(handler: (options) async {
        if (options.path.endsWith('/like') && options.method == 'POST') {
          return _jsonResponse({'success': true, 'data': {'likeCount': 1}});
        }
        return _jsonResponse({}, statusCode: 404);
      });

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);

      final post = CommunityPostModel(
        id: 'post-cache-invalidation-test',
        userId: 'author-1',
        authorName: 'Author',
        authorTag: '@author',
        authorAvatar: '',
        timeAgo: '1m ago',
        content: 'Test content',
        likesCount: 0,
        isLiked: false,
      );
      controller.posts.assignAll([post]);

      // Seed cached likers
      controller.postLikers['post-cache-invalidation-test'] = [
        const PostLikerModel(id: 'old-liker', fullName: 'Old Liker', username: '@old'),
      ];
      expect(controller.postLikers.containsKey('post-cache-invalidation-test'), isTrue);

      // Toggle like invalidates the cached likers
      controller.toggleLike('post-cache-invalidation-test');
      expect(controller.postLikers.containsKey('post-cache-invalidation-test'), isFalse);
    });
  });
}
