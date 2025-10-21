import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:awesome_notifications/awesome_notifications.dart'
    hide NotificationModel;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/services/firebase_token.service.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/constants/app_routes.dart';
import 'package:fuodz/models/notification.dart';
import 'package:fuodz/models/order.dart';
import 'package:fuodz/models/product.dart';
import 'package:fuodz/models/service.dart';
import 'package:fuodz/models/vendor.dart';
import 'package:fuodz/requests/order.request.dart';
import 'package:fuodz/requests/product.request.dart';
import 'package:fuodz/requests/service.request.dart';
import 'package:fuodz/requests/vendor.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/services/notification.service.dart';
import 'package:fuodz/services/toast.service.dart';
import 'package:fuodz/views/pages/home.page.dart';
import 'package:fuodz/views/pages/service/service_details.page.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:singleton/singleton.dart';


// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.data}');
  // Handle background video call notifications
  if (message.data.containsKey('is_video_call') &&
      message.data['is_video_call'] == '1') {
    print('Background video call notification received');
    // The notification will be handled when the app comes to foreground
  }
}

class FirebaseService {
  //
  /// Factory method that reuse same instance automatically
  factory FirebaseService() => Singleton.lazy(() => FirebaseService._());

  /// Private constructor
  FirebaseService._() {}

  //
  NotificationModel? notificationModel;
  dynamic firebaseMessaging; // Replaced FirebaseMessaging
  Map? notificationPayloadData;

  /// Initialize Firebase Messaging safely
  // Firebase initialization removed

