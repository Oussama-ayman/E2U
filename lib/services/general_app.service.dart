import 'dart:async';
// Removed Firebase imports
// Removed firebase.service import

class GeneralAppService {
  //

  //Handle background message - DISABLED
  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessageHandler(dynamic message) async {
    print("Background message handler disabled - using new chat system");
    // Firebase background message handling removed
  }
}
