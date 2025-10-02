// In lib/services/chat_web_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_client/web_socket_client.dart';

class ChatWebService {
  static final _instance = ChatWebService._internal();
  WebSocket? _socket;

  factory ChatWebService() => _instance;

  ChatWebService._internal();
  final _searchResultController = StreamController<Map<String, dynamic>>.broadcast(); // Use .broadcast() for multiple listeners
  final _contentController = StreamController<Map<String, dynamic>>.broadcast(); // Use .broadcast() for multiple listeners

  Stream<Map<String, dynamic>> get searchResultStream =>
      _searchResultController.stream;
  Stream<Map<String, dynamic>> get contentStream => _contentController.stream;

  void connect() {
    _socket = WebSocket(Uri.parse("ws://localhost:8000/ws/chat"));

    _socket!.messages.listen((message) {
      print("Received WebSocket message: $message");
      final data = json.decode(message);

      if (data['type'] == 'search_result') {
        // 1. Send the original message to the SourcesSection as before.
        _searchResultController.add(data);

        // 2. NEW: Extract the 'content' and send it to the AnswerSection.
        if (data['data'] is List) {
          for (var item in data['data']) {
            if (item is Map && item.containsKey('content') && item['content'] != null) {
              // The AnswerSection expects a map like {'data': '...content...'}.
              // We create that map here before sending it to the stream.
              _contentController.add({'data': item['content']});
            }
          }
        }
      } else if (data['type'] == 'answer_chunk') {
        // This is kept in case the backend also sends this type.
        _contentController.add(data);
      } else {
        print("Received unknown message type: ${data['type']}");
      }
    });
  }

  void chat(String query) {
    print(query);
    print(_socket);
    if (_socket != null) {
      _socket!.send(json.encode({'query': query}));
    }
  }

  // It's good practice to have a dispose method to close controllers.
  void dispose() {
    _searchResultController.close();
    _contentController.close();
    _socket?.close();
  }
}


