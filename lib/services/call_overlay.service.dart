import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuodz/services/app.service.dart';

class CallOverlayService {
  static CallOverlayService? _instance;
  static CallOverlayService get instance =>
      _instance ??= CallOverlayService._();
  CallOverlayService._();

  OverlayEntry? _currentOverlay;
  Timer? _callTimer;
  bool _isCallActive = false;
  String? _currentCallId;

  // Show incoming call overlay
  void showIncomingCall({
    required String callId,
    required String callerName,
    required String callerId,
    required bool isVideoCall,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    if (_currentOverlay != null) {
      hideCurrentOverlay();
    }

    _currentCallId = callId;
    _isCallActive = true;

    _currentOverlay = OverlayEntry(
      builder:
          (context) => IncomingCallOverlay(
            callerName: callerName,
            callerId: callerId,
            isVideoCall: isVideoCall,
            onAccept: () {
              hideCurrentOverlay();
              onAccept();
              _showActiveCallOverlay(
                callId: callId,
                participantName: callerName,
                isVideoCall: isVideoCall,
                isIncoming: true,
              );
            },
            onDecline: () {
              hideCurrentOverlay();
              onDecline();
              _isCallActive = false;
              _currentCallId = null;
            },
          ),
    );

    final context = AppService().navigatorKey.currentContext;
    if (context != null && context.mounted) {
      final overlay = Overlay.of(context);
      overlay.insert(_currentOverlay!);
    }

    // Auto-decline after 30 seconds
    _callTimer = Timer(Duration(seconds: 30), () {
      if (_currentOverlay != null) {
        hideCurrentOverlay();
        onDecline();
        _isCallActive = false;
        _currentCallId = null;
      }
    });
  }

  // Show outgoing call overlay
  void showOutgoingCall({
    required String callId,
    required String receiverName,
    required String receiverId,
    required bool isVideoCall,
    required VoidCallback onCancel,
  }) {
    if (_currentOverlay != null) {
      hideCurrentOverlay();
    }

    _currentCallId = callId;
    _isCallActive = true;

    _currentOverlay = OverlayEntry(
      builder:
          (context) => OutgoingCallOverlay(
            receiverName: receiverName,
            receiverId: receiverId,
            isVideoCall: isVideoCall,
            onCancel: () {
              hideCurrentOverlay();
              onCancel();
              _isCallActive = false;
              _currentCallId = null;
            },
            onConnected: () {
              hideCurrentOverlay();
              _showActiveCallOverlay(
                callId: callId,
                participantName: receiverName,
                isVideoCall: isVideoCall,
                isIncoming: false,
              );
            },
          ),
    );

    final context = AppService().navigatorKey.currentContext;
    if (context != null && context.mounted) {
      final overlay = Overlay.of(context);
      overlay.insert(_currentOverlay!);
    }
  }

  // Show active call overlay
  void _showActiveCallOverlay({
    required String callId,
    required String participantName,
    required bool isVideoCall,
    required bool isIncoming,
  }) {
    _currentOverlay = OverlayEntry(
      builder:
          (context) => ActiveCallOverlay(
            callId: callId,
            participantName: participantName,
            isVideoCall: isVideoCall,
            isIncoming: isIncoming,
            onEndCall: () {
              hideCurrentOverlay();
              _isCallActive = false;
              _currentCallId = null;
            },
          ),
    );

    final context = AppService().navigatorKey.currentContext;
    if (context != null && context.mounted) {
      final overlay = Overlay.of(context);
      overlay.insert(_currentOverlay!);
    }
  }

  // Hide current overlay
  void hideCurrentOverlay() {
    _callTimer?.cancel();
    _callTimer = null;

    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
  }

  // Check if call is active
  bool get isCallActive => _isCallActive;
  String? get currentCallId => _currentCallId;

  // End current call
  void endCurrentCall() {
    if (_isCallActive && _currentCallId != null) {
      hideCurrentOverlay();
      _isCallActive = false;
      _currentCallId = null;
    }
  }
}

// Incoming Call Overlay Widget
class IncomingCallOverlay extends StatefulWidget {
  final String callerName;
  final String callerId;
  final bool isVideoCall;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallOverlay({
    Key? key,
    required this.callerName,
    required this.callerId,
    required this.isVideoCall,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Play ringtone
    _playRingtone();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopRingtone();
    super.dispose();
  }

  void _playRingtone() {
    // Play system ringtone or custom sound
    SystemSound.play(SystemSoundType.click);
  }

  void _stopRingtone() {
    // Stop ringtone
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Caller info
            Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Text(
                  widget.callerName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.isVideoCall ? 'Incoming video call' : 'Incoming call',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),

            SizedBox(height: 80),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline button
                GestureDetector(
                  onTap: widget.onDecline,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call_end, color: Colors.white, size: 30),
                  ),
                ),

