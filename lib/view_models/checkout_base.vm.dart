import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_routes.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/extensions/string.dart';
import 'package:fuodz/models/checkout.dart';
import 'package:fuodz/models/delivery_address.dart';
import 'package:fuodz/models/vendor.dart';
import 'package:fuodz/models/payment_method.dart';
import 'package:fuodz/requests/checkout.request.dart';
import 'package:fuodz/requests/delivery_address.request.dart';
import 'package:fuodz/requests/vendor.request.dart';
import 'package:fuodz/requests/payment_method.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/services/cart.service.dart';
import 'package:fuodz/view_models/payment.view_model.dart';
import 'package:fuodz/widgets/bottomsheets/delivery_address_picker.bottomsheet.dart';
import 'package:fuodz/widgets/dialogs/order_processing.dialog.dart';
import 'package:jiffy/jiffy.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:fuodz/extensions/context.dart';
import 'package:collection/collection.dart';
import 'package:dartx/dartx.dart';

class CheckoutBaseViewModel extends PaymentViewModel {
  //
  CheckoutRequest checkoutRequest = CheckoutRequest();
  DeliveryAddressRequest deliveryAddressRequest = DeliveryAddressRequest();
  PaymentMethodRequest paymentOptionRequest = PaymentMethodRequest();

  VendorRequest vendorRequest = VendorRequest();
  TextEditingController driverTipTEC = TextEditingController();
  TextEditingController noteTEC = TextEditingController();
  DeliveryAddress? deliveryAddress;
  bool isPickup = false;
  bool isScheduled = false;
  List<String> availableTimeSlots = [];
  bool delievryAddressOutOfRange = false;
  bool canSelectPaymentOption = true;
  Vendor? vendor;
  CheckOut? checkout;
  bool calculateTotal = true;

  //
  List<PaymentMethod> paymentMethods = [];
  PaymentMethod? selectedPaymentMethod;
  //
  bool paymentTermsAgreed = false;

  // Cache order summary to avoid recalculation
  Map<String, dynamic>? _lastSummaryPayload;

  void initialise() async {
    // Ensure cart items are loaded
    await CartServices.getCartItems();

    // Validate cart items
    if (CartServices.productsInCart.isEmpty) {
      print("ERROR: No products in cart during checkout initialization");
      AlertService.error(
        context: viewContext,
        title: "Empty Cart".tr(),
        text: "Your cart is empty. Please add items before checkout.".tr(),
      );
      return;
    }

    print(
      "Checkout initialization - Cart items: ${CartServices.productsInCart.length}",
    );
    print(
      "Cart items: ${CartServices.productsInCart.map((e) => '${e.product?.name} (${e.selectedQty})').toList()}",
    );

    await fetchVendorDetails();
    prefetchDeliveryAddress();
    fetchPaymentOptions();
    updateTotalOrderSummary();
  }

  //
  fetchVendorDetails() async {
    //
    if (CartServices.productsInCart.isEmpty) {
      return;
    }
    vendor = CartServices.productsInCart[0].product?.vendor;

    //
    setBusy(true);
    try {
      vendor = await vendorRequest.vendorDetails(
        vendor!.id,
        params: {"type": "brief"},
      );
      setVendorRequirement();
    } catch (error) {
      print("Error Getting Vendor Details ==> $error");
    }
    setBusy(false);
  }

  setVendorRequirement() {
    if (vendor!.allowOnlyDelivery) {
      isPickup = false;
    } else if (vendor!.allowOnlyPickup) {
      isPickup = true;
    }
  }

  //start of schedule related
  changeSelectedDeliveryDate(String string, int index) {
    checkout?.deliverySlotDate = string;
    availableTimeSlots = vendor!.deliverySlots[index].times;
    notifyListeners();
  }

  changeSelectedDeliveryTime(String time) {
    checkout?.deliverySlotTime = time;
    notifyListeners();
  }

  //end of schedule related
  //
  prefetchDeliveryAddress() async {
    setBusyForObject(deliveryAddress, true);
    //
    try {
      //
      checkout!.deliveryAddress =
          deliveryAddress = await deliveryAddressRequest
              .preselectedDeliveryAddress(vendorId: vendor?.id);

      if (checkout?.deliveryAddress != null) {
        //
        checkDeliveryRange();
        updateTotalOrderSummary();
      }
    } catch (error) {
      print("Error Fetching preselected Address ==> $error");
    }
    setBusyForObject(deliveryAddress, false);
  }

