import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/features/challenge/data/datasources/challenge_remote_data_source.dart';
import 'package:genlink_frontend/features/challenge/domain/models/challenge_models.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio());

  dynamic responseData;
  final getPaths = <String>[];
  final postPaths = <String>[];
  final postBodies = <Object?>[];

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    getPaths.add(path);
    return parse(responseData);
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    postPaths.add(path);
    postBodies.add(body);
    return parse(responseData);
  }
}

const _payload = {
  'challengeId': 'challenge-1',
  'title': 'Challenge',
  'description': 'Description',
  'challengeType': 'TASK',
  'xpReward': 25,
  'status': 'NOT_STARTED',
  'progress': 0,
};

void main() {
  test('uses the verified challenge API paths and parses responses', () async {
    final apiClient = _FakeApiClient()..responseData = [_payload];
    final dataSource = ChallengeRemoteDataSourceImpl(apiClient);

    final active = await dataSource.getActiveChallenges();
    final mine = await dataSource.getMyChallenges();

    apiClient.responseData = _payload;
    final joined = await dataSource.joinChallenge('challenge-1');
    final completed = await dataSource.completeChallenge('challenge-1');
    final claimed = await dataSource.claimReward('challenge-1');

    expect(active.single.challengeId, 'challenge-1');
    expect(mine.single.challengeType.name, 'task');
    expect(joined.status, ChallengeStatus.notStarted);
    expect(completed.progress, 0);
    expect(claimed.xpReward, 25);
    expect(apiClient.getPaths, [
      '/api/v1/entertainment/challenges',
      '/api/v1/entertainment/challenges/mine',
    ]);
    expect(apiClient.postPaths, [
      '/api/v1/entertainment/challenges/challenge-1/join',
      '/api/v1/entertainment/challenges/challenge-1/complete',
      '/api/v1/entertainment/challenges/challenge-1/claim',
    ]);
    expect(apiClient.postBodies, [null, null, null]);
  });
}
