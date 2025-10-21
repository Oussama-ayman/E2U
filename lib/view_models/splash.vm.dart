import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';

// Removed Firebase messaging import
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_routes.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/constants/app_theme.dart';
import 'package:fuodz/requests/settings.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/services/app_permission_handler.service.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/services/custom_video_call.service.dart';
// Removed firebase.service import
import 'package:fuodz/services/location.service.dart';
import 'package:fuodz/services/websocket.service.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:fuodz/widgets/cards/language_selector.view.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'base.view_model.dart';
import 'dart:io' show Platform;

class SplashViewModel extends MyBaseViewModel {
  SplashViewModel(BuildContext context) {
    this.viewContext = context;
  }

  //
  SettingsRequest settingsRequest = SettingsRequest();

  //
  initialise() async {
    super.initialise();
    await loadAppSettings();
    if (AuthServices.authenticated()) {
      await AuthServices.getCurrentUser(force: true);
    }
  }

  //

  //
  loadAppSettings() async {
    setBusy(true);
    try {
      final appSettingsObject = await settingsRequest.appSettings();
      //START: WEBSOCKET SETTINGS
      if (appSettingsObject.body["websocket"] != null) {
        await WebsocketService().saveWebsocketDetails(
          appSettingsObject.body["websocket"],
        );
      }
      //END: WEBSOCKET SETTINGS

      Map<String, dynamic> appGenSettings = appSettingsObject.body["strings"];
      //set the app name ffrom package to the app settings
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String appName = packageInfo.appName;
      appGenSettings["app_name"] = appName;
      //app settings
      await updateAppVariables(appGenSettings);
      //colors
      await updateAppTheme(appSettingsObject.body["colors"]);
      loadNextPage();
    } catch (error) {
      setError(error);
      print("Error loading app settings ==> $error");
      //show a dialog
      AlertService.error(
        title: "An error occurred".tr(),
        text: "$error",
        confirmBtnText: "Retry".tr(),
        onConfirm: () {
          initialise();
        },
      );
    }
    setBusy(false);
  }

  //
  updateAppVariables(dynamic json) async {
    //
    await AppStrings.saveAppSettingsToLocalStorage(jsonEncode(json));
  }

  //theme change
  updateAppTheme(dynamic colorJson) async {
    //
    await AppColor.saveColorsToLocalStorage(jsonEncode(colorJson));
    //change theme
    // await AdaptiveTheme.of(viewContext).reset();
    AdaptiveTheme.of(viewContext).setTheme(
      light: AppTheme().darkTheme(),
      dark: AppTheme().darkTheme(),
      notify: true,
    );
    await AdaptiveTheme.of(viewContext).persist();
  }

  //
  loadNextPage() async {
    //
    await Utils.setJiffyLocale();
    //
    if (AuthServices.firstTimeOnApp()) {
      //choose language
      await Navigator.of(
        viewContext,
      ).push(MaterialPageRoute(builder: (ctx) => AppLanguageSelector()));
      // await showModalBottomSheet(
      //   context: viewContext,
      //   isScrollControlled: true,
      //   builder: (context) {
      //     return AppLanguageSelector();
      //   },
      // );
    }
    //
    if (AuthServices.firstTimeOnApp()) {
      Navigator.of(viewContext).pushNamedAndRemoveUntil(
        AppRoutes.welcomeRoute,
        (Route<dynamic> route) => false,
      );
    } else {
      // Initialize CustomVideoCall service if user is authenticated and UI is ready
      if (AuthServices.authenticated()) {
        try {
          // Only initialize video call service if overlay permission is granted
          if (Platform.isAndroid) {
            final hasDecision =
                await AppPermissionHandlerService.hasOverlayPermissionDecision();
            final isGranted =
                await AppPermissionHandlerService.isOverlayPermissionGranted();

            if (isGranted) {
              await CustomVideoCallService.initialize();
              print(
                'Customer Custom Video Call service initialized successfully after auth',
              );
            } else {
              print(
                'Skipping video call service initialization - overlay permission not granted',
              );
            }
          } else {
            // On iOS, no overlay permission needed
            await CustomVideoCallService.initialize();
            print(
              'Customer Custom Video Call service initialized successfully after auth',
            );
          }
        } catch (e) {
          print(
            'Error initializing Customer Custom Video Call service after auth: $e',
          );
        }
      }

      // Proactively request location permission early to improve user experience
      try {
        final permissionService = AppPermissionHandlerService();
        bool locationGranted =
            await permissionService.requestLocationPermissionSafely();

        // Also try to prepare location listener safely
        if (locationGranted) {
          await LocationService.prepareLocationListenerSafely(true);
        }

        // Check and handle overlay permission to prevent repeated requests
        if (Platform.isAndroid) {
          // Check if user has already made a decision
          final hasDecision =
              await AppPermissionHandlerService.hasOverlayPermissionDecision();
          final isGranted =
              await AppPermissionHandlerService.isOverlayPermissionGranted();

          // If no decision made and no permission granted, try to auto-grant
          if (!hasDecision && !isGranted) {
            await AppPermissionHandlerService.tryAutoGrantOverlayPermission();
          }

          // If still no permission, save that we're skipping to prevent future requests
          if (!await AppPermissionHandlerService.isOverlayPermissionGranted()) {
            print(
              'Overlay permission not available, saving skip decision to prevent future requests',
            );
            await AppPermissionHandlerService.skipOverlayPermission();
          }
        }

        print('Location permission status: $locationGranted');
      } catch (error) {
        print('Error requesting location permission in splash: $error');
      }

      Navigator.of(viewContext).pushNamedAndRemoveUntil(
        AppRoutes.homeRoute,
        (Route<dynamic> route) => false,
      );
    }

    // Firebase initial message handling removed
  }
}