  //
  fetchPaymentOptions({int? vendorId}) async {
    setBusyForObject(paymentMethods, true);
    try {
      paymentMethods = await paymentOptionRequest.getPaymentOptions(
        vendorId: vendorId != null ? vendorId : vendor?.id,
        params: {"is_pickup": isPickup ? 1 : 0},
      );
      //
      updatePaymentOptionSelection();
      clearErrors();
    } catch (error) {
      print("Regular Error getting payment methods ==> $error");
    }
    setBusyForObject(paymentMethods, false);
  }

  //
  fetchTaxiPaymentOptions() async {
    setBusyForObject(paymentMethods, true);
    try {
      paymentMethods = await paymentOptionRequest.getTaxiPaymentOptions();
      //
      updatePaymentOptionSelection();
      clearErrors();
    } catch (error) {
      print("Taxi Error getting payment methods ==> $error");
    }
    setBusyForObject(paymentMethods, false);
  }

  updatePaymentOptionSelection() {
    if (checkout != null && checkout!.total <= 0.00) {
      canSelectPaymentOption = false;
    } else {
      canSelectPaymentOption = true;
    }
    //
    if (!canSelectPaymentOption) {
      final selectedPaymentMethod = paymentMethods.firstOrNullWhere(
        (e) => e.isCash == 1,
      );
      changeSelectedPaymentMethod(selectedPaymentMethod, callTotal: false);
    }
  }

