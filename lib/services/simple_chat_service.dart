import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fuodz/constants/api.dart';
import 'package:fuodz/services/auth.service.dart';

class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String senderType; // 'customer' or 'driver'
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      orderId: (json['orderId'] ?? json['order_id'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender_id'] ?? '').toString(),
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      senderType: json['senderType'] ?? json['sender_type'] ?? 'customer',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      isRead: json['is_read'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType,
      'message': message,
    };
  }
}

class SimpleChatService {
  static final SimpleChatService _instance = SimpleChatService._internal();
  factory SimpleChatService() => _instance;
  SimpleChatService._internal();

  final StreamController<List<ChatMessage>> _messagesController =
      StreamController<List<ChatMessage>>.broadcast();

  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;

  Timer? _pollingTimer;
  String? _currentOrderId;
  List<ChatMessage> _messages = [];
  int _lastMessageCount = 0;
  String? _lastMessageId;

  String get baseUrl => Api.baseUrl;

  // Start listening to messages for an order
  void startListening(String orderId) {
    print('Customer: Starting to listen for order: $orderId');
    _currentOrderId = orderId;
    _messages.clear();
    _lastMessageCount = 0;
    _lastMessageId = null;
    _loadMessages();

    // Poll for new messages every 1 second for real-time feel
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _loadMessages();
    });
  }

  // Stop listening
  void stopListening() {
    _pollingTimer?.cancel();
    _currentOrderId = null;
    _messages.clear();
  }

  // Load messages from server
  Future<void> _loadMessages() async {
    if (_currentOrderId == null) return;

    try {
      final token = await AuthServices.getAuthBearerToken();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$_currentOrderId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> messagesJson = data['messages'] ?? [];

        final newMessages =
            messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

        // Sort by timestamp
        newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Check if there are new messages by comparing the last message ID
        String? newLastMessageId =
            newMessages.isNotEmpty ? newMessages.last.id : null;

        // Only update if messages changed
        if (!_areMessagesEqual(_messages, newMessages) ||
            newLastMessageId != _lastMessageId) {
          // Check if there are new messages (more than before)
          if (newMessages.length > _lastMessageCount && _lastMessageCount > 0) {
            // Show notification for new messages
            print(
              'Customer: New message detected! Count: ${newMessages.length}',
            );
          }

          _messages = newMessages;
          _lastMessageCount = _messages.length;
          _lastMessageId = newLastMessageId;
          _messagesController.add(_messages);
          print('Customer: Updated messages - count: ${newMessages.length}');
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) async {
    try {
      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderId: orderId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        message: message,
        timestamp: DateTime.now(),
      );

      // Add message locally for immediate feedback
      _messages.add(chatMessage);
      _messagesController.add(_messages);

      // Send message to the backend
      final token = await AuthServices.getAuthBearerToken();
      print('Customer: Sending message to: $baseUrl/orders/$orderId/messages');

      final requestBody = {
        'senderId': senderId,
        'senderName': senderName,
        'senderType': senderType,
        'message': message,
      };

      print('Customer: Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('Customer: Message response status: ${response.statusCode}');
      print('Customer: Message response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Remove the local message and reload from server for consistency
        if (_messages.isNotEmpty) {
          _messages.removeLast();
        }
        await _loadMessages();
        return true;
      } else {
        // Remove the message if sending failed
        if (_messages.isNotEmpty) {
          _messages.removeLast();
          _messagesController.add(_messages);
        }
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      // Remove the message if sending failed
      if (_messages.isNotEmpty) {
        _messages.removeLast();
        _messagesController.add(_messages);
      }
    }
    return false;
  }

  // Helper to compare message lists
  bool _areMessagesEqual(List<ChatMessage> list1, List<ChatMessage> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _messagesController.close();
  }
}
