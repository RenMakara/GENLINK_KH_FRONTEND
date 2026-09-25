import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  group('ApiClient.asList', () {
    test('returns a growable list that supports mutation', () {
      final rawData = [
        {'id': '1', 'name': 'Item 1'},
        {'id': '2', 'name': 'Item 2'},
      ];

      final result = ApiClient.asList(
        rawData,
        (map) => map['name'] as String,
      );

      expect(result, ['Item 1', 'Item 2']);

      // Verify that the list is growable and mutable without UnsupportedError
      expect(() => result.add('Item 3'), returnsNormally);
      expect(result.length, 3);

      expect(() => result.insert(0, 'Item 0'), returnsNormally);
      expect(result.first, 'Item 0');

      expect(() => result.removeWhere((item) => item == 'Item 1'), returnsNormally);
      expect(result, ['Item 0', 'Item 2', 'Item 3']);
    });
  });

  group('ApiClient.delete', () {
    late _MockDio mockDio;
    late ApiClient apiClient;

    setUp(() {
      mockDio = _MockDio();
      apiClient = ApiClient(mockDio);
    });

    test('succeeds when backend returns 200 with success envelope', () async {
      when(() => mockDio.delete<dynamic>('/items/1', queryParameters: null))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/items/1'),
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Deleted',
                  'data': null,
                },
              ));

      await expectLater(apiClient.delete('/items/1'), completes);
    });

    test('succeeds when backend returns 204 No Content', () async {
      when(() => mockDio.delete<dynamic>('/items/1', queryParameters: null))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/items/1'),
                statusCode: 204,
                data: null,
              ));

      await expectLater(apiClient.delete('/items/1'), completes);
    });

    test('succeeds when backend returns empty string body', () async {
      when(() => mockDio.delete<dynamic>('/items/1', queryParameters: null))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/items/1'),
                statusCode: 200,
                data: '',
              ));

      await expectLater(apiClient.delete('/items/1'), completes);
    });
  });
}
