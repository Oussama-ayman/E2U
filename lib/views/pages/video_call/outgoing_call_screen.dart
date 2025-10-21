import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String callId;
  final String receiverName;
  final String receiverPhoto;
  final String callType;
  final VoidCallback onCallEnded;

  const OutgoingCallScreen({
    Key? key,
    required this.callId,
    required this.receiverName,
    required this.receiverPhoto,
    required this.callType,
    required this.onCallEnded,
  }) : super(key: key);

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rippleAnimation;
  
  String _callStatus = 'Calling...';
  bool _isMuted = false;
  bool _isSpeakerEnabled = false;
  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for avatar
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Slide animation for screen entrance
    _slideController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Ripple animation for buttons
    _rippleController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleController.repeat();

    // Start entrance animation
    _slideController.forward();
    
    // Listen for call status changes
    _listenForCallStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _rippleController.dispose();
    _callStatusSubscription?.cancel();
    super.dispose();
  }

  void _listenForCallStatus() {
    _callStatusSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String;
        
        setState(() {
          switch (status) {
            case 'calling':
              _callStatus = 'Calling...';
              break;
            case 'ringing':
              _callStatus = 'Ringing...';
              break;
            case 'accepted':
              _callStatus = 'Connected';
              // Navigate to video call screen
              _navigateToVideoCall(data);
              break;
            case 'declined':
              _callStatus = 'Call declined';
              _endCallAfterDelay();
              break;
            case 'ended':
              _callStatus = 'Call ended';
              _endCallAfterDelay();
              break;
            case 'timeout':
              _callStatus = 'No answer';
              _endCallAfterDelay();
              break;
          }
        });
      }
    });
    
    // Auto-timeout after 30 seconds
    Timer(Duration(seconds: 30), () {
      if (mounted && _callStatus == 'Calling...') {
        _timeoutCall();
      }
    });
  }

  void _navigateToVideoCall(Map<String, dynamic> callData) {
    // The ZegoCloud call UI should automatically appear when call is accepted
    // since the service is already initialized and handling the call
    debugPrint('Call accepted, ZegoCloud UI should take over');
    
    // Close this screen as the ZegoCloud UI will take over
    Navigator.of(context).pop();
    widget.onCallEnded();
  }

  void _endCallAfterDelay() {
    Timer(Duration(seconds: 2), () {
      if (mounted) {
        _endCall();
      }
    });
  }

  void _timeoutCall() async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({
        'status': 'timeout',
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error timing out call: $e');
    }
  }

  void _endCall() {
    widget.onCallEnded();
    Navigator.of(context).pop();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // TODO: Implement actual mute functionality
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    // TODO: Implement actual speaker functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black,
                AppColor.primaryColor.withOpacity(0.3),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top section with receiver info
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Call type indicator
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.callType == 'video' 
                                  ? Icons.videocam 
                                  : Icons.phone,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.callType == 'video' 
                                  ? 'Video Call' 
                                  : 'Voice Call',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Receiver avatar with pulse animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColor.primaryColor.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 75,
                                backgroundImage: widget.receiverPhoto.isNotEmpty
                                    ? NetworkImage(widget.receiverPhoto)
                                    : null,
                                backgroundColor: AppColor.primaryColor,
                                child: widget.receiverPhoto.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 30),

                      // Receiver name
                      Text(
                        widget.receiverName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 15),

                      // Call status
                      Text(
                        _callStatus,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      // Status dots animation
                      if (_callStatus.contains('...'))
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDot(0),
                              SizedBox(width: 8),
                              _buildDot(1),
                              SizedBox(width: 8),
                              _buildDot(2),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom section with controls
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Mute button
                          _buildControlButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            isActive: !_isMuted,
                            onTap: _toggleMute,
                          ),

                          // End call button with ripple effect
                          AnimatedBuilder(
                            animation: _rippleAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Ripple effect
                                  Container(
                                    width: 80 + (_rippleAnimation.value * 40),
                                    height: 80 + (_rippleAnimation.value * 40),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.withOpacity(
                                        0.4 * (1 - _rippleAnimation.value),
                                      ),
                                    ),
                                  ),
                                  // Main button
                                  GestureDetector(
                                    onTap: _endCall,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.5),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.call_end,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          // Speaker button
                          _buildControlButton(
                            icon: _isSpeakerEnabled 
                                ? Icons.volume_up 
                                : Icons.volume_down,
                            isActive: _isSpeakerEnabled,
                            onTap: _toggleSpeaker,
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Control labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            _isMuted ? 'Unmute' : 'Mute',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'End Call',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _isSpeakerEnabled ? 'Speaker On' : 'Speaker Off',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double opacity = 0.3;
        if ((_pulseController.value * 3 + index) % 3 < 1) {
          opacity = 1.0;
        }
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive 
              ? Colors.white.withOpacity(0.2) 
              : Colors.grey.withOpacity(0.3),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