                // Accept button
                GestureDetector(
                  onTap: widget.onAccept,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isVideoCall ? Icons.videocam : Icons.call,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Outgoing Call Overlay Widget
class OutgoingCallOverlay extends StatefulWidget {
  final String receiverName;
  final String receiverId;
  final bool isVideoCall;
  final VoidCallback onCancel;
  final VoidCallback onConnected;

  const OutgoingCallOverlay({
    Key? key,
    required this.receiverName,
    required this.receiverId,
    required this.isVideoCall,
    required this.onCancel,
    required this.onConnected,
  }) : super(key: key);

  @override
  State<OutgoingCallOverlay> createState() => _OutgoingCallOverlayState();
}

class _OutgoingCallOverlayState extends State<OutgoingCallOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Simulate connection after 3 seconds (in real implementation, this would be triggered by ZegoCloud)
    _connectionTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        widget.onConnected();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _connectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Receiver info
            Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Text(
                  widget.receiverName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.isVideoCall ? 'Video calling...' : 'Calling...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),

            SizedBox(height: 80),

            // Cancel button
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.call_end, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Active Call Overlay Widget
class ActiveCallOverlay extends StatefulWidget {
  final String callId;
  final String participantName;
  final bool isVideoCall;
  final bool isIncoming;
  final VoidCallback onEndCall;

  const ActiveCallOverlay({
    Key? key,
    required this.callId,
    required this.participantName,
    required this.isVideoCall,
    required this.isIncoming,
    required this.onEndCall,
  }) : super(key: key);

  @override
  State<ActiveCallOverlay> createState() => _ActiveCallOverlayState();
}

class _ActiveCallOverlayState extends State<ActiveCallOverlay> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = true;
  Timer? _callDurationTimer;
  int _callDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startCallDurationTimer();
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    super.dispose();
  }

  void _startCallDurationTimer() {
    _callDurationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with participant info
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    widget.participantName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatDuration(_callDurationSeconds),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Video area (placeholder)
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    widget.isVideoCall && _isVideoOn
                        ? Center(
                          child: Text(
                            'Video Feed\n(ZegoCloud Integration)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
              ),
            ),

            // Control buttons
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isMuted ? Colors.red : Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // End call button
                  GestureDetector(
                    onTap: widget.onEndCall,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),

                  // Speaker/Video toggle button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (widget.isVideoCall) {
                          _isVideoOn = !_isVideoOn;
                        } else {
                          _isSpeakerOn = !_isSpeakerOn;
                        }
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            widget.isVideoCall
                                ? (_isVideoOn ? Colors.grey[700] : Colors.red)
                                : (_isSpeakerOn
                                    ? Colors.blue
                                    : Colors.grey[700]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isVideoCall
                            ? (_isVideoOn ? Icons.videocam : Icons.videocam_off)
                            : (_isSpeakerOn
                                ? Icons.volume_up
                                : Icons.volume_down),
                        color: Colors.white,
                        size: 24,
                      ),
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
}
