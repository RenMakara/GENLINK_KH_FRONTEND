import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/data/datasources/community_remote_datasource.dart';
import 'package:genlink_frontend/features/community/data/repositories/community_repository_impl.dart';
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
  _CapturingAdapter({required this.handler});

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
  setUp(() {
    Get.reset();
    Get.testMode = true;

    final authController = AuthController(
      authRepository: _FakeAuthRepository(),
      secureStorage: _FakeSecureStorage(),
      localization: _FakeLocalizationService(),
    );
    authController.currentUser.value = const UserEntity(
      id: 'user-me-123',
      fullName: 'Test User',
      username: 'testuser',
      email: 'test@genlink.kh',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 100,
      level: 1,
      preferredLanguage: 'en',
      role: 'STUDENT',
      active: true,
    );
    Get.put<AuthController>(authController);
    Get.put<LocalizationService>(_FakeLocalizationService());
  });

  tearDown(() {
    Get.reset();
  });

  group('Feed Save / Bookmark Specification Tests', () {
    test('1. Save: Optimistic update sets isBookmarked = true and calls remote datasource', () async {
      bool bookmarkApiCalled = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async {
            if (options.path.contains('bookmark') || options.path.contains('saved')) {
              bookmarkApiCalled = true;
              return _jsonResponse({'status': 200, 'message': 'OK', 'data': {'saved': true}});
            }
            if (options.path.contains('/feed')) {
              return _jsonResponse({
                'status': 200,
                'data': {
                  'content': [
                    {
                      'postId': 'post-save-1',
                      'author': {'userId': 'author-1', 'fullName': 'Sok Vichea', 'username': 'vichea', 'avatarUrl': ''},
                      'contentText': 'Campus life at RUPP',
                      'likeCount': 0,
                      'commentCount': 0,
                      'repostCount': 0,
                      'isBookmarked': false,
                      'savedByMe': false,
                    }
                  ],
                  'currentPage': 0,
                  'totalPages': 1,
                  'totalPosts': 1,
                  'hasNext': false,
                },
              });
            }
            return _jsonResponse({'status': 400, 'message': 'Not handled'}, statusCode: 400);
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);
      Get.put<CommunityController>(controller);

      await controller.fetchPosts();
      expect(controller.posts.isNotEmpty, isTrue);
      expect(controller.posts.first.isBookmarked, isFalse);

      final result = await controller.toggleBookmark('post-save-1');

      expect(result, isTrue);
      expect(controller.posts.first.isBookmarked, isTrue);
      expect(bookmarkApiCalled, isTrue);
    });

    test('2. Unsave: Tapping bookmark on saved post updates isBookmarked = false', () async {
      bool unsaveApiCalled = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async {
            if (options.path.contains('bookmark') || options.path.contains('saved')) {
              unsaveApiCalled = true;
              return _jsonResponse({'status': 200, 'message': 'OK', 'data': {'saved': false}});
            }
            if (options.path.contains('/feed')) {
              return _jsonResponse({
                'status': 200,
                'data': {
                  'content': [
                    {
                      'postId': 'post-save-2',
                      'author': {'userId': 'author-2', 'fullName': 'Sok Vichea', 'username': 'vichea', 'avatarUrl': ''},
                      'contentText': 'Campus life at ITC',
                      'likeCount': 0,
                      'commentCount': 0,
                      'repostCount': 0,
                      'isBookmarked': true,
                      'savedByMe': true,
                    }
                  ],
                  'currentPage': 0,
                  'totalPages': 1,
                  'totalPosts': 1,
                  'hasNext': false,
                },
              });
            }
            return _jsonResponse({'status': 400, 'message': 'Not handled'}, statusCode: 400);
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);
      Get.put<CommunityController>(controller);

      await controller.fetchPosts();
      expect(controller.posts.isNotEmpty, isTrue);
      expect(controller.posts.first.isBookmarked, isTrue);

      final result = await controller.toggleBookmark('post-save-2');

      expect(result, isTrue);
      expect(controller.posts.first.isBookmarked, isFalse);
      expect(unsaveApiCalled, isTrue);
    });

    test('3. Persistence after refresh: Persisted bookmark status survives feed refresh', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async {
            if (options.path.contains('/feed')) {
              return _jsonResponse({
                'status': 200,
                'data': {
                  'content': [
                    {
                      'postId': 'post-save-3',
                      'author': {
                        'userId': 'author-3',
                        'fullName': 'Roth Vanna',
                        'username': 'rothvanna',
                        'avatarUrl': '',
                      },
                      'contentText': 'Tech updates 2026',
                      'likeCount': 0,
                      'commentCount': 0,
                      'repostCount': 0,
                      'isBookmarked': true,
                      'savedByMe': true,
                    }
                  ],
                  'currentPage': 0,
                  'totalPages': 1,
                  'totalPosts': 1,
                  'hasNext': false,
                },
              });
            }
            return _jsonResponse({'status': 400, 'message': 'Not handled'}, statusCode: 400);
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);
      Get.put<CommunityController>(controller);

      await controller.fetchPosts(isRefresh: true);

      expect(controller.posts.length, equals(1));
      expect(controller.posts.first.id, equals('post-save-3'));
      expect(controller.posts.first.isBookmarked, isTrue);
    });

    test('4. Optimistic rollback: Network failure reverts bookmark to previous state', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async {
            if (options.path.contains('/feed')) {
              return _jsonResponse({
                'status': 200,
                'data': {
                  'content': [
                    {
                      'postId': 'post-save-4',
                      'author': {'userId': 'author-4', 'fullName': 'Sok Vichea', 'username': 'vichea', 'avatarUrl': ''},
                      'contentText': 'Campus news',
                      'likeCount': 0,
                      'commentCount': 0,
                      'repostCount': 0,
                      'isBookmarked': false,
                      'savedByMe': false,
                    }
                  ],
                  'currentPage': 0,
                  'totalPages': 1,
                  'totalPosts': 1,
                  'hasNext': false,
                },
              });
            }
            return _jsonResponse({'status': 500, 'message': 'Internal Server Error'}, statusCode: 500);
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);
      Get.put<CommunityController>(controller);

      await controller.fetchPosts();
      expect(controller.posts.isNotEmpty, isTrue);
      expect(controller.posts.first.isBookmarked, isFalse);

      final result = await controller.toggleBookmark('post-save-4');

      expect(result, isFalse);
      // Rolled back to false
      expect(controller.posts.first.isBookmarked, isFalse);
    });

    testWidgets('5. UI active/inactive state: PostCardWidget reflects bookmark state with warning accent', (tester) async {
      bool bookmarkToggled = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingAdapter(
          handler: (options) async {
            if (options.path.contains('bookmark') || options.path.contains('saved')) {
              bookmarkToggled = !bookmarkToggled;
              return _jsonResponse({'status': 200, 'message': 'OK', 'data': {'saved': bookmarkToggled}});
            }
            if (options.path.contains('/feed')) {
              return _jsonResponse({
                'status': 200,
                'data': {
                  'content': [
                    {
                      'postId': 'post-save-ui-5',
                      'author': {'userId': 'author-5', 'fullName': 'Chansela', 'username': 'chansela', 'avatarUrl': ''},
                      'contentText': 'Testing Save UI in PostCardWidget',
                      'likeCount': 0,
                      'commentCount': 0,
                      'repostCount': 0,
                      'isBookmarked': false,
                      'savedByMe': false,
                    }
                  ],
                  'currentPage': 0,
                  'totalPages': 1,
                  'totalPosts': 1,
                  'hasNext': false,
                },
              });
            }
            return _jsonResponse({'status': 400, 'message': 'Not handled'}, statusCode: 400);
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
      final controller = CommunityController(repository: repository);
      Get.put<CommunityController>(controller);

      await tester.runAsync(() async {
        await controller.fetchPosts();
      });
      expect(controller.posts.isNotEmpty, isTrue);

      final post = controller.posts.first;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: post,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial inactive state
      expect(find.byKey(const Key('post_bookmark_button_post-save-ui-5')), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

      // Tap to save
      await tester.tap(find.byKey(const Key('post_bookmark_button_post-save-ui-5')));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      // Active state: icon changes to bookmark_rounded with warning color
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      final bookmarkIcon = tester.widget<Icon>(find.byIcon(Icons.bookmark_rounded));
      expect(bookmarkIcon.color, equals(AppColors.warning));

      // Tap again to unsave
      await tester.tap(find.byKey(const Key('post_bookmark_button_post-save-ui-5')));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      // Inactive state restored
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });
  });
}
