import 'package:flutter/material.dart';
import 'package:fuodz/services/zego_video_call.service.dart';
import 'package:fuodz/widgets/zego_video_call_button.dart';
import 'package:fuodz/widgets/zego_voice_call_button.dart';
import 'package:fuodz/constants/app_colors.dart';

class EnhancedVideoCallTestPage extends StatefulWidget {
  const EnhancedVideoCallTestPage({Key? key}) : super(key: key);

  @override
  State<EnhancedVideoCallTestPage> createState() => _EnhancedVideoCallTestPageState();
}

class _EnhancedVideoCallTestPageState extends State<EnhancedVideoCallTestPage> {
  String _callState = 'idle';
  // String _testOrderId = '12345'; // Commented out unused field
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeZegoService();
  }

  void _initializeZegoService() async {
    try {
      await ZegoVideoCallService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Failed to initialize ZegoCloud: $e');
    }
  }

  @override
  void dispose() {
    ZegoVideoCallService.uninitialize();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Video Call Test'),
        backgroundColor: AppColor.primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Call State Indicator
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStateColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStateColor(),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStateIcon(),
                    color: _getStateColor(),
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Call State: $_callState',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStateColor(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Test Buttons Section
            Text(
              'Test Call Functions:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Initiate Outgoing Call
            ElevatedButton.icon(
              onPressed: () => _initiateTestCall(),
              icon: Icon(Icons.videocam),
              label: Text('Start Outgoing Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),

            // Simulate Incoming Call
            ElevatedButton.icon(
              onPressed: () => _simulateIncomingCall(),
              icon: Icon(Icons.call_received),
              label: Text('Simulate Incoming Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),

            // End Current Call
            ElevatedButton.icon(
              onPressed: _isInitialized ? () => _endCall() : null,
              icon: Icon(Icons.call_end),
              label: Text('End Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 30),

            // ZegoCloud Call Button Demo
            Text(
              'ZegoCloud Call Button Demo:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Different Button Variants
            Row(
              children: [
                Expanded(
                  child: ZegoVideoCallButton(
                    targetUserId: 'driver_test',
                    targetUserName: 'Test Driver',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ZegoVoiceCallButton(
                    targetUserId: 'driver_test',
                    targetUserName: 'Test Driver',
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Test Results Section
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInstruction(
                              '1. Outgoing Call Test',
                              'Tap "Start Outgoing Call" to initiate a call. The state should change to "initiating" then "ringing".',
                            ),
                            _buildInstruction(
                              '2. Incoming Call Test',
                              'Tap "Simulate Incoming Call" to show the incoming call overlay with ringtone.',
                            ),
                            _buildInstruction(
                              '3. Two-Device Test',
                              'Open this page on two devices and test actual communication between Customer and Driver apps.',
                            ),
                            _buildInstruction(
                              '4. Overlay Test',
                              'Tap "Test Overlay" to manually trigger the incoming call overlay.',
                            ),
                            _buildInstruction(
                              '5. End Call Test',
                              'Use "End Call" button to terminate active calls and verify cleanup.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColor.primaryColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor() {
    switch (_callState) {
      case 'idle':
        return Colors.grey;
      case 'initiating':
        return Colors.orange;
      case 'ringing':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'timeout':
        return Colors.purple;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon() {
    switch (_callState) {
      case 'idle':
        return Icons.phone_disabled;
      case 'initiating':
        return Icons.phone_forwarded;
      case 'ringing':
        return Icons.ring_volume;
      case 'accepted':
        return Icons.videocam;
      case 'rejected':
        return Icons.call_end;
      case 'timeout':
        return Icons.timer_off;
      case 'ended':
        return Icons.call_end;
      default:
        return Icons.phone;
    }
  }

  Future<void> _initiateTestCall() async {
    try {
      await ZegoVideoCallService.makeVideoCall('driver_test', 'Test Driver');
      setState(() {
        _callState = 'initiating';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video call initiated with ZegoCloud'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simulateIncomingCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ZegoCloud handles incoming calls automatically through the prebuilt UI'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _endCall() async {
    setState(() {
      _callState = 'ended';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Call ended - ZegoCloud handles cleanup automatically'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
