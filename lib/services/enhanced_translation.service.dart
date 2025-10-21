import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class EnhancedTranslationService {
  static const String _selectedLanguageKey = 'selected_translation_language';
  static const String _translationEnabledKey = 'translation_enabled';
  static const String _autoTranslateKey = 'auto_translate_enabled';
  static const String _translateApiUrl = 'https://translate.googleapis.com/translate_a/single';
  
  static final Dio _dio = Dio();
  static final Map<String, String> _translationCache = {};
  
  // Supported languages with flags
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
    'th': {'name': 'Thai', 'flag': '🇹🇭'},
    'vi': {'name': 'Vietnamese', 'flag': '🇻🇳'},
    'tr': {'name': 'Turkish', 'flag': '🇹🇷'},
    'pl': {'name': 'Polish', 'flag': '🇵🇱'},
    'nl': {'name': 'Dutch', 'flag': '🇳🇱'},
    'sv': {'name': 'Swedish', 'flag': '🇸🇪'},
    'da': {'name': 'Danish', 'flag': '🇩🇰'},
    'no': {'name': 'Norwegian', 'flag': '🇳🇴'},
    'fi': {'name': 'Finnish', 'flag': '🇫🇮'},
    'el': {'name': 'Greek', 'flag': '🇬🇷'},
    'he': {'name': 'Hebrew', 'flag': '🇮🇱'},
    'cs': {'name': 'Czech', 'flag': '🇨🇿'},
    'sk': {'name': 'Slovak', 'flag': '🇸🇰'},
    'hu': {'name': 'Hungarian', 'flag': '🇭🇺'},
    'ro': {'name': 'Romanian', 'flag': '🇷🇴'},
    'bg': {'name': 'Bulgarian', 'flag': '🇧🇬'},
    'hr': {'name': 'Croatian', 'flag': '🇭🇷'},
    'sr': {'name': 'Serbian', 'flag': '🇷🇸'},
    'sl': {'name': 'Slovenian', 'flag': '🇸🇮'},
    'et': {'name': 'Estonian', 'flag': '🇪🇪'},
    'lv': {'name': 'Latvian', 'flag': '🇱🇻'},
    'lt': {'name': 'Lithuanian', 'flag': '🇱🇹'},
    'uk': {'name': 'Ukrainian', 'flag': '🇺🇦'},
    'be': {'name': 'Belarusian', 'flag': '🇧🇾'},
    'ka': {'name': 'Georgian', 'flag': '🇬🇪'},
    'am': {'name': 'Amharic', 'flag': '🇪🇹'},
    'sw': {'name': 'Swahili', 'flag': '🇰🇪'},
    'zu': {'name': 'Zulu', 'flag': '🇿🇦'},
    'af': {'name': 'Afrikaans', 'flag': '🇿🇦'},
    'sq': {'name': 'Albanian', 'flag': '🇦🇱'},
    'az': {'name': 'Azerbaijani', 'flag': '🇦🇿'},
    'eu': {'name': 'Basque', 'flag': '🏴'},
    'bn': {'name': 'Bengali', 'flag': '🇧🇩'},
    'bs': {'name': 'Bosnian', 'flag': '🇧🇦'},
    'ca': {'name': 'Catalan', 'flag': '🏴'},
    'ceb': {'name': 'Cebuano', 'flag': '🇵🇭'},
    'co': {'name': 'Corsican', 'flag': '🇫🇷'},
    'cy': {'name': 'Welsh', 'flag': '🏴󠁧󠁢󠁷󠁬󠁳󠁿'},
    'eo': {'name': 'Esperanto', 'flag': '🌍'},
    'fa': {'name': 'Persian', 'flag': '🇮🇷'},
    'fy': {'name': 'Frisian', 'flag': '🇳🇱'},
    'ga': {'name': 'Irish', 'flag': '🇮🇪'},
    'gd': {'name': 'Scots Gaelic', 'flag': '🏴󠁧󠁢󠁳󠁣󠁴󠁿'},
    'gl': {'name': 'Galician', 'flag': '🇪🇸'},
    'gu': {'name': 'Gujarati', 'flag': '🇮🇳'},
    'ha': {'name': 'Hausa', 'flag': '🇳🇬'},
    'haw': {'name': 'Hawaiian', 'flag': '🇺🇸'},
    'hmn': {'name': 'Hmong', 'flag': '🇱🇦'},
    'is': {'name': 'Icelandic', 'flag': '🇮🇸'},
    'ig': {'name': 'Igbo', 'flag': '🇳🇬'},
    'id': {'name': 'Indonesian', 'flag': '🇮🇩'},
    'jw': {'name': 'Javanese', 'flag': '🇮🇩'},
    'kn': {'name': 'Kannada', 'flag': '🇮🇳'},
    'kk': {'name': 'Kazakh', 'flag': '🇰🇿'},
    'km': {'name': 'Khmer', 'flag': '🇰🇭'},
    'rw': {'name': 'Kinyarwanda', 'flag': '🇷🇼'},
    'ku': {'name': 'Kurdish', 'flag': '🇮🇶'},
    'ky': {'name': 'Kyrgyz', 'flag': '🇰🇬'},
    'lo': {'name': 'Lao', 'flag': '🇱🇦'},
    'la': {'name': 'Latin', 'flag': '🏛️'},
    'lb': {'name': 'Luxembourgish', 'flag': '🇱🇺'},
    'mk': {'name': 'Macedonian', 'flag': '🇲🇰'},
    'mg': {'name': 'Malagasy', 'flag': '🇲🇬'},
    'ms': {'name': 'Malay', 'flag': '🇲🇾'},
    'ml': {'name': 'Malayalam', 'flag': '🇮🇳'},
    'mt': {'name': 'Maltese', 'flag': '🇲🇹'},
    'mi': {'name': 'Maori', 'flag': '🇳🇿'},
    'mr': {'name': 'Marathi', 'flag': '🇮🇳'},
    'mn': {'name': 'Mongolian', 'flag': '🇲🇳'},
    'my': {'name': 'Myanmar', 'flag': '🇲🇲'},
    'ne': {'name': 'Nepali', 'flag': '🇳🇵'},
    'ny': {'name': 'Chichewa', 'flag': '🇲🇼'},
    'or': {'name': 'Odia', 'flag': '🇮🇳'},
    'ps': {'name': 'Pashto', 'flag': '🇦🇫'},
    'pa': {'name': 'Punjabi', 'flag': '🇮🇳'},
    'sm': {'name': 'Samoan', 'flag': '🇼🇸'},
    'sn': {'name': 'Shona', 'flag': '🇿🇼'},
    'sd': {'name': 'Sindhi', 'flag': '🇵🇰'},
    'si': {'name': 'Sinhala', 'flag': '🇱🇰'},
    'so': {'name': 'Somali', 'flag': '🇸🇴'},
    'st': {'name': 'Sesotho', 'flag': '🇱🇸'},
    'su': {'name': 'Sundanese', 'flag': '🇮🇩'},
    'tg': {'name': 'Tajik', 'flag': '🇹🇯'},
    'ta': {'name': 'Tamil', 'flag': '🇮🇳'},
    'tt': {'name': 'Tatar', 'flag': '🇷🇺'},
    'te': {'name': 'Telugu', 'flag': '🇮🇳'},
    'tk': {'name': 'Turkmen', 'flag': '🇹🇲'},
    'tl': {'name': 'Filipino', 'flag': '🇵🇭'},
    'ur': {'name': 'Urdu', 'flag': '🇵🇰'},
    'ug': {'name': 'Uyghur', 'flag': '🇨🇳'},
    'uz': {'name': 'Uzbek', 'flag': '🇺🇿'},
    'xh': {'name': 'Xhosa', 'flag': '🇿🇦'},
    'yi': {'name': 'Yiddish', 'flag': '🇮🇱'},
    'yo': {'name': 'Yoruba', 'flag': '🇳🇬'},
  };

  /// Translate text from auto-detected language to target language
  static Future<String> translateText({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    try {
      if (text.trim().isEmpty) return text;
      
      // Check cache first
      final cacheKey = '${text}_${sourceLanguage}_$targetLanguage';
      if (_translationCache.containsKey(cacheKey)) {
        return _translationCache[cacheKey]!;
      }

      final response = await _dio.get(
        _translateApiUrl,
        queryParameters: {
          'client': 'gtx',
          'sl': sourceLanguage,
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
          
          if (translatedText.isNotEmpty) {
            // Cache the result
            _translationCache[cacheKey] = translatedText;
            return translatedText;
          }
        }
      }
      
      return text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
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
      debugPrint('Language detection error: $e');
      return 'en';
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

  /// Set translation enabled state
  static Future<void> setTranslationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_translationEnabledKey, enabled);
  }

  /// Check if auto-translate is enabled
  static Future<bool> isAutoTranslateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoTranslateKey) ?? false;
  }

  /// Set auto-translate enabled state
  static Future<void> setAutoTranslateEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoTranslateKey, enabled);
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

  /// Clear translation cache
  static void clearCache() {
    _translationCache.clear();
  }
}
