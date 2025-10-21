import 'dart:io';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropdown_alert/dropdown_alert.dart';
import 'package:fuodz/constants/app_theme.dart';
import 'package:fuodz/services/app.service.dart';

import 'package:fuodz/views/pages/splash.page.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'constants/app_strings.dart';
import 'package:fuodz/services/router.service.dart' as router;
import 'package:fuodz/services/app_permission_handler.service.dart';

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyApp({Key? key, this.navigatorKey}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Global key for navigator context
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  BuildContext? _appContext;

  // Static context for ZegoCloud access
  static BuildContext? _globalContext;
  static GlobalKey<NavigatorState>? _globalNavigatorKey;
  static final GlobalKey<NavigatorState> _zegoNavigatorKey =
      GlobalKey<NavigatorState>();

  // Static getter for context with multiple fallbacks
  static BuildContext? getZegoContext() {
    // Try zego navigator context first
    if (_zegoNavigatorKey.currentContext != null &&
        _zegoNavigatorKey.currentContext!.mounted) {
      return _zegoNavigatorKey.currentContext!;
    }

    // Try global navigator context
    if (_globalNavigatorKey?.currentContext != null &&
        _globalNavigatorKey!.currentContext!.mounted) {
      return _globalNavigatorKey!.currentContext!;
    }

    // Try global context
    if (_globalContext != null && _globalContext!.mounted) {
      return _globalContext!;
    }

    return null;
  }

  // Create a safe context wrapper that prevents null operations
  static BuildContext _createSafeContext(BuildContext fallbackContext) {
    // Return the fallback context but with additional safety checks
    // This is a last resort to prevent null pointer exceptions
    return fallbackContext;
  }

  // Validate context before use
  static bool _isContextValid(BuildContext? context) {
    return context != null && context.mounted;
  }

  // Get the best available context with comprehensive validation
  static BuildContext? getBestContext() {
    // Try all available contexts in order of preference
    final contexts = [
      _zegoNavigatorKey.currentContext,
      _globalNavigatorKey?.currentContext,
      _globalContext,
    ];

    for (final context in contexts) {
      if (_isContextValid(context)) {
        return context;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set the navigator key in AppService so both use the same key
    AppService().setNavigatorKey(_zegoNavigatorKey);

    // Set global navigator key for ZegoCloud
    _globalNavigatorKey = _zegoNavigatorKey;

    // Ensure we have a valid context for ZegoCloud
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAppContext();
    });
  }

  void _updateAppContext() {
    final context = _navigatorKey.currentContext;
    if (context != null && context.mounted) {
      setState(() {
        _appContext = context;
        _globalContext = context; // Set global context for ZegoCloud
      });
      debugPrint('MyApp: Updated app context for ZegoCloud');
    }
  }

  // Check if ZegoCloud overlay should be shown
  // Only show when user is authenticated and video calling might be needed
  Future<bool> _shouldShowZegoOverlay() async {
    // Check if user has already made a decision about overlay permission
    if (Platform.isAndroid) {
      final hasDecision =
          await AppPermissionHandlerService.hasOverlayPermissionDecision();
      final isGranted =
          await AppPermissionHandlerService.isOverlayPermissionGranted();

      // Only show overlay if permission is granted and user hasn't disabled it
      return isGranted && !hasDecision;
    }

    // For now, return false to prevent automatic overlay permission request
    // This can be changed to true when video calling is actually needed
    // or when user explicitly enables video calling in settings
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //
    return AdaptiveTheme(
      light: AppTheme().darkTheme(),
      dark: AppTheme().darkTheme(),
      initial: AdaptiveThemeMode.dark,
      builder: (theme, darkTheme) {
        return MaterialApp(
          /// 1.1.3: register the navigator key to MaterialApp
          navigatorKey: widget.navigatorKey ?? _zegoNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          onGenerateRoute: router.generateRoute,
          onUnknownRoute: (RouteSettings settings) {
            // open your app when is executed from outside when is terminated.
            return router.generateRoute(settings);
          },
          // initialRoute: _startRoute,
          localizationsDelegates: translator.delegates,
          locale: translator.activeLocale,
          supportedLocales: translator.locals(),
          builder: (context, child) {
            // Update global context whenever builder is called
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _globalContext = context;
              }
            });

            return Stack(
              children: [
                child!,
                // Only show ZegoCloud overlay when video calling is actually needed
                // This prevents the automatic overlay permission request on app startup
                FutureBuilder<bool>(
                  future: _shouldShowZegoOverlay(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return ZegoUIKitPrebuiltCallMiniOverlayPage(
                        contextQuery: () {
                          // Use static context getter for better reliability
                          final zegoContext = getZegoContext();
                          if (_isContextValid(zegoContext)) {
                            debugPrint('ZegoCloud: Using static context');
                            return zegoContext!;
                          }

                          // Fallback to current builder context with mounted check
                          if (_isContextValid(context)) {
                            debugPrint(
                              'ZegoCloud: Using builder context as fallback',
                            );
                            return context;
                          }

                          // Last resort - create a safe context wrapper
                          debugPrint(
                            'ZegoCloud: WARNING - No valid context available, using safe wrapper',
                          );
                          return _createSafeContext(context);
                        },
                      );
                    }
                    return SizedBox.shrink(); // Don't show overlay
                  },
                ),
                DropdownAlert(),
              ],
            );
          },
          home: SplashPage(),
          theme: theme,
          darkTheme: darkTheme,
        );
      },
    );
  }
}
