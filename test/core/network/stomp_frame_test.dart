import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/network/stomp_frame.dart';

void main() {
  test('parses a STOMP CONNECTED frame and headers', () {
    final frame = StompFrameCodec.parse(
      'CONNECTED\r\n'
      'version:1.2\r\n'
      'heart-beat:0,0\r\n'
      '\r\n',
    );

    expect(frame?.command, 'CONNECTED');
    expect(frame?.headers['version'], '1.2');
    expect(frame?.headers['heart-beat'], '0,0');
    expect(frame?.body, isEmpty);
  });

  test('parses a MESSAGE frame without changing the JSON payload', () {
    final frame = StompFrameCodec.parse(
      'MESSAGE\n'
      'subscription:sub-match\n'
      'destination:/user/queue/match\n'
      'content-type:application/json\n'
      '\n'
      '{"status":"IN_PROGRESS","matchId":"match-1"}',
    );

    expect(frame?.command, 'MESSAGE');
    expect(frame?.headers['destination'], '/user/queue/match');
    expect(frame?.body, '{"status":"IN_PROGRESS","matchId":"match-1"}');
  });

  test('ignores heartbeat and blank frames', () {
    expect(StompFrameCodec.parse(''), isNull);
    expect(StompFrameCodec.parse('\n\n'), isNull);
  });
}
