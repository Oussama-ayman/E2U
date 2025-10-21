import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class SimpleVideoCallTestPage extends StatefulWidget {
  const SimpleVideoCallTestPage({Key? key}) : super(key: key);

  @override
  State<SimpleVideoCallTestPage> createState() =>
      _SimpleVideoCallTestPageState();
}

class _SimpleVideoCallTestPageState extends State<SimpleVideoCallTestPage> {
  bool _isInitialized = false;
  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _receiverIdController.text = "test_driver_123";
    _receiverNameController.text = "Test Driver";
    _initializeZegoCloud();
  }

  Future<void> _initializeZegoCloud() async {
    try {
      // Initialize ZegoCloud directly without authentication
      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: 1452620307,
        appSign:
            '8dd923124e1558cd11775f0e41d66558442d6f6dd13c3b817d89d89d4bbecbd7d1c',
        userID: 'test_customer_123',
        userName: 'Test Customer',
        plugins: [ZegoUIKitSignalingPlugin()],
        requireConfig: (ZegoCallInvitationData data) {
          final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();
          config.topMenuBar.isVisible = true;
          config.bottomMenuBar.isVisible = true;
          return config;
        },
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
            print('Call ended: ${event.reason}');
            defaultAction.call();
          },
        ),
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onIncomingCallDeclineButtonPressed: () {
            print('Incoming call declined');
          },
          onIncomingCallAcceptButtonPressed: () {
            print('Incoming call accepted');
          },
          onOutgoingCallCancelButtonPressed: () {
            print('Outgoing call cancelled');
          },
        ),
      );

      setState(() {
        _isInitialized = true;
      });
      print('ZegoCloud initialized successfully!');
    } catch (e) {
      print('Error initializing ZegoCloud: $e');
    }
  }

  Future<void> _makeVideoCall() async {
    try {
      final receiverId = _receiverIdController.text;
      final receiverName = _receiverNameController.text;

      print('Making video call to: $receiverName ($receiverId)');

      await ZegoUIKitPrebuiltCallInvitationService().send(
        isVideoCall: true,
        invitees: [ZegoCallUser(receiverId, receiverName)],
        customData: 'Test video call from customer app',
      );

      print('Video call invitation sent!');
    } catch (e) {
      print('Error making video call: $e');
    }
  }

  Future<void> _makeVoiceCall() async {
    try {
      final receiverId = _receiverIdController.text;
      final receiverName = _receiverNameController.text;

      print('Making voice call to: $receiverName ($receiverId)');

      await ZegoUIKitPrebuiltCallInvitationService().send(
        isVideoCall: false,
        invitees: [ZegoCallUser(receiverId, receiverName)],
        customData: 'Test voice call from customer app',
      );

      print('Voice call invitation sent!');
    } catch (e) {
      print('Error making voice call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Video Call Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'ZegoCloud Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isInitialized ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isInitialized ? 'READY' : 'NOT READY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Receiver Info
            TextField(
              controller: _receiverIdController,
              decoration: InputDecoration(
                labelText: 'Receiver ID',
                border: OutlineInputBorder(),
                hintText: 'e.g., test_driver_123',
              ),
            ),

            SizedBox(height: 16),

            TextField(
              controller: _receiverNameController,
              decoration: InputDecoration(
                labelText: 'Receiver Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Test Driver',
              ),
            ),

            SizedBox(height: 20),

            // Call Buttons
            ElevatedButton.icon(
              onPressed: _isInitialized ? _makeVideoCall : null,
              icon: Icon(Icons.videocam),
              label: Text('Make Video Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isInitialized ? _makeVoiceCall : null,
              icon: Icon(Icons.call),
              label: Text('Make Voice Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 20),

            // Instructions
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Make sure both Customer and Driver apps are running',
                    ),
                    Text('2. Use the same Receiver ID in both apps'),
                    Text('3. Click "Make Video Call" or "Make Voice Call"'),
                    Text('4. Check Driver app for incoming call screen'),
                    Text('5. Accept call to see video/voice call interface'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    super.dispose();
  }
}
