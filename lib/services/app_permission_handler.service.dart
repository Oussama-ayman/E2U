import 'package:flutter/material.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/widgets/bottomsheets/location_permission.bottomsheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPermissionHandlerService {
  // Keys for SharedPreferences
  static const String _overlayPermissionSkippedKey =
      'overlay_permission_skipped';
  static const String _overlayPermissionGrantedKey =
      'overlay_permission_granted';
  static const String _overlayPermissionPermanentlyDisabledKey =
      'overlay_permission_permanently_disabled';
  static const String _overlayPermissionRequestedKey =
      'overlay_permission_requested';

  //MANAGE LOCATION PERMISSION
  static Future<bool> isLocationPermissionGranted() async {
    var status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  // Request location permission with better error handling
  Future<bool> requestLocationPermissionSafely() async {
    try {
      var status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        return true;
      }

      // If denied but not permanently, request permission
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
        if (status.isGranted) {
          return true;
        }
      }

      // If permanently denied, show dialog
      if (status.isPermanentlyDenied) {
        return await _showLocationPermissionDialog();
      }

      return false;
    } catch (error) {
      print("Error requesting location permission: $error");
      return false;
    }
  }

  // Show location permission dialog
  Future<bool> _showLocationPermissionDialog() async {
    var status = await Permission.locationWhenInUse.status;
    //check if location permission is not granted
    if (status.isDenied || status.isPermanentlyDenied) {
      final context = AppService().navigatorKey.currentContext;
      if (context == null) {
        print(
          "Warning: No valid context available for location permission dialog",
        );
        return false;
      }

      return await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return LocationPermissionDialog(
                onResult: (result) async {
                  Navigator.of(context).pop(result);
                },
              );
            },
          ) ??
          false;
    }
    return false;
  }

  // Check if we should show location permission request
  Future<bool> shouldRequestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    return status.isDenied && !status.isPermanentlyDenied;
  }

  // OVERLAY PERMISSION HANDLING

  // Check if overlay permission is granted
  static Future<bool> isOverlayPermissionGranted() async {
    // First check our saved state
    final prefs = await SharedPreferences.getInstance();
    final permissionPreviouslyGranted =
        prefs.getBool(_overlayPermissionGrantedKey) ?? false;

    // If we previously granted it, check if it's still granted
    if (permissionPreviouslyGranted) {
      var status = await Permission.systemAlertWindow.status;
      // If permission was revoked, update our records
      if (!status.isGranted) {
        await prefs.setBool(_overlayPermissionGrantedKey, false);
        return false;
      }
      return true;
    }

    // If not previously granted, check current status
    var status = await Permission.systemAlertWindow.status;
    return status.isGranted;
  }

  // Check if user has already made a decision about overlay permission
  static Future<bool> hasOverlayPermissionDecision() async {
    final prefs = await SharedPreferences.getInstance();
    final overlaySkipped = prefs.getBool(_overlayPermissionSkippedKey) ?? false;
    final overlayGranted = prefs.getBool(_overlayPermissionGrantedKey) ?? false;
    final overlayPermanentlyDisabled =
        prefs.getBool(_overlayPermissionPermanentlyDisabledKey) ?? false;

    return overlaySkipped || overlayGranted || overlayPermanentlyDisabled;
  }

  // Try to auto-grant overlay permission
  static Future<bool> tryAutoGrantOverlayPermission() async {
    try {
      // Check if user has already made a decision
      if (await hasOverlayPermissionDecision()) {
        return false; // Don't request if user has already decided
      }

      // Check if we've already requested permission before
      final prefs = await SharedPreferences.getInstance();
      final permissionPreviouslyRequested =
          prefs.getBool(_overlayPermissionRequestedKey) ?? false;

      // If we've already requested it, don't request again
      if (permissionPreviouslyRequested) {
        return false;
      }

      // Try to request permission silently
      final status = await Permission.systemAlertWindow.request();

      // Save that we've requested the permission
      await prefs.setBool(_overlayPermissionRequestedKey, true);

      if (status.isGranted) {
        await prefs.setBool(_overlayPermissionGrantedKey, true);
        return true;
      } else if (status.isDenied) {
        // Save that user denied the permission
        await prefs.setBool(_overlayPermissionSkippedKey, true);
      } else if (status.isPermanentlyDenied) {
        // Save that user permanently denied the permission
        await prefs.setBool(_overlayPermissionPermanentlyDisabledKey, true);
      }

      return false;
    } catch (e) {
      print('Auto-grant overlay permission failed: $e');
      return false;
    }
  }

  // Skip overlay permission
  static Future<void> skipOverlayPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_overlayPermissionSkippedKey, true);
    // Also mark that we've made a decision to prevent future requests
    await prefs.setBool(_overlayPermissionRequestedKey, true);
  }

  // Permanently disable overlay permission requests
  static Future<void> permanentlyDisableOverlayPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_overlayPermissionSkippedKey, true);
    await prefs.setBool(_overlayPermissionPermanentlyDisabledKey, true);
    // Also mark that we've made a decision to prevent future requests
    await prefs.setBool(_overlayPermissionRequestedKey, true);
  }

  // Grant overlay permission
  static Future<void> grantOverlayPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_overlayPermissionGrantedKey, true);
    // Also mark that we've made a decision to prevent future requests
    await prefs.setBool(_overlayPermissionRequestedKey, true);
  }

  // Reset overlay permission state (useful for testing or when user wants to reset)
  static Future<void> resetOverlayPermissionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_overlayPermissionSkippedKey);
    await prefs.remove(_overlayPermissionGrantedKey);
    await prefs.remove(_overlayPermissionPermanentlyDisabledKey);
    await prefs.remove(_overlayPermissionRequestedKey);
  }
}
