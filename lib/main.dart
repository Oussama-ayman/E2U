import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/my_app.dart';
import 'package:fuodz/services/cart.service.dart';
import 'package:fuodz/services/firebase.service.dart';
import 'package:fuodz/services/local_storage.service.dart';
import 'package:fuodz/services/app_permission_handler.service.dart';

import 'package:fuodz/services/notification.service.dart';

import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'constants/app_languages.dart';

/// 1.1.1 define a navigator key for ZegoCloud
final navigatorKey = GlobalKey<NavigatorState>();

//ssll handshake error
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      /// 1.1.2: set navigator key to ZegoUIKitPrebuiltCallInvitationService
      ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

      // Initialize ZegoCloud properly with signaling plugin
      await ZegoUIKit().initLog();
      ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
        ZegoUIKitSignalingPlugin(),
      ]);

      // Check overlay permission BEFORE initializing ZegoCloud to prevent automatic permission requests
      if (Platform.isAndroid) {
        try {
          // Check if user has already made a decision about overlay permission
          final hasDecision =
              await AppPermissionHandlerService.hasOverlayPermissionDecision();
          final isGranted =
              await AppPermissionHandlerService.isOverlayPermissionGranted();

          // If user hasn't made a decision and permission isn't granted, try to auto-grant
          if (!hasDecision && !isGranted) {
            await AppPermissionHandlerService.tryAutoGrantOverlayPermission();
          }

          // If still no permission, skip ZegoCloud initialization to prevent permission request
          if (!await AppPermissionHandlerService.isOverlayPermissionGranted()) {
            print(
              'Overlay permission not granted, skipping ZegoCloud initialization to prevent permission request',
            );
            // Don't return here, just skip ZegoCloud initialization
          }
        } catch (e) {
          print('Error checking overlay permission: $e');
          // If there's an error, skip ZegoCloud to be safe
        }
      }

      // Initialize Firebase
      await Firebase.initializeApp();

      await translator.init(
        localeType: LocalizationDefaultType.asDefined,
        languagesList: AppLanguages.codes,
        assetsDirectory: 'assets/lang/',
      );

      //
      await LocalStorageService.getPrefs();
      await CartServices.getCartItems();
      await NotificationService.clearIrrelevantNotificationChannels();
      await NotificationService.initializeAwesomeNotification();
      await NotificationService.listenToActions();

      // Initialize Firebase messaging for video calls
      await FirebaseService().setUpFirebaseMessaging();

      //prevent ssl error
      HttpOverrides.global = MyHttpOverrides();

      // Run app!
      runApp(LocalizedApp(child: MyApp(navigatorKey: navigatorKey)));
    },
    (error, stackTrace) {
      print('Unhandled error: $error');
      print('Stack trace: $stackTrace');
      // Crashlytics error recording removed
    },
  );
}
