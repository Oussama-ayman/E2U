import 'package:flutter/material.dart';
import 'package:fuodz/services/custom_video_call.service.dart';
import 'package:fuodz/constants/app_colors.dart';

class VideoCallTestPage extends StatefulWidget {
  const VideoCallTestPage({Key? key}) : super(key: key);

  @override
  State<VideoCallTestPage> createState() => _VideoCallTestPageState();
}

class _VideoCallTestPageState extends State<VideoCallTestPage> {
  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default values for testing
    _receiverIdController.text = "3"; // Driver ID
    _receiverNameController.text = "Driver Account";
  }

  Future<void> _makeVideoCall() async {
    if (_receiverIdController.text.isEmpty || _receiverNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in both Receiver ID and Name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await CustomVideoCallService.makeVideoCall(
        receiverId: _receiverIdController.text,
        receiverName: _receiverNameController.text,
        callType: 'video',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video call initiated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to make call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _makeVoiceCall() async {
    if (_receiverIdController.text.isEmpty || _receiverNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in both Receiver ID and Name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await CustomVideoCallService.makeVideoCall(
        receiverId: _receiverIdController.text,
        receiverName: _receiverNameController.text,
        callType: 'voice',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice call initiated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to make call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Video Call Test'),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Status
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        CustomVideoCallService.isInitialized 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: CustomVideoCallService.isInitialized 
                            ? Colors.green 
                            : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Service Status: ${CustomVideoCallService.isInitialized ? "Ready" : "Not Ready"}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (CustomVideoCallService.currentCallId != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Current Call: ${CustomVideoCallService.currentCallId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Input Fields
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Call Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  TextField(
                    controller: _receiverIdController,
                    decoration: InputDecoration(
                      labelText: 'Receiver ID (Driver ID)',
                      hintText: 'e.g., 3',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  TextField(
                    controller: _receiverNameController,
                    decoration: InputDecoration(
                      labelText: 'Receiver Name',
                      hintText: 'e.g., Driver Account',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Call Buttons
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Make a Call',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _makeVideoCall,
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.videocam),
                          label: Text('Video Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 16),
                      
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _makeVoiceCall,
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.phone),
                          label: Text('Voice Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Instructions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'How to Test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Make sure both Customer and Driver apps are running\n'
                    '2. Enter the Driver ID (usually "3") in Receiver ID\n'
                    '3. Enter Driver name in Receiver Name\n'
                    '4. Click "Video Call" button\n'
                    '5. Check that outgoing call screen appears\n'
                    '6. Driver app should show incoming call screen',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _receiverIdController.dispose();
    _receiverNameController.dispose();
    super.dispose();
  }
}
