import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fuodz/constants/app_colors.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerName;
  final String callerPhoto;
  final String callerType;
  final String callType;
  final VoidCallback onCallDeclined;
  final VoidCallback onCallAccepted;

  const IncomingCallScreen({
    Key? key,
    required this.callId,
    required this.callerName,
    required this.callerPhoto,
    required this.callerType,
    required this.callType,
    required this.onCallDeclined,
    required this.onCallAccepted,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rippleAnimation;
  Timer? _autoDeclineTimer;

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
    
    // Auto-decline after 30 seconds
    _autoDeclineTimer = Timer(Duration(seconds: 30), () {
      if (mounted) {
        _declineCall();
      }
    });
  }

  @override
  void dispose() {
    _autoDeclineTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  // Generate UID for the receiver (customer)
  int _generateReceiverUID() {
    // For customer receiving a call, generate a customer UID
    final baseId = Random().nextInt(999999);
    return 1000000 + baseId; // Customer UIDs start with 1000000
  }

  void _acceptCall() {
    _autoDeclineTimer?.cancel();
    widget.onCallAccepted();
    Navigator.of(context).pop();
  }

  void _declineCall() {
    _autoDeclineTimer?.cancel();
    widget.onCallDeclined();
    Navigator.of(context).pop();
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
              colors: [Colors.black, Colors.grey[900]!, Colors.black],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top section with caller info
                  Expanded(
                    flex: 2,
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
                                    ? 'Incoming Video Call' 
                                    : 'Incoming Voice Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Caller avatar with pulse animation
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
                                  backgroundImage: widget.callerPhoto.isNotEmpty
                                      ? NetworkImage(widget.callerPhoto)
                                      : null,
                                  backgroundColor: AppColor.primaryColor,
                                  child: widget.callerPhoto.isEmpty
                                      ? Icon(
                                          widget.callerType == 'driver'
                                              ? FlutterIcons.truck_fea
                                              : FlutterIcons.user_fea,
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

                        // Caller name
                        Text(
                          widget.callerName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 10),

                        // Caller type
                        Text(
                          widget.callerType == 'driver' ? 'Driver' : 'Customer',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),

                        SizedBox(height: 20),

                        // Ringing animation dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDot(0),
                            SizedBox(width: 8),
                            _buildDot(1),
                            SizedBox(width: 8),
                            _buildDot(2),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom section with action buttons
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Decline button with ripple effect
                            _buildActionButton(
                              onTap: _declineCall,
                              color: Colors.red,
                              icon: FlutterIcons.phone_off_fea,
                              isAccept: false,
                            ),

                            // Accept button with ripple effect
                            _buildActionButton(
                              onTap: _acceptCall,
                              color: Colors.green,
                              icon: FlutterIcons.phone_fea,
                              isAccept: true,
                            ),
                          ],
                        ),

                        SizedBox(height: 40),

                        // Action labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              'Decline',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build enhanced action button with ripple effect
  Widget _buildActionButton({
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
    required bool isAccept,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _rippleAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect
              if (isAccept)
                Container(
                  width: 70 + (_rippleAnimation.value * 30),
                  height: 70 + (_rippleAnimation.value * 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(
                      alpha: 0.3 * (1 - _rippleAnimation.value),
                    ),
                  ),
                ),
              // Main button
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(icon, size: 30, color: Colors.white),
              ),
            ],
          );
        },
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
}
