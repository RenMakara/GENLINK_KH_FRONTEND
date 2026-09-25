/// A small STOMP frame representation used by [AppRealtimeService].
///
/// The application deliberately keeps one WebSocket/STOMP transport. This
/// parser only separates frames from the existing transport; it is not a
/// second realtime client.
class StompFrame {
  const StompFrame({
    required this.command,
    required this.headers,
    required this.body,
  });

  final String command;
  final Map<String, String> headers;
  final String body;
}

class StompFrameCodec {
  const StompFrameCodec._();

  static StompFrame? parse(String rawFrame) {
    final normalized = rawFrame.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');

    var commandIndex = 0;
    while (commandIndex < lines.length && lines[commandIndex].trim().isEmpty) {
      commandIndex++;
    }
    if (commandIndex >= lines.length) return null;

    final command = lines[commandIndex].trim();
    if (command.isEmpty) return null;

    final headers = <String, String>{};
    var bodyStart = lines.length;
    for (var index = commandIndex + 1; index < lines.length; index++) {
      final line = lines[index];
      if (line.isEmpty) {
        bodyStart = index + 1;
        break;
      }
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      headers[line.substring(0, separator)] = line.substring(separator + 1);
    }

    final body = bodyStart < lines.length
        ? lines.sublist(bodyStart).join('\n')
        : '';
    return StompFrame(command: command, headers: headers, body: body);
  }
}
