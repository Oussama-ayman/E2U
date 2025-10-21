// Removed firestore_chat import
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_routes.dart';
import 'package:fuodz/constants/app_strings.dart';
// Removed app_ui_settings import
import 'package:fuodz/extensions/dynamic.dart';
import 'package:fuodz/models/api_response.dart';
import 'package:fuodz/models/order.dart';
import 'package:fuodz/models/payment_method.dart';
import 'package:fuodz/requests/order.request.dart';
import 'package:fuodz/services/app.service.dart';
// Removed chat.service import
import 'package:fuodz/services/order_details_websocket.service.dart';
import 'package:fuodz/services/custom_video_call.service.dart';
import 'package:fuodz/services/call_overlay.service.dart';
import 'package:fuodz/view_models/checkout_base.vm.dart';
import 'package:fuodz/views/pages/checkout/widgets/payment_methods.view.dart';
import 'package:fuodz/widgets/bottomsheets/driver_rating.bottomsheet.dart';
import 'package:fuodz/widgets/bottomsheets/order_cancellation.bottomsheet.dart';
import 'package:fuodz/widgets/bottomsheets/vendor_rating.bottomsheet.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fuodz/extensions/context.dart';

class OrderDetailsViewModel extends CheckoutBaseViewModel {
  //
  Order order;
  OrderRequest orderRequest = OrderRequest();

  //
  OrderDetailsViewModel(BuildContext context, this.order) {
    this.viewContext = context;
  }

  initialise() async {
    fetchPaymentOptions();
    await fetchOrderDetails();
    //handle order update through websocket
    handleWebsocketOrderEvent();
  }

  @override
  void dispose() {
    if (AppStrings.useWebsocketAssignment) {
      OrderDetailsWebsocketService().disconnect();
    }
    super.dispose();
  }

  void callVendor() {
    // Shop calling disabled - removed from UI
    print("Shop calling disabled");
  }

  void callDriver() async {
    try {
      // Use CustomVideoCallService for video calling
      if (order.driver != null) {
        // Ensure the service is initialized
        if (!CustomVideoCallService.isInitialized) {
          await CustomVideoCallService.initialize();
        }

        await CustomVideoCallService.makeVideoCall(
          receiverId: order.driver!.id.toString(),
          receiverName: order.driver!.name,
          callType: 'video',
        );
      } else {
        throw Exception('Driver not available');
      }
    } catch (e) {
      debugPrint('OrderDetailsViewModel: Video call failed: $e');
      // Fallback to phone call
      launchUrlString("tel:${order.driver?.phone}");
    }
  }

  // Custom overlay video call method
  void callDriverWithOverlay() async {
    try {
      debugPrint(
        'OrderDetailsViewModel: Starting custom overlay video call to driver',
      );

      if (order.driver == null || order.driver!.id <= 0) {
        debugPrint('OrderDetailsViewModel: Driver ID is invalid');
        return;
      }

      final callId = DateTime.now().millisecondsSinceEpoch.toString();

      // Show outgoing call overlay
      CallOverlayService.instance.showOutgoingCall(
        callId: callId,
        receiverName: order.driver!.name,
        receiverId: order.driver!.id.toString(),
        isVideoCall: true,
        onCancel: () {
          debugPrint(
            'OrderDetailsViewModel: Custom overlay video call cancelled',
          );
        },
      );

      debugPrint(
        'OrderDetailsViewModel: Custom overlay video call initiated successfully',
      );
    } catch (error) {
      debugPrint(
        'OrderDetailsViewModel: Custom overlay video call error: $error',
      );
      // Fallback to regular phone call
      launchUrlString("tel:${order.driver?.phone}");
    }
  }

  void callRecipient() {
    launchUrlString("tel:${order.recipientPhone}");
  }

  chatVendor() {
    // Shop chat removed - only driver chat is available
    ScaffoldMessenger.of(
      viewContext,
    ).showSnackBar(SnackBar(content: Text("Chat with driver instead")));
  }

  chatDriver() {
    //
    Navigator.of(viewContext).pushNamed(AppRoutes.chatRoute, arguments: order);
  }

  Future<void> fetchOrderDetails() async {
    refreshController.refreshCompleted();
    notifyListeners();
    setBusy(true);
    try {
      order = await orderRequest.getOrderDetails(id: order.id);
      clearErrors();
    } catch (error) {
      print("Error ==> $error");
      setError(error);
      viewContext.showToast(msg: "$error", bgColor: Colors.red);
    }
    setBusy(false);
  }

