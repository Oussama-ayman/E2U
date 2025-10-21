import 'package:flutter/material.dart';
import 'package:fuodz/services/custom_video_call.service.dart';
import 'package:fuodz/constants/app_colors.dart';

class ZegoVoiceCallButton extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final VoidCallback? onPressed;

  const ZegoVoiceCallButton({
    Key? key,
    required this.targetUserId,
    required this.targetUserName,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        if (onPressed != null) {
          onPressed!();
        } else {
          try {
            // Ensure the service is initialized
            if (!CustomVideoCallService.isInitialized) {
              await CustomVideoCallService.initialize();
            }

            // Make the voice call (service will handle showing outgoing screen)
            await CustomVideoCallService.makeVideoCall(
              receiverId: targetUserId,
              receiverName: targetUserName,
              callType:
                  'voice', // This parameter is used by makeVideoCall to determine call type
            );
          } catch (e) {
            debugPrint(
              'ZegoVoiceCallButton: Failed to initiate voice call: $e',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to initiate voice call: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
      icon: Icon(Icons.phone),
      label: Text('Voice Call'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.accentColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ), // Reduced padding to prevent overflow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size(0, 36), // Set minimum height
      ),
    );
  }
}
