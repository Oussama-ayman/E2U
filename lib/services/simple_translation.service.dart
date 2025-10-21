import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleTranslationService {
  static const String _selectedLanguageKey = 'selected_translation_language';
  static const String _translationEnabledKey = 'translation_enabled';
  
  // Google Translate API endpoint
  static const String _translateApiUrl = 'https://translate.googleapis.com/translate_a/single';
  
  // Common languages with their flag emojis
  static const Map<String, Map<String, String>> supportedLanguages = {
    'en': {'name': 'English', 'flag': '🇺🇸'},
    'es': {'name': 'Spanish', 'flag': '🇪🇸'},
    'fr': {'name': 'French', 'flag': '🇫🇷'},
    'de': {'name': 'German', 'flag': '🇩🇪'},
    'it': {'name': 'Italian', 'flag': '🇮🇹'},
    'pt': {'name': 'Portuguese', 'flag': '🇵🇹'},
    'ru': {'name': 'Russian', 'flag': '🇷🇺'},
    'ja': {'name': 'Japanese', 'flag': '🇯🇵'},
    'ko': {'name': 'Korean', 'flag': '🇰🇷'},
    'zh': {'name': 'Chinese', 'flag': '🇨🇳'},
    'ar': {'name': 'Arabic', 'flag': '🇸🇦'},
    'hi': {'name': 'Hindi', 'flag': '🇮🇳'},
    'tr': {'name': 'Turkish', 'flag': '🇹🇷'},
    'nl': {'name': 'Dutch', 'flag': '🇳🇱'},
    'sv': {'name': 'Swedish', 'flag': '🇸🇪'},
    'da': {'name': 'Danish', 'flag': '🇩🇰'},
    'no': {'name': 'Norwegian', 'flag': '🇳🇴'},
    'fi': {'name': 'Finnish', 'flag': '🇫🇮'},
    'pl': {'name': 'Polish', 'flag': '🇵🇱'},
    'th': {'name': 'Thai', 'flag': '🇹🇭'},
    'vi': {'name': 'Vietnamese', 'flag': '🇻🇳'},
    'id': {'name': 'Indonesian', 'flag': '🇮🇩'},
    'ms': {'name': 'Malay', 'flag': '🇲🇾'},
    'tl': {'name': 'Filipino', 'flag': '🇵🇭'},
    'he': {'name': 'Hebrew', 'flag': '🇮🇱'},
    'fa': {'name': 'Persian', 'flag': '🇮🇷'},
    'ur': {'name': 'Urdu', 'flag': '🇵🇰'},
    'bn': {'name': 'Bengali', 'flag': '🇧🇩'},
    'ta': {'name': 'Tamil', 'flag': '🇱🇰'},
    'te': {'name': 'Telugu', 'flag': '🇮🇳'},
    'ml': {'name': 'Malayalam', 'flag': '🇮🇳'},
    'kn': {'name': 'Kannada', 'flag': '🇮🇳'},
    'gu': {'name': 'Gujarati', 'flag': '🇮🇳'},
    'pa': {'name': 'Punjabi', 'flag': '🇮🇳'},
    'mr': {'name': 'Marathi', 'flag': '🇮🇳'},
  };

  static final Dio _dio = Dio();

  /// Translate text from auto-detected language to target language
  static Future<String> translateText({
    required String text,
    required String targetLanguage,
  }) async {
    try {
      if (text.trim().isEmpty) return text;
      
      final response = await _dio.get(
        _translateApiUrl,
        queryParameters: {
          'client': 'gtx',
          'sl': 'auto', // Auto-detect source language
          'tl': targetLanguage,
          'dt': 't',
          'q': text,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty && data[0] is List) {
          final List<dynamic> translations = data[0];
          String translatedText = '';
          
          for (var translation in translations) {
            if (translation is List && translation.isNotEmpty) {
              translatedText += translation[0].toString();
            }
          }
          
          return translatedText.isNotEmpty ? translatedText : text;
        }
      }
      
      return text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  /// Get the currently selected language
  static Future<String> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageKey) ?? 'en';
  }

  /// Set the selected language
  static Future<void> setSelectedLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, languageCode);
  }

  /// Check if translation is enabled
  static Future<bool> isTranslationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_translationEnabledKey) ?? false;
  }

  /// Enable or disable translation
  static Future<void> setTranslationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_translationEnabledKey, enabled);
  }

  /// Get language name from code
  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode]?['name'] ?? languageCode.toUpperCase();
  }

  /// Get language flag from code
  static String getLanguageFlag(String languageCode) {
    return supportedLanguages[languageCode]?['flag'] ?? '🌐';
  }

  /// Get all supported languages
  static List<Map<String, String>> getSupportedLanguages() {
    return supportedLanguages.entries.map((entry) => {
      'code': entry.key,
      'name': entry.value['name']!,
      'flag': entry.value['flag']!,
    }).toList();
  }

  /// Check if a language is supported
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  /// Detect the language of given text
  static Future<String> detectLanguage(String text) async {
    try {
      if (text.trim().isEmpty) return 'en';

      final response = await _dio.get(
        _translateApiUrl,
        queryParameters: {
          'client': 'gtx',
          'sl': 'auto',
          'tl': 'en',
          'dt': 't',
          'q': text,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        if (data.length > 2 && data[2] != null) {
          return data[2].toString();
        }
      }
      
      return 'en';
    } catch (e) {
      print('Language detection error: $e');
      return 'en';
    }
  }
}