  setUpFirebaseMessaging() async {
    try {
      print("Setting up Firebase messaging for video calls");

      // Initialize Firebase Messaging
      firebaseMessaging = FirebaseMessaging.instance;

      // Request permission for notifications
      NotificationSettings settings = await firebaseMessaging!
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');

        // Get FCM token for backend registration
        String? token = await firebaseMessaging!.getToken();
        if (token != null) {
          print("FCM Token: $token");
          // Send token to backend for customer topic subscription
          await FirebaseTokenService().syncDeviceTokenWithServer(token);

          // Subscribe to customer topic for video calls
          if (AuthServices.authenticated()) {
            final currentUser = AuthServices.currentUser;
            if (currentUser != null) {
              final customerTopic = 'customer_${currentUser.id}';
              await firebaseMessaging!.subscribeToTopic(customerTopic);
              print('Subscribed to customer topic: $customerTopic');
            }
          }
        }

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Received foreground message: ${message.data}');
          handleNotification(message);
        });

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        // Handle notification taps
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('Notification tapped: ${message.data}');
          handleNotification(message);
        });
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print("Firebase messaging setup failed: $e");
    }
  }

  // Handle notifications
  void handleNotification(RemoteMessage message) {
    final data = message.data;

    // Check if this is a video call notification
    if (data.containsKey('is_video_call') && data['is_video_call'] == '1') {
      print("Processing video call notification: $data");
      _handleVideoCallNotification(data);
      return;
    }

    // Handle other notifications
    print("Processing general notification: $data");
    saveNewNotification(message);
  }

  // Handle video call notifications
  void _handleVideoCallNotification(Map<String, dynamic> data) {
    try {
      final callStatus = data['call_status'] ?? 'incoming';
      final sessionId = data['session_id'] ?? '';
      final callerName = data['caller_name'] ?? 'Unknown';
      final callerType = data['caller_type'] ?? 'driver';
      final agoraChannelName = data['agora_channel_name'] ?? '';
      final callerUID =
          int.tryParse(data['caller_uid']?.toString() ?? '0') ?? 0;

      print(
        'FirebaseService: Handling video call notification - Status: $callStatus, Session: $sessionId',
      );

      switch (callStatus) {
        case 'incoming':
          _showIncomingCallNotification(
            sessionId: sessionId,
            callerName: callerName,
            callerType: callerType,
            agoraChannelName: agoraChannelName,
            callerUID: callerUID,
          );
          break;
        case 'accepted':
          print('FirebaseService: Call was accepted by the other party');
          // The enhanced video call service will handle this through polling
          break;
        case 'rejected':
          print('FirebaseService: Call was rejected by the other party');
          // The enhanced video call service will handle this through polling
          break;
        case 'ended':
          print('FirebaseService: Call was ended');
          // The enhanced video call service will handle this through polling
          break;
        default:
          print('FirebaseService: Unknown call status: $callStatus');
      }
    } catch (e) {
      print('FirebaseService: Error handling video call notification: $e');
    }
  }

  // Show incoming call notification
  void _showIncomingCallNotification({
    required String sessionId,
    required String callerName,
    required String callerType,
    required String agoraChannelName,
    required int callerUID,
  }) {
    final context = AppService().navigatorKey.currentContext;
    if (context != null) {
      // Play ringtone
      AppService().playNotificationSound();

      print('FirebaseService: Video call notification received, ZegoCloud will handle the UI automatically');
      // ZegoCloud handles incoming calls automatically through the custom video call service
      // No need to manually show screens as ZegoCloud manages the call flow
    }
  }

  //write to notification list
  saveNewNotification(dynamic message, {String? title, String? body}) {
    //
    notificationPayloadData = message != null ? message.data : null;
    if (message?.notification == null &&
        message?.data["title"] == null &&
        title == null) {
      return;
    }
    //Saving the notification
    notificationModel = NotificationModel();
    notificationModel!.title =
        message?.notification?.title ?? title ?? message?.data["title"] ?? "";
    notificationModel!.body =
        message?.notification?.body ?? body ?? message?.data["body"] ?? "";
    //

    final imageUrl =
        message?.data["image"] ??
        (Platform.isAndroid
            ? message?.notification?.android?.imageUrl
            : message?.notification?.apple?.imageUrl);
    notificationModel!.image = imageUrl;

    //
    notificationModel!.timeStamp = DateTime.now().millisecondsSinceEpoch;

    //add to database/shared pref
    NotificationService.addNotification(notificationModel!);
  }

  //
  showNotification(dynamic message) async {
    if (message.notification == null && message.data["title"] == null) {
      return;
    }

    //
    notificationPayloadData = message.data;

    //
    try {
      //
      String? imageUrl;

      try {
        imageUrl =
            message.data["image"] ??
            (Platform.isAndroid
                ? message.notification?.android?.imageUrl
                : message.notification?.apple?.imageUrl);
      } catch (error) {
        print("error getting notification image");
      }

      //
      if (imageUrl != null) {
        //
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: Random().nextInt(20),
            channelKey:
                NotificationService.appNotificationChannel().channelKey!,
            title: message.data["title"] ?? message.notification?.title,
            body: message.data["body"] ?? message.notification?.body,
            bigPicture: imageUrl,
            icon: "resource://drawable/notification_icon",
            notificationLayout: NotificationLayout.BigPicture,
            payload: Map<String, String>.from(message.data),
          ),
        );
      } else {
        //
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: Random().nextInt(20),
            channelKey:
                NotificationService.appNotificationChannel().channelKey!,
            title: message.data["title"] ?? message.notification?.title,
            body: message.data["body"] ?? message.notification?.body,
            icon: "resource://drawable/notification_icon",
            notificationLayout: NotificationLayout.Default,
            payload: Map<String, String>.from(message.data),
          ),
        );
      }

      ///
    } catch (error) {
      print("Notification Show error ===> ${error}");
    }
  }

  //handle on notification selected
  Future selectNotification(String? payload) async {
    if (payload == null) {
      return;
    }
    try {
      log("NotificationPaylod ==> ${jsonEncode(notificationPayloadData)}");
      //
      if (notificationPayloadData != null && notificationPayloadData is Map) {
        //

        //
        final isChat = notificationPayloadData!.containsKey("is_chat");
        final isOrder =
            notificationPayloadData!.containsKey("is_order") &&
            (notificationPayloadData?["is_order"].toString() == "1" ||
                (notificationPayloadData?["is_order"] is bool &&
                    notificationPayloadData?["is_order"]));

        ///
        final hasProduct = notificationPayloadData!.containsKey("product");
        final hasVendor = notificationPayloadData!.containsKey("vendor");
        final hasService = notificationPayloadData!.containsKey("service");
        //
        if (isChat) {
          // Chat functionality disabled - using new chat system
          print("Chat notification received but Firebase chat is disabled");
        }
        //order
        else if (isOrder) {
          //
          try {
            //fetch order from api
            int orderId = int.parse("${notificationPayloadData!['order_id']}");
            Order order = await OrderRequest().getOrderDetails(id: orderId);
            //
            Navigator.of(
              AppService().navigatorKey.currentContext!,
            ).pushNamed(AppRoutes.orderDetailsRoute, arguments: order);
          } catch (error) {
            //navigate to orders page
            await Navigator.of(
              AppService().navigatorKey.currentContext!,
            ).push(MaterialPageRoute(builder: (_) => HomePage()));
            //then switch to orders tab
            AppService().changeHomePageIndex();
          }
        }
        //vendor type of notification
        else if (hasVendor) {
          Vendor? vendor;
          final vendorData = notificationPayloadData?['vendor'];
          try {
            vendor = Vendor.fromJson(jsonDecode(vendorData));
          } catch (error) {
            final vendorJsonData = jsonDecode(vendorData);
            final vendorId = vendorJsonData["id"];
            if (vendorId != null) {
              AlertService.loading();
              try {
                vendor = await VendorRequest().vendorDetails(vendorId);
                AlertService.loading();
              } catch (error) {
                AlertService.loading();
              }
            }
          }
          try {
            Navigator.of(
              AppService().navigatorKey.currentContext!,
            ).pushNamed(AppRoutes.shopDetails, arguments: vendor);
          } catch (error) {
            ToastService.toastError("Unable to fetch vendor details".tr());
            Navigator.of(
              AppService().navigatorKey.currentContext!,
            ).pushNamed(AppRoutes.homeRoute);
          }

          //
        }
        //product type of notification
        else if (hasProduct) {
          //
          Product? product;
          final productData = notificationPayloadData?['product'];
          try {
            product = Product.fromJson(jsonDecode(productData));
          } catch (error) {
            final productJsonData = jsonDecode(productData);
            final productId = productJsonData["id"];
            if (productId != null) {
              AlertService.loading();
              try {
                product = await ProductRequest().productDetails(productId);
                AlertService.loading();
              } catch (error) {
                AlertService.loading();
              }
            }
          }
          try {
            Navigator.of(
              AppService().navigatorKey.currentContext!,
            ).pushNamed(AppRoutes.product, arguments: product);
          } catch (error) {
            ToastService.toastError("Unable to fetch product details".tr());
            Navigator.of(
              AppService().navigatorKey.currentContext!,
            ).pushNamed(AppRoutes.homeRoute);
          }
        }
        //service type of notification
        else if (hasService) {
          Service? service;
          final serviceData = notificationPayloadData?['service'];
          try {
            service = Service.fromJson(jsonDecode(serviceData));
            //
          } catch (error) {
            final serviceJsonData = jsonDecode(serviceData);
            final serviceId = serviceJsonData["id"];
            if (serviceId != null) {
              AlertService.loading();
              try {
                service = await ServiceRequest().serviceDetails(serviceId);
                AlertService.loading();
              } catch (error) {
                AlertService.loading();
              }
            }
          }
          try {
            Navigator.of(AppService().navigatorKey.currentContext!).push(
              MaterialPageRoute(builder: (_) => ServiceDetailsPage(service!)),
            );
          } catch (error) {
            ToastService.toastError("Unable to fetch service details".tr());
            Navigator.of(
              AppService().navigatorKey.currentContext!,
            ).pushNamed(AppRoutes.homeRoute);
          }
        }
        //regular notifications
        else {
          Navigator.of(AppService().navigatorKey.currentContext!).pushNamed(
            AppRoutes.notificationDetailsRoute,
            arguments: notificationModel,
          );
        }
      } else {
        Navigator.of(AppService().navigatorKey.currentContext!).pushNamed(
          AppRoutes.notificationDetailsRoute,
          arguments: notificationModel,
        );
      }
    } catch (error) {
      print("Error opening Notification ==> $error");
    }
  }

  //refresh orders list if the notification is about assigned order
  void refreshOrdersList(dynamic message) async {
    if (message.data["is_order"] != null) {
      await Future.delayed(Duration(seconds: 3));
      AppService().refreshAssignedOrders.add(true);
    }
  }
}
