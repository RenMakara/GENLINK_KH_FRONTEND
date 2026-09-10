import 'package:dio/dio.dart';

import '../../../core/storage/secure_storage.dart';

class MockInterceptor extends Interceptor {
  MockInterceptor(this.storage);
  final SecureStorage storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.readAccessToken();
    final isDemoToken =
        token == 'demo_access_token' ||
        token == 'mock_access_token_123' ||
        token == 'mock_google_token';

    if (!isDemoToken) {
      handler.next(options);
      return;
    }

    if (options.path.contains('/auth/')) {
      handler.next(options);
      return;
    }

    final path = options.path;
    dynamic data = {};

    if (path.contains('/mobile/home')) {
      data = {
        'user': {
          'id': 'demo123',
          'firstName': 'Designer',
          'lastName': 'Pro',
          'fullName': 'Designer Pro',
          'level': 5,
          'totalXp': 1200,
          'xpForNextLevel': 2000,
          'percentToNext': 60,
        },
        'todayProgress': {
          'doneCount': 1,
          'totalCount': 3,
          'percent': 33,
          'progress': 0.33,
          'habitsTotal': 1,
          'habitsCompletedToday': 1,
          'tasksTotal': 2,
          'tasksCompleted': 0,
        },
        'recommendedCommunities': [],
        'feedPreview': [],
      };
    } else if (path.contains('/profile/me')) {
      data = {
        'id': 'demo123',
        'email': 'demo@genlink.kh',
        'firstName': 'Designer',
        'lastName': 'Pro',
        'headline': 'UI/UX Designer',
        'level': 5,
        'totalXp': 1200,
      };
    } else if (path.contains('/community/posts')) {
      data = {'content': [], 'totalPages': 0, 'totalElements': 0};
    } else if (path.contains('/community')) {
      data = [];
    } else {
      data = {};
    }

    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'success': true,
          'data': data,
          if (path.contains('/posts') && data is Map)
            ...data,
        },
      ),
    );
  }
}
