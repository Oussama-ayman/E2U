import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';

class VideoCallWidget extends StatefulWidget {
  final String channelName;
  final int uid;
  final String orderId;
  final VoidCallback? onCallEnded;

  const VideoCallWidget({
    Key? key,
    required this.channelName,
    required this.uid,
    required this.orderId,
    this.onCallEnded,
  }) : super(key: key);

  @override
  State<VideoCallWidget> createState() => _VideoCallWidgetState();
}

class _VideoCallWidgetState extends State<VideoCallWidget> {
  bool _isCallActive = true;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  void _initializeCall() {
    print('VideoCallWidget: Initializing call for channel: ${widget.channelName}');
    // ZegoCloud initialization would go here
  }

  @override
  void dispose() {
    _endCall();
    super.dispose();
  }

  void _endCall() {
    if (_isCallActive) {
      _isCallActive = false;
      widget.onCallEnded?.call();
      print('VideoCallWidget: Call ended for order ${widget.orderId}');
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    print('VideoCallWidget: Audio ${_isMuted ? 'muted' : 'unmuted'}');
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    print('VideoCallWidget: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    print('VideoCallWidget: Speaker ${_isSpeakerOn ? 'on' : 'off'}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video display area
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    size: 100,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Video Call Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Channel: ${widget.channelName}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'UID: ${widget.uid}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control buttons at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute button
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  onPressed: _toggleMute,
                  backgroundColor: _isMuted ? Colors.red : Colors.white24,
                ),

                // Speaker button
                _buildControlButton(
                  icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  onPressed: _toggleSpeaker,
                  backgroundColor: _isSpeakerOn ? AppColor.primaryColor : Colors.white24,
                ),

                // Video toggle button
                _buildControlButton(
                  icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  onPressed: _toggleVideo,
                  backgroundColor: _isVideoEnabled ? Colors.white24 : Colors.red,
                ),

                // End call button
                _buildControlButton(
                  icon: Icons.call_end,
                  onPressed: () {
                    _endCall();
                    Navigator.of(context).pop();
                  },
                  backgroundColor: Colors.red,
                ),
              ],
            ),
          ),

          // Top info bar
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: Colors.green,
                    size: 12,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Connected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Order: ${widget.orderId}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
