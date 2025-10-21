import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/views/pages/video_call/incoming_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallNotificationService {
  static final CallNotificationService _instance =
      CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  Timer? _callListenerTimer;
  String? _currentOrderId;
  bool _isListening = false;

  // Start listening for incoming calls for a specific order
  void startListening(String orderId) {
    _currentOrderId = orderId;
    if (_isListening) return;

    // Clear old notifications when starting to listen
    _clearOldNotifications();

    _isListening = true;
    _callListenerTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _checkForIncomingCalls();
    });

    print('CallNotification: Started listening for calls on order $orderId');
  }

  // Stop listening for incoming calls
  void stopListening() {
    _isListening = false;
    _callListenerTimer?.cancel();
    _callListenerTimer = null;
    _currentOrderId = null;
    print('CallNotification: Stopped listening for calls');
  }

  // Clear old notification files
  void _clearOldNotifications() async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final files = await directory.list().toList();

        for (final entity in files) {
          if (entity is File &&
              (entity.path.contains('geomart_call_notification_') ||
                  entity.path.contains('geomart_active_call_'))) {
            try {
              final stat = await entity.stat();
              final now = DateTime.now();
              final fileAge = now.difference(stat.modified);

              // Delete files older than 1 minute to clear old notifications
              if (fileAge.inMinutes > 1) {
                await entity.delete();
                print('CallNotification: Deleted old file: ${entity.path}');
              }
            } catch (e) {
              print('Error deleting old file ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error clearing old notifications: $e');
    }
  }

  // Check for incoming calls (cross-app file system)
  Future<void> _checkForIncomingCalls() async {
    if (!_isListening || _currentOrderId == null) return;

    try {
      // First check shared external storage for cross-app notifications
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        // Check for notifications from driver app (the other app)
        final driverFile = File(
          '${directory.path}/geomart_call_notification_${_currentOrderId}_driver.json',
        );

        print('CallNotification: Checking for driver file: ${driverFile.path}');

        if (await driverFile.exists()) {
          final callDataJson = await driverFile.readAsString();
          final callData = jsonDecode(callDataJson);

          print(
            'CallNotification: Found driver notification file with data: $callData',
          );

          // This is from the driver app, so process it
          final callerApp = callData['callerApp'] ?? '';
          if (callerApp == 'driver') {
            print('CallNotification: Processing incoming call from driver app');
            // Remove the file to prevent duplicate notifications
            await driverFile.delete();

            // Show incoming call screen
            _showIncomingCallScreen(
              callerName: callData['callerName'] ?? 'Unknown',
              callerType: callData['callerType'] ?? 'driver',
              channelName: callData['channelName'] ?? '',
              uid: callData['uid'] ?? 0,
            );
            return;
          }
        }

        // Also check for our own notifications (to ignore them)
        final customerFile = File(
          '${directory.path}/geomart_call_notification_${_currentOrderId}_customer.json',
        );

        if (await customerFile.exists()) {
          final callDataJson = await customerFile.readAsString();
          final callData = jsonDecode(callDataJson);

          // Check if this notification is from the same app (ignore own notifications)
          final callerApp = callData['callerApp'] ?? '';
          if (callerApp == 'customer') {
            print(
              'CallNotification: Ignoring own notification from customer app',
            );
            return;
          }
        }
      } else {
        print('CallNotification: Download directory does not exist');
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final callDataJson = prefs.getString('incoming_call_${_currentOrderId}');

      if (callDataJson != null) {
        final callData = jsonDecode(callDataJson);

        // Remove the call data to prevent duplicate notifications
        await prefs.remove('incoming_call_${_currentOrderId}');

        print(
          'CallNotification: Received call notification from prefs for order $_currentOrderId',
        );

        // Show incoming call screen
        _showIncomingCallScreen(
          callerName: callData['callerName'] ?? 'Unknown',
          callerType: callData['callerType'] ?? 'driver',
          channelName: callData['channelName'] ?? '',
          uid: callData['uid'] ?? 0,
        );
      }
    } catch (e) {
      print('Error checking for incoming calls: $e');
    }
  }

  // Show incoming call screen
  void _showIncomingCallScreen({
    required String callerName,
    required String callerType,
    required String channelName,
    required int uid,
  }) {
    final context = AppService().navigatorKey.currentContext;
    if (context != null) {
      // Play ringtone when incoming call is detected
      AppService().playNotificationSound();

      // Show custom incoming call screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            callId: channelName,
            callerName: callerName,
            callerPhoto: '', // No photo available from notification
            callerType: callerType,
            callType: 'video', // Default to video call
            onCallAccepted: () {
              print('CallNotification: Call accepted for $callerName');
              // ZegoCloud will handle the actual call UI
            },
            onCallDeclined: () {
              print('CallNotification: Call declined for $callerName');
            },
          ),
        ),
      );

      print('CallNotification: Showing incoming call screen for $callerName');
    }
  }

  // Send call notification to another user (cross-app)
  static Future<void> sendCallNotification({
    required String orderId,
    required String callerName,
    required String callerType,
    required String channelName,
    required int uid,
    required String receiverType,
  }) async {
    try {
      print(
        'CallNotification: Attempting to send notification for order $orderId',
      );

      // Use shared external storage for cross-app communication
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final file = File(
          '${directory.path}/geomart_call_notification_${orderId}_${receiverType}.json',
        );

        final callData = {
          'callerName': callerName,
          'callerType': callerType,
          'channelName': channelName,
          'uid': uid,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'callerApp': 'customer', // Identify which app sent the notification
        };

        await file.writeAsString(jsonEncode(callData));
        print(
          'CallNotification: Successfully sent call notification for order $orderId to ${file.path}',
        );
        print('CallNotification: Notification data: $callData');
      } else {
        print(
          'CallNotification: Download directory does not exist, using fallback',
        );
        // Fallback to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final callData = {
          'callerName': callerName,
          'callerType': callerType,
          'channelName': channelName,
          'uid': uid,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await prefs.setString('incoming_call_$orderId', jsonEncode(callData));
        print(
          'CallNotification: Sent call notification for order $orderId (fallback)',
        );
      }
    } catch (e) {
      print('Error sending call notification: $e');
    }
  }

  void dispose() {
    stopListening();
  }
}
