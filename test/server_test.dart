import "dart:convert";
import "dart:io";

import "package:async/async.dart";
import "package:http/http.dart";
import "package:test/test.dart";
import "package:web_socket_channel/web_socket_channel.dart";

void main() {
  final postPort = "8080";
  final webSocketPort = "8081";

  late Process p;

  setUp(() async {
    p = await Process.start(
      "dart",
      ["run", "bin/server.dart"],
      environment: {
        "POST_PORT": postPort,
        "WS_PORT": webSocketPort,
      },
    );

    Stream<String> mergedStream = StreamGroup.merge([p.stdout, p.stderr])
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();

    if (Platform.environment.containsKey("DEBUG") || Platform.environment.containsKey("RUNNER_DEBUG")) {
      print("============================================== New Test ===============================================");
      int i = 0;
      mergedStream.forEach((String message) {
        print("$i: $message");
        i++;
      });
    }

    // Check if server crashes on startup:
    mergedStream.forEach((element) {
      if (element.contains("SocketException")) {
        fail("Server failed to start: $element");
      }
    });

    // Wait for server to finish starting up:
    await mergedStream.firstWhere((element) => element.contains(webSocketPort));
  });

  tearDown(() => p.kill());

  final localhost = "127.0.0.1";
  final host = "http://$localhost:$postPort";
  final webSocketHost = Uri.parse("ws://$localhost:$webSocketPort");

  test("404", () async {
    final response = await get(Uri.parse("$host/never-gonna-give-you-up"));
    expect(response.statusCode, 404);
  });

  test("No websocket connections", () async {
    final body = "I am sending into the void!";
    final response = await post(Uri.parse("$host/post"), body: body);
    expect(response.statusCode, 202);
    expect(response.body, "Accepted, but no WebSocket connections are present to pass the message to\n$body");
  });

  test("Connect websocket", () async {
    WebSocketChannel channel = WebSocketChannel.connect(webSocketHost);
    final result = await channel.stream.first;
    channel.sink.close();
    expect(result, "Hello from the server!");
  });

  test("Send message to websocket", () async {
    WebSocketChannel channel = WebSocketChannel.connect(webSocketHost);

    final body = "Hello websocket channel!";
    final response = await post(Uri.parse("$host/post"), body: body);
    expect(response.statusCode, 201);
    expect(response.body, "Accepted, sent to 1 WebSocket connection(s)\n$body");

    final result = await channel.stream.elementAt(1);
    channel.sink.close();
    expect(result, body);
  });

  test("Ping Pong", () async {
    WebSocketChannel channel = WebSocketChannel.connect(webSocketHost);

    channel.sink.add("ping");
    final result = await channel.stream.elementAt(1);
    channel.sink.close();
    expect(result, "pong");
  });
}