  //
  Future<DeliveryAddress?> showDeliveryAddressPicker() async {
    //
    final mDeliveryAddress = await showModalBottomSheet(
      context: viewContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DeliveryAddressPicker(
          onSelectDeliveryAddress: (deliveryAddress) {
            this.deliveryAddress = deliveryAddress;
            checkout?.deliveryAddress = deliveryAddress;
            //
            checkDeliveryRange();
            updateTotalOrderSummary();
            //
            notifyListeners();
            viewContext.pop(deliveryAddress);
          },
        );
      },
    );
    return mDeliveryAddress;
  }

  //
  togglePickupStatus(bool? value) {
    //
    if (vendor!.allowOnlyPickup) {
      value = true;
    } else if (vendor!.allowOnlyDelivery) {
      value = false;
    }
    isPickup = value ?? false;
    //remove delivery address if pickup
    if (isPickup) {
      checkout?.deliveryAddress = null;
    } else {
      checkout?.deliveryAddress = deliveryAddress;
    }

    updateTotalOrderSummary();
    notifyListeners();
    fetchPaymentOptions();
  }

  //
  toggleScheduledOrder(bool? value) async {
    isScheduled = value ?? false;
    checkout?.isScheduled = isScheduled;
    //remove delivery address if pickup
    checkout?.pickupDate = null;
    checkout?.deliverySlotDate = "";
    checkout?.pickupTime = null;
    checkout?.deliverySlotTime = "";

    await Jiffy.setLocale(translator.activeLocale.languageCode);

    notifyListeners();
  }

  //
  void checkDeliveryRange() {
    delievryAddressOutOfRange =
        vendor!.deliveryRange < (deliveryAddress!.distance ?? 0);
    if (deliveryAddress?.can_deliver != null) {
      delievryAddressOutOfRange =
          (deliveryAddress?.can_deliver ?? false) ==
          false; //if vendor has set delivery range
    }
    notifyListeners();
  }

  //
  isSelected(PaymentMethod paymentMethod) {
    return paymentMethod.id == selectedPaymentMethod?.id;
  }

  changeSelectedPaymentMethod(
    PaymentMethod? paymentMethod, {
    bool callTotal = true,
  }) {
    selectedPaymentMethod = paymentMethod;
    checkout?.paymentMethod = paymentMethod;
    if (callTotal) {
      updateTotalOrderSummary();
    }
    notifyListeners();
  }

  //update total/order amount summary with caching
  updateTotalOrderSummary() async {
    final payload = {
      "pickup": isPickup ? 1 : 0,
      "delievryAddressOutOfRange": delievryAddressOutOfRange ? 1 : 0,
      "tip": driverTipTEC.text,
      "delivery_address_id": deliveryAddress?.id ?? "null",
      "latlng":
          "${deliveryAddress?.latitude ?? 0},${deliveryAddress?.longitude ?? 0}",
      "coupon_code": checkout?.coupon?.code ?? "",
      "vendor_id": vendor?.id ?? 0,
      "products":
          CartServices.productsInCart.map((e) => e.toCheckout()).toList(),
    };

    // Check if payload changed to avoid unnecessary API calls
    if (_lastSummaryPayload != null &&
        const DeepCollectionEquality().equals(_lastSummaryPayload, payload)) {
      print("Order summary unchanged, using cached result");
      return;
    }

    setBusy(true);
    try {
      final mCheckout = await checkoutRequest.orderSummary(payload);
      _lastSummaryPayload = payload;

      checkout?.copyWith(
        subTotal: mCheckout.subTotal,
        discount: mCheckout.discount,
        deliveryFee: mCheckout.deliveryFee,
        tax: mCheckout.tax,
        tax_rate: mCheckout.tax_rate,
        total: mCheckout.total,
        totalWithTip: mCheckout.totalWithTip,
        token: mCheckout.token,
        fees: mCheckout.fees,
      );
    } catch (error) {
      print("Error getting order summary ==> $error");
      toastError("$error");
    }
    setBusy(false);
    //
    updatePaymentOptionSelection();
    notifyListeners();
  }

  //
  bool pickupOnlyProduct() {
    //
    final product = CartServices.productsInCart.firstOrNullWhere(
      (e) => !e.product?.canBeDelivered,
    );

    return product != null;
  }

  // Add loading states with timeouts
  Future<void> placeOrderWithProgress() async {
    // Show loading dialog with timeout
    showDialog(
      context: viewContext,
      barrierDismissible: false,
      builder: (context) => OrderProcessingDialog(),
    );

    try {
      await processOrderPlacement().timeout(
        Duration(seconds: 45), // Give reasonable timeout
        onTimeout: () {
          throw TimeoutException('Order processing timed out');
        },
      );
    } finally {
      if (Navigator.canPop(viewContext)) {
        Navigator.pop(viewContext); // Close loading dialog
      }
    }
  }

  //
  placeOrder({bool ignore = false}) async {
    //
    if (isScheduled && (checkout?.deliverySlotDate.isEmptyOrNull ?? true)) {
      //
      AlertService.error(
        context: viewContext,
        title: "Delivery Date".tr(),
        text: "Please select your desire order date".tr(),
      );
    } else if (isScheduled &&
        (checkout?.deliverySlotTime.isEmptyOrNull ?? true)) {
      //
      AlertService.error(
        context: viewContext,
        title: "Delivery Time".tr(),
        text: "Please select your desire order time".tr(),
      );
    } else if (!isPickup && pickupOnlyProduct()) {
      //
      AlertService.error(
        context: viewContext,
        title: "Product".tr(),
        text:
            "There seems to be products that can not be delivered in your cart"
                .tr(),
      );
    } else if (!isPickup && deliveryAddress == null) {
      //
      AlertService.error(
        context: viewContext,
        title: "Delivery address".tr(),
        text: "Please select delivery address".tr(),
      );
    } else if (delievryAddressOutOfRange && !isPickup) {
      //
      AlertService.error(
        context: viewContext,
        title: "Delivery address".tr(),
        text: "Delivery address is out of vendor delivery range".tr(),
      );
    } else if (selectedPaymentMethod == null) {
      AlertService.error(
        context: viewContext,
        title: "Payment Methods".tr(),
        text: "Please select a payment method".tr(),
      );
    } else if (!ignore && !verifyVendorOrderAmountCheck()) {
      print("Failed");
    }
    //process the new order
    else {
      // Add a simple timeout to prevent hanging
      try {
        await processOrderPlacement().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            print("Checkout process timed out");
            setBusy(false);
            AlertService.error(
              context: viewContext,
              title: "Timeout".tr(),
              text: "Checkout process timed out. Please try again.".tr(),
            );
            throw TimeoutException(
              'Checkout process timed out',
              const Duration(seconds: 60),
            );
          },
        );
      } catch (e) {
        if (e is TimeoutException) {
          // Already handled above
          return;
        }
        print("Error in checkout process: $e");
        setBusy(false);
        AlertService.error(
          context: viewContext,
          title: "Error".tr(),
          text: "An error occurred during checkout. Please try again.".tr(),
        );
      }
    }
  }

  //
  processOrderPlacement() async {
    //process the order placement
    setBusy(true);

    // Validate required data before placing order
    if (checkout?.cartItems == null || checkout!.cartItems!.isEmpty) {
      AlertService.error(
        context: viewContext,
        title: "Invalid Order".tr(),
        text: "No items in cart. Please refresh and try again.".tr(),
      );
      setBusy(false);
      return;
    }

    if (checkout?.paymentMethod == null) {
      AlertService.error(
        context: viewContext,
        title: "Payment Method".tr(),
        text: "Please select a payment method.".tr(),
      );
      setBusy(false);
      return;
    }

    if (!isPickup && checkout?.deliveryAddress == null) {
      AlertService.error(
        context: viewContext,
        title: "Delivery Address".tr(),
        text: "Please select a delivery address.".tr(),
      );
      setBusy(false);
      return;
    }

    print("Placing order with ${checkout!.cartItems!.length} items");
    print("Payment method: ${checkout!.paymentMethod?.name}");
    print("Delivery address: ${checkout!.deliveryAddress?.address}");
    print("Total: ${checkout!.total}");

    //set the total with discount as the new total
    checkout!.total = checkout!.totalWithTip;

    try {
      // Add timeout to prevent hanging
      final apiResponse = await checkoutRequest
          .newOrder(checkout!, tip: driverTipTEC.text, note: noteTEC.text)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Order placement timed out',
                const Duration(seconds: 30),
              );
            },
          );

      print("Order API response: ${apiResponse.allGood}");
      print("Order API message: ${apiResponse.message}");

      //notify wallet view to update, just incase wallet was use for payment
      AppService().refreshWalletBalance.add(true);

      //not error
      if (apiResponse.allGood) {
        try {
          await CartServices.clearCart();
          print("Cart cleared successfully after order placement");

          //cash payment
          final paymentLink = apiResponse.body["link"].toString();
          if (!paymentLink.isEmptyOrNull) {
            print("Processing payment link: $paymentLink");
            //close pages
            await Navigator.of(viewContext).pushNamedAndRemoveUntil(
              AppRoutes.homeRoute,
              (route) {
                return route.isFirst;
              },
            );
            showOrdersTab(context: viewContext);
            dynamic result;
            // if (["offline", "razorpay"]
            if ([
              "offline",
            ].contains(checkout!.paymentMethod?.slug ?? "offline")) {
              result = await openExternalWebpageLink(paymentLink);
            } else {
              result = await openWebpageLink(paymentLink);
            }
            print("Result from payment ==> $result");
          }
          //cash payment
          else {
            print("Processing cash payment - showing success alert");
            bool alertShown = false;

            try {
              await AlertService.success(
                context: viewContext, // Pass the context explicitly
                title: "Checkout".tr(),
                text: apiResponse.message,
                confirmBtnText: "Ok".tr(),
                barrierDismissible: false,
                onConfirm: () async {
                  try {
                    print("Success alert confirmed - navigating to home");
                    await Navigator.of(viewContext).pushNamedAndRemoveUntil(
                      AppRoutes.homeRoute,
                      (route) {
                        return route.isFirst;
                      },
                    );
                    showOrdersTab(context: viewContext);
                  } catch (e) {
                    print("Error navigating after order success: $e");
                    // Fallback navigation
                    if (viewContext.mounted) {
                      viewContext.pop();
                    }
                  }
                },
              );
              alertShown = true;
            } catch (e) {
              print("Error showing success alert: $e");
              alertShown = false;
            }

            // If alert failed to show, use fallback navigation
            if (!alertShown) {
              try {
                print("Using fallback navigation after alert error");
                await Navigator.of(viewContext).pushNamedAndRemoveUntil(
                  AppRoutes.homeRoute,
                  (route) {
                    return route.isFirst;
                  },
                );
                showOrdersTab(context: viewContext);
              } catch (navError) {
                print("Error in fallback navigation: $navError");
                // Last resort: just pop the current context
                if (viewContext.mounted) {
                  viewContext.pop();
                }
              }
            }
          }
        } catch (e) {
          print("Error in post-order processing: $e");
          // Even if there's an error, try to navigate away
          try {
            if (viewContext.mounted) {
              viewContext.pop();
            }
          } catch (popError) {
            print("Error popping context: $popError");
          }
        }
      } else {
        print("Order placement failed: ${apiResponse.message}");
        AlertService.error(
          context: viewContext,
          title: "Checkout".tr(),
          text: apiResponse.message,
        );
      }
    } catch (e) {
      print("Error during order placement: $e");
      if (e is TimeoutException) {
        AlertService.error(
          context: viewContext,
          title: "Timeout".tr(),
          text: "Order placement timed out. Please try again.".tr(),
        );
      } else {
        AlertService.error(
          context: viewContext,
          title: "Error".tr(),
          text: "Failed to place order. Please try again.".tr(),
        );
      }

      // Ensure cart is cleared even on error to prevent getting stuck
      try {
        await CartServices.clearCart();
        print("Cart cleared after order placement error");
      } catch (clearError) {
        print("Error clearing cart after order error: $clearError");
      }

      // Try to navigate away from checkout page
      try {
        if (viewContext.mounted) {
          viewContext.pop();
        }
      } catch (popError) {
        print("Error popping context after order error: $popError");
      }
    }

    // Always ensure busy state is reset
    try {
      setBusy(false);
    } catch (e) {
      print("Error resetting busy state: $e");
    }

    // Always refresh cart state
    try {
      CartServices.refreshState();
    } catch (refreshError) {
      print("Error refreshing cart state: $refreshError");
    }
  }

  //
  showOrdersTab({required BuildContext context}) {
    try {
      //clear cart items
      CartServices.clearCart();
      print("Cart cleared in showOrdersTab");

      //switch tab to orders
      AppService().changeHomePageIndex(index: 1);
      print("Home page index changed to orders tab");

      //pop until home page
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil(
          (route) =>
              route.settings.name == AppRoutes.homeRoute || route.isFirst,
        );
        print("Navigated back to home page");
      } else {
        print("Cannot pop - already at home page");
      }
    } catch (e) {
      print("Error in showOrdersTab: $e");
      // Fallback: just pop the current context
      try {
        if (context.mounted) {
          context.pop();
        }
      } catch (popError) {
        print("Error in fallback pop: $popError");
      }
    }
  }

  //
  bool verifyVendorOrderAmountCheck() {
    //if vendor set min/max order
    final orderVendor = checkout?.cartItems?.first.product?.vendor ?? vendor;
    //if order is less than the min allowed order by this vendor
    //if vendor is currently open for accepting orders

    if (vendor == null) {
      AlertService.error(
        context: viewContext,
        title: "Vendor Error".tr(),
        text: "Vendor information not available".tr(),
      );
      return false;
    }

    if (!vendor!.isOpen &&
        !(checkout?.isScheduled ?? false) &&
        !(checkout?.isPickup ?? false)) {
      //vendor is closed
      AlertService.error(
        context: viewContext,
        title: "Vendor is not open".tr(),
        text:
            "Vendor is currently not open to accepting order at the moment"
                .tr(),
      );
      return false;
    } else if (orderVendor?.minOrder != null &&
        orderVendor!.minOrder! > (checkout?.subTotal ?? 0)) {
      ///
      AlertService.error(
        context: viewContext,
        title: "Minimum Order Value".tr(),
        text:
            "Order value/amount is less than vendor accepted minimum order"
                .tr() +
            "${AppStrings.currencySymbol} ${orderVendor.minOrder}"
                .currencyFormat(),
      );
      return false;
    }
    //if order is more than the max allowed order by this vendor
    else if (orderVendor?.maxOrder != null &&
        orderVendor!.maxOrder! < (checkout?.subTotal ?? 0)) {
      //
      AlertService.error(
        context: viewContext,
        title: "Maximum Order Value".tr(),
        text:
            "Order value/amount is more than vendor accepted maximum order"
                .tr() +
            "${AppStrings.currencySymbol} ${orderVendor.maxOrder}"
                .currencyFormat(),
      );
      return false;
    }
    return true;
  }

  // Debug method to test checkout functionality
  void debugCheckout() {
    print("=== CHECKOUT DEBUG INFO ===");
    print("Checkout object: ${checkout != null ? 'Present' : 'Null'}");
    print("Cart items: ${checkout?.cartItems?.length ?? 0}");
    print("Vendor: ${vendor?.name ?? 'Null'}");
    print("Delivery address: ${deliveryAddress?.address ?? 'Null'}");
    print("Payment method: ${selectedPaymentMethod?.name ?? 'Null'}");
    print("Is pickup: $isPickup");
    print("Is scheduled: $isScheduled");
    print("Sub total: ${checkout?.subTotal ?? 0}");
    print("Total: ${checkout?.total ?? 0}");
    print("=== END CHECKOUT DEBUG ===");
  }
}
