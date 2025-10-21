import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fuodz/services/simple_translation.service.dart';

class TranslationOverlay extends StatefulWidget {
  final Widget child;
  final String? chatPath;

  const TranslationOverlay({
    Key? key,
    required this.child,
    this.chatPath,
  }) : super(key: key);

  @override
  State<TranslationOverlay> createState() => _TranslationOverlayState();

  // Static method to access the state from outside
  static _TranslationOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<_TranslationOverlayState>();
  }
}

class _TranslationOverlayState extends State<TranslationOverlay> {
  bool _isTranslationEnabled = false;
  String _selectedLanguage = 'en';
  final Map<String, String> _translationCache = {};
  Timer? _translationTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _translationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final enabled = await SimpleTranslationService.isTranslationEnabled();
    final language = await SimpleTranslationService.getSelectedLanguage();
    
    setState(() {
      _isTranslationEnabled = enabled;
      _selectedLanguage = language;
    });
  }

  // Public methods for external control
  void changeLanguage(String languageCode) async {
    await SimpleTranslationService.setSelectedLanguage(languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
    // Clear cache when language changes
    _translationCache.clear();
  }

  void toggleTranslation(bool enabled) async {
    await SimpleTranslationService.setTranslationEnabled(enabled);
    setState(() {
      _isTranslationEnabled = enabled;
    });
  }

  // Getters for current state
  bool get isTranslationEnabled => _isTranslationEnabled;
  String get selectedLanguage => _selectedLanguage;

  Future<String> _translateText(String text) async {
    if (!_isTranslationEnabled || text.trim().isEmpty) {
      return text;
    }

    // Check cache first
    final cacheKey = '${text}_$_selectedLanguage';
    if (_translationCache.containsKey(cacheKey)) {
      final cachedText = _translationCache[cacheKey];
      if (cachedText != null) {
        return cachedText;
      }
    }

    try {
      final translatedText = await SimpleTranslationService.translateText(
        text: text,
        targetLanguage: _selectedLanguage,
      );
      
      // Cache the result
      _translationCache[cacheKey] = translatedText;
      
      return translatedText;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Original chat widget
        widget.child,

        // Translation popup (for showing translated text)
        if (_isTranslationEnabled)
          _TranslationPopupHandler(
            translateText: _translateText,
            selectedLanguage: _selectedLanguage,
          ),
      ],
    );
  }
}

class _TranslationPopupHandler extends StatefulWidget {
  final Future<String> Function(String) translateText;
  final String selectedLanguage;

  const _TranslationPopupHandler({
    Key? key,
    required this.translateText,
    required this.selectedLanguage,
  }) : super(key: key);

  @override
  State<_TranslationPopupHandler> createState() => _TranslationPopupHandlerState();
}

class _TranslationPopupHandlerState extends State<_TranslationPopupHandler> {
  OverlayEntry? _overlayEntry;
  Offset? _tapPosition;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showTranslationPopup(String text, Offset position) async {
    _removeOverlay();
    
    final translatedText = await widget.translateText(text);
    
    if (translatedText != text && mounted) {
      _overlayEntry = OverlayEntry(
        builder: (context) => _TranslationPopup(
          originalText: text,
          translatedText: translatedText,
          position: position,
          selectedLanguage: widget.selectedLanguage,
          onClose: _removeOverlay,
        ),
      );
      
      if (_overlayEntry != null) {
        Overlay.of(context).insert(_overlayEntry!);
        
        // Auto-remove after 5 seconds
        Timer(const Duration(seconds: 5), () {
          _removeOverlay();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _tapPosition = details.globalPosition;
      },
      onLongPress: () {
        // For now, we'll show a demo translation
        // In a real implementation, you'd need to detect selected text
        if (_tapPosition != null) {
          _showTranslationPopup(
            "Hello, how are you?", // Demo text
            _tapPosition!,
          );
        }
      },
      child: const SizedBox.expand(),
    );
  }
}

class _TranslationPopup extends StatelessWidget {
  final String originalText;
  final String translatedText;
  final Offset position;
  final String selectedLanguage;
  final VoidCallback onClose;

  const _TranslationPopup({
    Key? key,
    required this.originalText,
    required this.translatedText,
    required this.position,
    required this.selectedLanguage,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 150,
      top: position.dy - 100,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300] ?? Colors.grey),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    SimpleTranslationService.getLanguageFlag(selectedLanguage),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Translation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Original:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                originalText,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                '${SimpleTranslationService.getLanguageName(selectedLanguage)}:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                translatedText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
