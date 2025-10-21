import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/services/simple_chat_service.dart';
import 'package:fuodz/services/custom_video_call.service.dart';
import 'package:fuodz/services/call_notification.service.dart';
import 'package:fuodz/models/order.dart';
import 'package:fuodz/models/user.dart';
import 'package:fuodz/services/auth.service.dart';
// Removed velocity_x import
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fuodz/widgets/translatable_chat_message.dart';
import 'package:fuodz/widgets/translation_settings_widget.dart';

class SimpleChatPage extends StatefulWidget {
  final Order order;

  const SimpleChatPage({Key? key, required this.order}) : super(key: key);

  @override
  State<SimpleChatPage> createState() => _SimpleChatPageState();
}

class _SimpleChatPageState extends State<SimpleChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SimpleChatService _chatService = SimpleChatService();
  final CallNotificationService _callNotificationService =
      CallNotificationService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    // Start listening for incoming video calls
    _callNotificationService.startListening(widget.order.code);
  }

  void _initializeChat() async {
    _currentUser = AuthServices.currentUser;
    if (_currentUser != null) {
      _chatService.startListening(widget.order.code);
      _chatService.messagesStream.listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
          });
          _scrollToBottom();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    final success = await _chatService.sendMessage(
      orderId: widget.order.code,
      senderId: _currentUser!.id.toString(),
      senderName: _currentUser!.name,
      senderType: 'customer',
      message: message,
    );

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startVideoCall() async {
    if (_currentUser == null || widget.order.driver == null) return;

    try {
      // Ensure the service is initialized
      if (!CustomVideoCallService.isInitialized) {
        await CustomVideoCallService.initialize();
      }

      // Use CustomVideoCallService for video calls
      await CustomVideoCallService.makeVideoCall(
        receiverId: widget.order.driver!.id.toString(),
        receiverName: widget.order.driver!.name,
        callType: 'video',
      );
    } catch (e) {
      debugPrint('SimpleChatPage: Failed to start video call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start video call: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _chatService.stopListening();
    _callNotificationService.stopListening();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.order.driver?.name ?? "Driver"}'),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.order.driver != null)
            IconButton(
              icon: Icon(FlutterIcons.video_fea),
              onPressed: _startVideoCall,
              tooltip: 'Start Video Call',
            ),
        ],
      ),
      body: Column(
        children: [
          // Translation Settings
          TranslationSettingsWidget(
            onSettingsChanged: () {
              // Refresh messages when translation settings change
              setState(() {});
            },
          ),

          // Messages List
          Expanded(
            child:
                _messages.isEmpty
                    ? Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isOwnMessage = message.senderType == 'customer';

                        return TranslatableChatMessage(
                          message: message.message,
                          senderName: message.senderName,
                          timestamp: message.timestamp,
                          isOwnMessage: isOwnMessage,
                        );
                      },
                    ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey : AppColor.primaryColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
