# Post to WebSocket Broadcaster (Dart)

A little server application that listens for HTTP POST requests
and broadcasts the body of the request to all connected websockets.

Built using [Shelf](https://pub.dev/packages/shelf),
[Shelf Router](https://pub.dev/packages/shelf_router),
[Web Socket Channel](https://pub.dev/packages/web_socket_channel),
and [Shelf Web Socket](https://pub.dev/packages/shelf_web_socket).

## Running the server application

By default, the POST server listens on port 8080
and the WebSocket server listens on port 8081,
but you can set the `POST_PORT` and `WS_PORT` environment variables
to change the ports that each server listens on.

Only supports binding to IPV4 addresses.

### With the Dart SDK

Please install the [Dart SDK](https://dart.dev/get-dart) if you haven't already.

#### Pre-compiling
You can  compile the server to a native executable, and run that:

```bash
$ dart pub get && dart compile exe bin/server.dart && bin/server.exe
POST Server listening on port 8080
WebSocket Server broadcasting on port 8081
```

#### Running directly

You can also run the script directly with the `dart` command.\
This is worse for performance (CPU & RAM) than pre-compiling, however.

```bash
$ dart pub get && dart run bin/server.dart
POST Server listening on port 8080
WebSocket Server broadcasting on port 8081
```

### With Docker

If you have Docker installed, you
can build and run with the `docker` command.

```bash
$ docker build . -t myserver
$ docker run -it -p 8080:8080 -p 8081:8081 myserver
POST Server listening on port 8080
WebSocket Server broadcasting on port 8081
```

## Connecting to and using the server application
You'll need to have the server application running somewhere,
on your own localhost for example.

Firstly, you should connect a websocket client,
otherwise the received POST messages will have nowhere to be broadcast to.

For example, you can use the `websocat` command line tool:
```bash
$ websocat ws://127.0.0.1:8081/
Hello from the server!
```

Then, you can send a POST request to the server.
You'll get the message echoed back to you.

You can use `curl` to do this:
```bash
$ curl -X POST 127.0.0.1:8080/post -d "Hello from a POST request"
Hello, World
```

Then, you should see the message printed in the websocket client:
```diff
$ websocat ws://127.0.0.1:8081/
Hello from the server!
+ Hello from a POST request
```

In the server terminal, you should see some logs printed:
```diff
POST Server listening on port 8080
WebSocket Server broadcasting on port 8081
WebSocket connection established
+ post: Hello from a POST request
+ 2023-10-13T16:52:26.601238  0:00:00.011524 POST    [201] /post
```
