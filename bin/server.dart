import "dart:io";

import "package:shelf/shelf.dart";
import "package:shelf/shelf_io.dart";
import "package:shelf_router/shelf_router.dart";
import "package:shelf_web_socket/shelf_web_socket.dart";
import "package:web_socket_channel/web_socket_channel.dart";

List<WebSocketChannel> webSocketChannels = [];

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final int postPort = int.tryParse(getEnv("POST_PORT")) ?? 8080;
  setupPostServer(ip, postPort);

  final int webSocketPort = int.tryParse(getEnv("WS_PORT")) ?? 8081;
  setupWebSocketServer(ip, webSocketPort);
}

Future<void> setupPostServer(InternetAddress ip, int port) async {
  final Router router = Router()..post("/post", _postHandler);
  final Handler handler = Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final server = await serve(handler, ip, port);
  print("POST Server listening on port ${server.port}");
}

Future<Response> _postHandler(Request request) async {
  final String message = await request.readAsString();

  if (message.isEmpty) {
    return Response(400, body: "No message provided");
  }

  print("post: $message");

  if (webSocketChannels.isEmpty) {
    return Response(202, body: "Accepted, but no WebSocket connections are present to pass the message to\n$message");
  }

  for (WebSocketChannel channel in webSocketChannels) {
    channel.sink.add(message);
  }

  return Response(201, body: message);
}

Future<void> setupWebSocketServer(InternetAddress ip, int port) async {
  final Handler handler = webSocketHandler(_webSocketHandler, pingInterval: Duration(seconds: 5));

  final server = await serve(handler, ip, port);
  print("WebSocket Server broadcasting on port ${server.port}");
}

void _webSocketHandler(WebSocketChannel channel) {
  webSocketChannels.add(channel);
  print("WebSocket connection established");
  channel.sink.add("Hello from the server!");

  channel.stream.listen(
    null,
    onDone: () {
      webSocketChannels.remove(channel);
      print("WebSocket connection closed (${channel.closeCode} \"${channel.closeReason}\")");
    },
  );
}

String getEnv(String key) {
  return Platform.environment[key] ?? "";
}

String attemptDecode(String message) {
  try {
    return Uri.decodeFull(message);
  } catch (e) {
    print("Message $message failed to decode:\n$e");
    return message;
  }
}
