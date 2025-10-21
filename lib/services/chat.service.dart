// Removed firestore_chat import
import 'package:fuodz/requests/chat.request.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:fuodz/services/enhanced_translation.service.dart';

class ChatService {
  //
  static sendChatMessage(String message, dynamic chatEntity) async {
    //notify the involved party
    final otherPeerKey = chatEntity.peers.keys.firstWhere(
      (peerKey) => chatEntity.mainUser.id != peerKey,
    );
    //
    final otherPeer = chatEntity.peers[otherPeerKey];

    // Try to translate message for notification if auto-translate is enabled
    String notificationMessage = message;
    try {
      final isAutoTranslateEnabled =
          await EnhancedTranslationService.isAutoTranslateEnabled();
      if (isAutoTranslateEnabled) {
        final preferredLanguage =
            await EnhancedTranslationService.getSelectedLanguage();
        final detectedLanguage =
            await EnhancedTranslationService.detectLanguage(message);

        // Only translate if the message is not already in the preferred language
        if (detectedLanguage != preferredLanguage) {
          notificationMessage = await EnhancedTranslationService.translateText(
            text: message,
            targetLanguage: preferredLanguage,
          );
        }
      }
    } catch (e) {
      print("Translation error for notification: $e");
      // Use original message if translation fails
    }

    final apiResponse = await ChatRequest().sendNotification(
      title: "New Message from".tr() + " ${chatEntity.mainUser.name}",
      body: notificationMessage,
      topic: otherPeer!.id,
      path: chatEntity.path,
      user: chatEntity.mainUser,
      otherUser: otherPeer,
    );

    print("Result ==> ${apiResponse.body}");
  }
}
