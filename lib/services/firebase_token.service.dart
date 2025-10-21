import 'dart:developer';

// Removed Firebase imports
import 'package:fuodz/requests/auth.request.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:singleton/singleton.dart';

import 'local_storage.service.dart';

class FirebaseTokenService {
  //
  /// Factory method that reuse same instance automatically
  factory FirebaseTokenService() =>
      Singleton.lazy(() => FirebaseTokenService._());

  /// Private constructor
  FirebaseTokenService._() {}

  dynamic firebaseMessaging; // Replaced FirebaseMessaging

  // Firebase initialization removed

  static String DEVICE_TOKEN_STORE_KEY = "device_token";

  handleDeviceTokenSync() async {
    print("Firebase token sync disabled - using new chat system");
    // Firebase token sync removed
  }

  syncDeviceTokenWithServer(String? deviceToken) async {
    try {
      final storagePref = await LocalStorageService.getPrefs();
      //check if saved token is same as current token
      String? savedToken = storagePref.getString(DEVICE_TOKEN_STORE_KEY);
      //if token is not saved or is different from current token
      if (savedToken == deviceToken) {
        return;
      }
      //save token
      await storagePref.setString(DEVICE_TOKEN_STORE_KEY, deviceToken!);
      //send token to server if the auth is logged in
      if (AuthServices.authenticated()) {
        await AuthRequest().updateDeviceToken(deviceToken);
      }
    } catch (error) {
      log("Error syncing device token with server: $error");
    }
  }

  Future<String?> getDeviceToken() async {
    String? deviceToken;
    try {
      final storagePref = await LocalStorageService.getPrefs();
      deviceToken = storagePref.getString(DEVICE_TOKEN_STORE_KEY);
      //
      if (deviceToken == null) {
        await handleDeviceTokenSync();
      }
      //last try
      deviceToken = storagePref.getString(DEVICE_TOKEN_STORE_KEY);
    } catch (error) {
      log("Error getting device token: $error");
    }
    return deviceToken ?? "no_firebase_token";
  }
}
