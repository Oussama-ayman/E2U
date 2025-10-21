import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart' as intl;
import 'package:singleton/singleton.dart';
import 'package:synchronized/synchronized.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class AppService {
  //

  /// Factory method that reuse same instance automatically
  factory AppService() => Singleton.lazy(() => AppService._());

  /// Private constructor
  AppService._() {}

  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  // Allow setting a custom navigator key (for ZegoCloud context)
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
  
  // Get the current navigator key
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
  
  // Get current context for ZegoCloud with validation
  BuildContext? get currentContext {
    try {
      final context = _navigatorKey.currentContext;
      if (context != null && context.mounted) {
        return context;
      }
      // Try to get context from the overlay state if main context is not available
      final overlay = _navigatorKey.currentState?.overlay;
      if (overlay != null && overlay.mounted) {
        return overlay.context;
      }
      return null;
    } catch (e) {
      debugPrint('AppService: Error getting current context: $e');
      return null;
    }
  }
  
  // Get a valid mounted context specifically for ZegoCloud
  BuildContext? getValidContextForZego() {
    try {
      // First try the navigator's current context
      final navContext = _navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        debugPrint('AppService: Using navigator context for ZegoCloud');
        return navContext;
      }
      
      // Then try the navigator state's overlay context
      final navState = _navigatorKey.currentState;
      if (navState != null) {
        final overlayContext = navState.overlay?.context;
        if (overlayContext != null && overlayContext.mounted) {
          debugPrint('AppService: Using overlay context for ZegoCloud');
          return overlayContext;
        }
      }
      
      debugPrint('AppService: No valid context available for ZegoCloud');
      return null;
    } catch (e) {
      debugPrint('AppService: Error getting valid context for ZegoCloud: $e');
      return null;
    }
  }
  
  BehaviorSubject<int> homePageIndex = BehaviorSubject<int>();
  BehaviorSubject<bool> refreshAssignedOrders = BehaviorSubject<bool>();
  BehaviorSubject<bool> refreshWalletBalance = BehaviorSubject<bool>();
  int? vendorId;
  Lock lock = new Lock();
  final audioPlayer = AudioPlayer();

  //
  changeHomePageIndex({int index = 2}) async {
    print("Changed Home Page");
    homePageIndex.add(index);
  }

  //
  void playNotificationSound() async {
    try {
      await audioPlayer.stop();
    } catch (error) {
      print("Error stopping audio player");
    }

    //
    await audioPlayer.setAsset("assets/audio/alert.mp3", preload: true);
    await audioPlayer.setLoopMode(LoopMode.one);
    await audioPlayer.setVolume(1.0);
    await audioPlayer.play();
  }

  void stopNotificationSound() async {
    try {
      await audioPlayer.stop();
    } catch (error) {
      print("Error stopping audio player");
    }
  }

  Future<File?> compressFile(File file, {int quality = 50}) async {
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath =
        dir.absolute.path + "/temp_" + _generateRandomString(10) + ".jpg";

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
    );

    if (kDebugMode) {
      print("unCompress file size ==> ${file.lengthSync()}");
      if (result != null) {
        print("Compress file size ==> ${result.length}");
        print("Compress successful");
      } else {
        print("compress failed");
      }
    }

    return result != null ? File(result.path) : null;
  }

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static bool isDirectionRTL(BuildContext context) {
    return intl.Bidi.isRtlLanguage(translator.activeLocale.languageCode);
  }
}
