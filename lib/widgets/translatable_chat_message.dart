import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/services/enhanced_translation.service.dart';

class TranslatableChatMessage extends StatefulWidget {
  final String message;
  final String senderName;
  final DateTime timestamp;
  final bool isOwnMessage;
  final String? originalLanguage;

  const TranslatableChatMessage({
    Key? key,
    required this.message,
    required this.senderName,
    required this.timestamp,
    required this.isOwnMessage,
    this.originalLanguage,
  }) : super(key: key);

  @override
  State<TranslatableChatMessage> createState() =>
      _TranslatableChatMessageState();
}

class _TranslatableChatMessageState extends State<TranslatableChatMessage> {
  String? _translatedMessage;
  bool _isTranslating = false;
  bool _showTranslation = false;
  String? _detectedLanguage;

  @override
  void initState() {
    super.initState();
    _checkAutoTranslation();
  }

  Future<void> _checkAutoTranslation() async {
    if (widget.isOwnMessage) return; // Don't auto-translate own messages

    try {
      final isAutoTranslateEnabled =
          await EnhancedTranslationService.isAutoTranslateEnabled();
      if (isAutoTranslateEnabled) {
        await _translateMessage();
      }
    } catch (e) {
      print('Error checking auto-translation: $e');
    }
  }

  Future<void> _translateMessage() async {
    if (_isTranslating || widget.message.trim().isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      // Detect language if not provided
      if (_detectedLanguage == null) {
        _detectedLanguage = await EnhancedTranslationService.detectLanguage(
          widget.message,
        );
      }

      // Get user's preferred language
      final preferredLanguage =
          await EnhancedTranslationService.getSelectedLanguage();

      // Only translate if message is not already in preferred language
      if (_detectedLanguage != preferredLanguage) {
        final translated = await EnhancedTranslationService.translateText(
          text: widget.message,
          targetLanguage: preferredLanguage,
          sourceLanguage: _detectedLanguage ?? 'auto',
        );

        setState(() {
          _translatedMessage = translated;
          _showTranslation = true;
        });
      }
    } catch (e) {
      print('Translation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _toggleTranslation() {
    if (_translatedMessage == null && !_isTranslating) {
      _translateMessage();
    } else {
      setState(() {
        _showTranslation = !_showTranslation;
      });
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            widget.isOwnMessage
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment:
                  widget.isOwnMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                // Main message bubble
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        widget.isOwnMessage
                            ? AppColor.primaryColor
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original message
                      if (!_showTranslation || _translatedMessage == null)
                        Text(
                          widget.message,
                          style: TextStyle(
                            color:
                                widget.isOwnMessage
                                    ? Colors.white
                                    : Colors.black87,
                            fontSize: 16,
                          ),
                        ),

                      // Translated message
                      if (_showTranslation && _translatedMessage != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _translatedMessage ?? '',
                              style: TextStyle(
                                color:
                                    widget.isOwnMessage
                                        ? Colors.white
                                        : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Translated from ${EnhancedTranslationService.getLanguageName(_detectedLanguage ?? 'auto')}',
                              style: TextStyle(
                                color:
                                    widget.isOwnMessage
                                        ? Colors.white60
                                        : Colors.grey[500],
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: 4),

                      // Timestamp and translation button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(widget.timestamp),
                            style: TextStyle(
                              color:
                                  widget.isOwnMessage
                                      ? Colors.white70
                                      : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),

                          // Translation button for incoming messages
                          if (!widget.isOwnMessage) ...[
                            SizedBox(width: 8),
                            if (_isTranslating)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey[600] ?? Colors.grey,
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: _toggleTranslation,
                                child: Icon(
                                  _showTranslation && _translatedMessage != null
                                      ? FlutterIcons.eye_off_fea
                                      : FlutterIcons.globe_fea,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Show original message when translation is displayed
                if (_showTranslation && _translatedMessage != null)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600] ?? Colors.grey
                                : Colors.grey[300] ?? Colors.grey,
                      ),
                    ),
                    child: Text(
                      'Original: ${widget.message}',
                      style: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
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
