# Agora Video Call Integration

This document describes the Agora.io video call integration that has been added to the app.

## Features

- **2-minute call duration** with visible countdown timer
- **One-time pause option** for 60 seconds during the call
- **Camera controls** - enable/disable camera
- **Microphone controls** - enable/disable microphone
- **Camera switching** - front/back camera toggle
- **Automatic call termination** when time expires
- **Permission handling** for camera and microphone access

## Configuration

### Agora Credentials
The following Agora.io credentials are configured in the app:

- **App ID**: `fce29dd9bc6e4d7aafc65350d1bf98e2`
- **Primary Certificate**: `485c93c4848842fd92b730524a6800e7`

### Files Added/Modified

#### New Files:
1. `lib/services/agora_video_call.service.dart` - Core video call service
2. `lib/widgets/video_call/video_call_widget.dart` - Video call UI widget
3. `lib/widgets/buttons/video_call.button.dart` - Video call button components
4. `lib/views/pages/test/video_call_test.page.dart` - Test page for video calls

#### Modified Files:
1. `pubspec.yaml` - Added `agora_rtc_engine: ^6.3.2` dependency
2. `lib/views/pages/order/widgets/order_details_vendor_info.view.dart` - Added video call button
3. `lib/views/pages/order/widgets/order_details_driver_info.view.dart` - Added video call button
4. `android/app/src/main/AndroidManifest.xml` - Added Android permissions
5. `ios/Runner/Info.plist` - Updated iOS permission descriptions

## Usage

### In Order Details
Video call buttons are automatically added to:
- **Driver Info Section** - Call the assigned driver

### Button Components
Two button components are available:

1. **VideoCallButton** - Full button with text and icon
2. **VideoCallIconButton** - Compact icon-only button

### Example Usage
```dart
VideoCallButton(
  orderId: order.code,
  driverId: driver.id.toString(),
  onCallStarted: () {
    // Optional callback when call starts
  },
  onCallEnded: () {
    // Optional callback when call ends
  },
)
```

## Permissions

### Android Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS Permissions (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera for profile photo update and video calls.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need permission to make audio and video calls</string>
```

## Video Call Flow

1. **User taps video call button**
2. **Permission check** - Camera and microphone permissions are requested
3. **Channel creation** - Unique channel name generated based on order ID
4. **Call initiation** - User joins Agora channel
5. **Timer starts** - 2-minute countdown begins
6. **Call controls** - Camera, microphone, and pause controls available
7. **Call termination** - Automatic or manual call end

## Call Controls

### During Call:
- **Timer Display** - Shows remaining time in MM:SS format
- **Pause Button** - One-time use, pauses timer for 60 seconds
- **Camera Toggle** - Enable/disable video feed
- **Microphone Toggle** - Enable/disable audio
- **Camera Switch** - Switch between front and back camera
- **End Call** - Manually terminate the call

### Video Layout:
- **Remote video** - Full screen view of the other participant
- **Local video** - Small overlay window showing your own video
- **Controls overlay** - Tap screen to show/hide controls

## Testing

A test page is available at `lib/views/pages/test/video_call_test.page.dart` to test the video call functionality without needing a full order context.

## Production Considerations

1. **Token Generation** - Currently using empty tokens for testing. In production, implement server-side token generation using Agora's token service.

2. **Channel Management** - Consider implementing proper channel cleanup and management for production use.

3. **Error Handling** - Add comprehensive error handling for network issues, permission denials, and Agora service failures.

4. **Analytics** - Add call analytics and logging for monitoring call quality and usage.

5. **Scalability** - Consider implementing call queuing and load balancing for high-volume usage.

## Troubleshooting

### Common Issues:
1. **Permission Denied** - Ensure camera and microphone permissions are granted
2. **No Video/Audio** - Check device camera and microphone functionality
3. **Connection Issues** - Verify internet connectivity and Agora service status
4. **Build Errors** - Ensure all dependencies are properly installed with `flutter pub get`

### Debug Mode:
The Agora service includes debug logging that can be enabled by setting `enableLogging: true` in the PusherConnector configuration.
