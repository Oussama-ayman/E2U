import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fuodz/services/zego_video_call.service.dart';
import 'package:fuodz/widgets/video_call/video_call_widget.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/services/call_notification.service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DirectVideoCallService {
  static final DirectVideoCallService _instance =
      DirectVideoCallService._internal();
  factory DirectVideoCallService() => _instance;
  DirectVideoCallService._internal();

  bool _isInCall = false;

  // Generate a consistent channel name for the call (same for both customer and driver)
  String _generateChannelName(String orderId) {
    return 'geomart_call_$orderId';
  }

  // Get or create a shared channel name for an order
  Future<String> _getSharedChannelName(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingChannel = prefs.getString('channel_$orderId');

    if (existingChannel != null) {
      return existingChannel;
    }

    final newChannel = _generateChannelName(orderId);
    await prefs.setString('channel_$orderId', newChannel);
    return newChannel;
  }

  // Generate UID based on user type and ID
  int _generateUID(String userId, String userType) {
    final baseId = int.tryParse(userId) ?? Random().nextInt(999999);
    if (userType == 'customer') {
      return 1000000 + baseId; // Customer UIDs start with 1000000
    } else {
      return 2000000 + baseId; // Driver UIDs start with 2000000
    }
  }

  // Reset call state when call ends
  Future<void> endCall({String? orderId}) async {
    _isInCall = false;
    print('DirectVideoCall: Call state reset');

    // Clean up call notification file if orderId is provided
    if (orderId != null) {
      await _deleteCallNotificationFile(orderId);
      await _deleteActiveCallFile(orderId);
    }

    // Also clear all old call notifications
    await clearOldCallNotifications();
  }

  // Check camera and microphone permissions
  Future<bool> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
      final permissions =
          await [Permission.camera, Permission.microphone].request();
      return permissions[Permission.camera]?.isGranted == true &&
          permissions[Permission.microphone]?.isGranted == true;
    }

    return true;
  }

  // Initiate a direct video call
  Future<bool> initiateCall({
    required String orderId,
    required String callerId,
    required String callerName,
    required String callerType,
    required String receiverId,
    required String receiverName,
    required String receiverType,
  }) async {
    try {
      // Check if already in a call
      if (_isInCall) {
        print('DirectVideoCall: Already in a call, ignoring new call request');
        return false;
      }

      // Clear old call notifications first
      await clearOldCallNotifications();

      // Check if there's already an incoming call for this order
      if (await _hasIncomingCall(orderId)) {
        print(
          'DirectVideoCall: Incoming call detected, not initiating new call',
        );
        return false;
      }

      // Check if there's already an active call for this order
      if (await _hasActiveCall(orderId)) {
        print('DirectVideoCall: Active call detected, joining existing call');
        // Join the existing call instead of creating a new one
        return await _joinExistingCall(orderId, callerId, callerType);
      }

      // Check permissions first
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        throw Exception('Camera and microphone permissions required');
      }

      _isInCall = true;

      // Generate consistent channel name and UID
      final channelName = _generateChannelName(orderId);
      final uid = _generateUID(callerId, callerType);

      print(
        'DirectVideoCall: Initiating call - Channel: $channelName, UID: $uid',
      );

      // Create active call file to prevent duplicate calls
      await _createActiveCallFile(orderId, channelName, callerName, callerType);

      // Send call notification to the receiver
      await CallNotificationService.sendCallNotification(
        orderId: orderId,
        callerName: callerName,
        callerType: callerType,
        channelName: channelName,
        uid: uid, // Send caller's UID for reference
        receiverType: "driver", // Customer calling driver
      );

      // Show video call screen directly
      _showVideoCallScreen(
        channelName: channelName,
        uid: uid,
        callerName: callerName,
        receiverName: receiverName,
        isOutgoing: true,
        orderId: orderId,
      );

      return true;
    } catch (e) {
      print('Error initiating direct video call: $e');
      _isInCall = false;
      return false;
    }
  }

  // Join an existing video call
  Future<bool> joinCall({
    required String channelName,
    required String userId,
    required String userName,
    required String userType,
    required String otherUserName,
  }) async {
    try {
      // Check permissions first
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        throw Exception('Camera and microphone permissions required');
      }

      // Generate UID
      final uid = _generateUID(userId, userType);

      print('DirectVideoCall: Joining call - Channel: $channelName, UID: $uid');

      // Extract orderId from channelName (format: geomart_call_ORDER_ID)
      final orderId = channelName.replaceFirst('geomart_call_', '');

      // Show video call screen
      _showVideoCallScreen(
        channelName: channelName,
        uid: uid,
        callerName: otherUserName,
        receiverName: userName,
        isOutgoing: false,
        orderId: orderId,
      );

      return true;
    } catch (e) {
      print('Error joining direct video call: $e');
      return false;
    }
  }

  // Show video call screen
  void _showVideoCallScreen({
    required String channelName,
    required int uid,
    required String callerName,
    required String receiverName,
    required bool isOutgoing,
    String? orderId,
  }) {
    final context = AppService().navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  title: Text(
                    isOutgoing
                        ? 'Calling $receiverName...'
                        : 'Call from $callerName',
                    style: TextStyle(color: Colors.white),
                  ),
                  iconTheme: IconThemeData(color: Colors.white),
                ),
                body: VideoCallWidget(
                  channelName: channelName,
                  uid: uid,
                  orderId: orderId ?? "unknown",
                  onCallEnded: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  // Quick call method for testing
  Future<bool> quickCall({
    required String orderId,
    required String callerId,
    required String callerName,
    required String callerType,
  }) async {
    return await initiateCall(
      orderId: orderId,
      callerId: callerId,
      callerName: callerName,
      callerType: callerType,
      receiverId: 'test_receiver',
      receiverName: callerType == 'customer' ? 'Driver' : 'Customer',
      receiverType: callerType == 'customer' ? 'driver' : 'customer',
    );
  }

  // Check if there's an incoming call for this order
  Future<bool> _hasIncomingCall(String orderId) async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final file = File(
          '${directory.path}/geomart_call_notification_$orderId.json',
        );

        // Check if file exists and is recent (less than 5 minutes old)
        if (await file.exists()) {
          final stat = await file.stat();
          final now = DateTime.now();
          final fileAge = now.difference(stat.modified);

          // If file is older than 2 minutes, delete it and return false
          if (fileAge.inMinutes > 2) {
            print(
              'DirectVideoCall: Deleting old call notification file (${fileAge.inMinutes} minutes old)',
            );
            await file.delete();
            return false;
          }

          print(
            'DirectVideoCall: Found recent incoming call file (${fileAge.inMinutes} minutes old)',
          );
          return true;
        }
      }
    } catch (e) {
      print('Error checking for incoming call: $e');
    }
    return false;
  }

  // Check if there's already an active call for this order
  Future<bool> _hasActiveCall(String orderId) async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final file = File(
          '${directory.path}/geomart_active_call_$orderId.json',
        );

        if (await file.exists()) {
          final callDataJson = await file.readAsString();
          final callData = jsonDecode(callDataJson);

          // Check if call is recent (less than 5 minutes old)
          final timestamp = callData['timestamp'] ?? 0;
          final callTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();
          final callAge = now.difference(callTime);

          if (callAge.inMinutes > 5) {
            print('DirectVideoCall: Deleting old active call file');
            await file.delete();
            return false;
          }

          print('DirectVideoCall: Found active call for order $orderId');
          return true;
        }
      }
    } catch (e) {
      print('Error checking for active call: $e');
    }
    return false;
  }

  // Join an existing call
  Future<bool> _joinExistingCall(
    String orderId,
    String userId,
    String userType,
  ) async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final file = File(
          '${directory.path}/geomart_active_call_$orderId.json',
        );

        if (await file.exists()) {
          final callDataJson = await file.readAsString();
          final callData = jsonDecode(callDataJson);

          final channelName =
              callData['channelName'] ?? _generateChannelName(orderId);
          final uid = _generateUID(userId, userType);

          print(
            'DirectVideoCall: Joining existing call - Channel: $channelName, UID: $uid',
          );

          // Show video call screen directly
          _showVideoCallScreen(
            channelName: channelName,
            uid: uid,
            callerName: 'Joining Call',
            receiverName: 'Other User',
            isOutgoing: false,
            orderId: orderId,
          );

          return true;
        }
      }
    } catch (e) {
      print('Error joining existing call: $e');
    }
    return false;
  }

  // Create active call file
  Future<void> _createActiveCallFile(
    String orderId,
    String channelName,
    String callerName,
    String callerType,
  ) async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final file = File(
          '${directory.path}/geomart_active_call_$orderId.json',
        );

        final callData = {
          'orderId': orderId,
          'channelName': channelName,
          'callerName': callerName,
          'callerType': callerType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await file.writeAsString(jsonEncode(callData));
        print('DirectVideoCall: Created active call file for order $orderId');
      }
    } catch (e) {
      print('Error creating active call file: $e');
    }
  }

  // Delete a specific call notification file
  Future<void> _deleteCallNotificationFile(String orderId) async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        // Delete both customer and driver notification files for this order
        final customerFile = File(
          '${directory.path}/geomart_call_notification_${orderId}_customer.json',
        );
        final driverFile = File(
          '${directory.path}/geomart_call_notification_${orderId}_driver.json',
        );

        if (await customerFile.exists()) {
          await customerFile.delete();
          print(
            'DirectVideoCall: Deleted customer call notification file for order $orderId',
          );
        }

        if (await driverFile.exists()) {
          await driverFile.delete();
          print(
            'DirectVideoCall: Deleted driver call notification file for order $orderId',
          );
        }
      }
    } catch (e) {
      print('Error deleting call notification file for order $orderId: $e');
    }
  }

  // Delete a specific active call file
  Future<void> _deleteActiveCallFile(String orderId) async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final file = File(
          '${directory.path}/geomart_active_call_$orderId.json',
        );
        if (await file.exists()) {
          await file.delete();
          print('DirectVideoCall: Deleted active call file for order $orderId');
        }
      }
    } catch (e) {
      print('Error deleting active call file for order $orderId: $e');
    }
  }

  // Clear all old call notification files
  Future<void> clearOldCallNotifications() async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final files = await directory.list().toList();
        final now = DateTime.now();

        for (final entity in files) {
          if (entity is File &&
              entity.path.contains('geomart_call_notification_')) {
            try {
              final stat = await entity.stat();
              final fileAge = now.difference(stat.modified);

              // Delete files older than 2 minutes
              if (fileAge.inMinutes > 2) {
                print(
                  'DirectVideoCall: Deleting old call notification file: ${entity.path}',
                );
                await entity.delete();
              }
            } catch (e) {
              print(
                'Error deleting old call notification file ${entity.path}: $e',
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error clearing old call notifications: $e');
    }
  }

  // Clear ALL call notification files (for testing)
  Future<void> clearAllCallNotifications() async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final files = await directory.list().toList();

        for (final entity in files) {
          if (entity is File &&
              (entity.path.contains('geomart_call_notification_') ||
                  entity.path.contains('geomart_active_call_'))) {
            try {
              await entity.delete();
              print('DirectVideoCall: Deleted file: ${entity.path}');
            } catch (e) {
              print('Error deleting file ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error clearing all call notifications: $e');
    }
  }

  Future<void> dispose() async {
    await ZegoVideoCallService.uninitialize();
  }
}