  handleWebsocketOrderEvent() {
    //start websocket listening to ordr events
    if (AppStrings.useWebsocketAssignment) {
      OrderDetailsWebsocketService().connectToOrderChannel("${order.id}", (
        data,
      ) {
        fetchOrderDetails();
      });
    }
  }

  refreshDataSet() {
    if (!AppStrings.useWebsocketAssignment) {
      fetchOrderDetails();
    }
  }

  //
  rateVendor() async {
    showModalBottomSheet(
      context: viewContext,
      isScrollControlled: true,
      builder: (context) {
        return VendorRatingBottomSheet(
          order: order,
          onSubmitted: () {
            //
            viewContext.pop();
            fetchOrderDetails();
          },
        );
      },
    );
  }

  //
  rateDriver() async {
    await viewContext.push(
      (context) => DriverRatingBottomSheet(
        order: order,
        onSubmitted: () {
          //
          viewContext.pop();
          fetchOrderDetails();
        },
      ),
    );
  }

  //
  trackOrder() {
    Navigator.of(
      viewContext,
    ).pushNamed(AppRoutes.orderTrackingRoute, arguments: order);
  }

  cancelOrder() async {
    showModalBottomSheet(
      context: viewContext,
      isScrollControlled: true,
      builder: (context) {
        return OrderCancellationBottomSheet(
          order: order,
          onSubmit: (String reason) {
            viewContext.pop();
            processOrderCancellation(reason);
          },
        );
      },
    );
  }

  //
  processOrderCancellation(String reason) async {
    setBusyForObject(order, true);
    try {
      final responseMessage = await orderRequest.updateOrder(
        id: order.id,
        status: "cancelled",
        reason: reason,
      );
      //
      order.status = "cancelled";
      //message
      viewContext.showToast(
        msg: responseMessage,
        bgColor: Colors.green,
        textColor: Colors.white,
      );

      clearErrors();
    } catch (error) {
      print("Error ==> $error");
      setError(error);
      viewContext.showToast(
        msg: "$error",
        bgColor: Colors.red,
        textColor: Colors.white,
      );
    }
    setBusyForObject(order, false);
  }

  void showVerificationQRCode() async {
    showDialog(
      context: viewContext,
      builder: (context) {
        return Dialog(
          child:
              VStack([
                QrImageView(
                  data: order.verificationCode,
                  version: QrVersions.auto,
                  size: viewContext.percentWidth * 40,
                ).box.makeCentered(),
                "${order.verificationCode}".text.medium.xl2
                    .makeCentered()
                    .py4(),
                "Verification Code".tr().text.light.sm.makeCentered().py8(),
              ]).p20(),
        );
      },
    );
  }

  void shareOrderDetails() async {
    Share.share(
      "%s is sharing an order code with you. Track order with this code: %s"
          .tr()
          .fill([order.user.name, order.code]),
    );
  }

  openPaymentMethodSelection() async {
    //
    setBusyForObject(order.paymentStatus, true);
    await fetchPaymentOptions(vendorId: order.vendorId);
    setBusyForObject(order.paymentStatus, false);
    await
    //
    showModalBottomSheet(
      context: viewContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (contex) {
        return PaymentMethodsView(this)
            .p20()
            .scrollVertical()
            .box
            .color(contex.theme.colorScheme.surface)
            .topRounded()
            .make();
      },
    );
  }

  changeSelectedPaymentMethod(
    PaymentMethod? paymentMethod, {
    bool callTotal = true,
  }) async {
    //
    viewContext.pop();
    setBusyForObject(order.paymentStatus, true);
    try {
      //
      ApiResponse apiResponse = await orderRequest.updateOrderPaymentMethod(
        id: order.id,
        paymentMethodId: paymentMethod?.id,
        status: "pending",
      );

      //
      order = Order.fromJson(apiResponse.body["order"]);
      if (!["wallet", "cash"].contains(paymentMethod?.slug)) {
        if (paymentMethod?.slug == "offline") {
          openExternalWebpageLink(order.paymentLink);
        } else {
          openWebpageLink(order.paymentLink);
        }
      } else {
        toastSuccessful("${apiResponse.body['message']}");
      }

      //notify wallet view to update, just incase wallet was use for payment
      AppService().refreshWalletBalance.add(true);
    } catch (error) {
      toastError("$error");
    }
    setBusyForObject(order.paymentStatus, false);
  }
}
