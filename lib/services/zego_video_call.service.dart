import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:fuodz/services/app_permission_handler.service.dart';

class ZegoVideoCallService {
  // ZegoCloud credentials - Updated to use the working credentials
  static const int appID = 1386611196;
  static const String appSign =
      'a3c2d5d7fee736984686f5bff89c066a02efb63f91794f7e2907931ae9acb13e';

  static bool _isInitialized = false;

  // Check if ZegoCloud can be initialized (overlay permission granted)
  static Future<bool> canInitialize() async {
    if (Platform.isAndroid) {
      return await AppPermissionHandlerService.isOverlayPermissionGranted();
    }
    return true; // On iOS, no overlay permission needed
  }

  // Initialize ZegoCloud service with default user
  static Future<void> initialize() async {
    await initializeWithUser('customer_1000004', 'Customer User');
  }

  // Initialize ZegoCloud service with specific user
  static Future<void> initializeWithUser(String userID, String userName) async {
    // Check if we can initialize (overlay permission granted)
    if (!await canInitialize()) {
      debugPrint(
        'ZegoVideoCall: Cannot initialize - overlay permission not granted',
      );
      return;
    }

    if (_isInitialized) {
      await uninitialize();
    }

    try {
      debugPrint(
        'ZegoVideoCall: Initializing ZegoCloud service for customer: $userID',
      );

      // Initialize ZegoUIKitPrebuiltCallInvitationService
      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: appID,
        appSign: appSign,
        userID: userID,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
      );

      _isInitialized = true;
      debugPrint('ZegoVideoCall: ZegoCloud service initialized successfully');
    } catch (e) {
      debugPrint('ZegoVideoCall: Error initializing service: $e');
      rethrow;
    }
  }

  // Uninitialize service
  static Future<void> uninitialize() async {
    try {
      debugPrint('ZegoVideoCall: Uninitializing ZegoCloud service...');
      ZegoUIKitPrebuiltCallInvitationService().uninit();
      _isInitialized = false;
      debugPrint('ZegoVideoCall: Service uninitialized');
    } catch (e) {
      debugPrint('ZegoVideoCall: Error uninitializing service: $e');
    }
  }

  // Make a video call to driver
  static Future<void> makeVideoCall(
    String driverUserID,
    String driverName,
  ) async {
    try {
      debugPrint('ZegoVideoCall: Making video call to driver: $driverUserID');

      // Check if we can make the call (overlay permission granted)
      if (!await canInitialize()) {
        debugPrint(
          'ZegoVideoCall: Cannot make video call - overlay permission not granted',
        );
        // You could show a dialog here asking user to grant overlay permission
        throw Exception('Overlay permission required for video calls');
      }

      // Ensure service is initialized
      if (!_isInitialized) {
        await initializeWithUser('customer_1000004', 'Customer User');
      }

      // Send call invitation to driver
      ZegoUIKitPrebuiltCallInvitationService().send(
        isVideoCall: true,
        invitees: [ZegoCallUser(driverUserID, driverName)],
        customData: 'Customer calling driver for order assistance',
      );

      debugPrint('ZegoVideoCall: Video call invitation sent successfully');
    } catch (e) {
      debugPrint('ZegoVideoCall: Error making video call: $e');
      rethrow;
    }
  }

  // Make a voice call to driver
  static Future<void> makeVoiceCall(
    String driverUserID,
    String driverName,
  ) async {
    try {
      debugPrint('ZegoVideoCall: Making voice call to driver: $driverUserID');

      // Check if we can make the call (overlay permission granted)
      if (!await canInitialize()) {
        debugPrint(
          'ZegoVideoCall: Cannot make voice call - overlay permission not granted',
        );
        // You could show a dialog here asking user to grant overlay permission
        throw Exception('Overlay permission required for voice calls');
      }

      // Ensure service is initialized
      if (!_isInitialized) {
        await initializeWithUser('customer_1000004', 'Customer User');
      }

      // Send call invitation to driver
      ZegoUIKitPrebuiltCallInvitationService().send(
        isVideoCall: false,
        invitees: [ZegoCallUser(driverUserID, driverName)],
        customData: 'Customer calling driver for order assistance',
      );

      debugPrint('ZegoVideoCall: Voice call invitation sent successfully');
    } catch (e) {
      debugPrint('ZegoVideoCall: Error making voice call: $e');
      rethrow;
    }
  }

  // Update user info
  static Future<void> updateUserInfo(String userID, String userName) async {
    try {
      debugPrint('ZegoVideoCall: Updating user info: $userID, $userName');

      // Update user information
      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: appID,
        appSign: appSign,
        userID: userID,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
      );

      debugPrint('ZegoVideoCall: User info updated successfully');
    } catch (e) {
      debugPrint('ZegoVideoCall: Error updating user info: $e');
      rethrow;
    }
  }

  // Check if service is initialized
  static bool get isInitialized => _isInitialized;

  // Create call notification for driver app compatibility
  static Future<void> createCallNotification(
    String orderId,
    String channelName,
  ) async {
    try {
      debugPrint(
        'ZegoVideoCall: Creating call notification for order: $orderId',
      );

      final directory = await getExternalStorageDirectory();
      if (directory == null) return;

      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }

      final callFile = File(
        '${downloadDir.path}/geomart_call_notification_${orderId}_driver.json',
      );

      final callData = {
        'callerName': 'Customer Account',
        'callerType': 'customer',
        'channelName': channelName,
        'uid': 'customer_1000004',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'callerApp': 'customer',
        'zegoCall': true, // Flag to indicate ZegoCloud call
      };

      await callFile.writeAsString(callData.toString());
      debugPrint(
        'ZegoVideoCall: Call notification created at: ${callFile.path}',
      );
    } catch (e) {
      debugPrint('ZegoVideoCall: Error creating call notification: $e');
    }
  }

  // Clean up call notification
  static Future<void> cleanupCallNotification(String orderId) async {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      final callFile = File(
        '${downloadDir.path}/geomart_call_notification_${orderId}_driver.json',
      );

      if (callFile.existsSync()) {
        await callFile.delete();
        debugPrint('ZegoVideoCall: Call notification cleaned up');
      }
    } catch (e) {
      debugPrint('ZegoVideoCall: Error cleaning up call notification: $e');
    }
  }
}
