import 'dart:async';
// import 'package:cool_alert/cool_alert.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:fuodz/extensions/context.dart';
import 'package:velocity_x/velocity_x.dart';

class AlertService {
  //

  static Future<bool> showConfirm({
    String? title,
    String? text,
    String cancelBtnText = "Cancel",
    String confirmBtnText = "Ok",
    bool closeOnConfirmBtnTap = true,
    Function? onConfirm,
    BuildContext? context, // Added context parameter
  }) async {
    //
    bool result = false;
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show confirm alert");
      return false;
    }

    await QuickAlert.show(
      borderRadius: Sizes.radiusSmall,
      context: alertContext,
      type: QuickAlertType.confirm,
      text: text,
      title: title,
      confirmBtnText: confirmBtnText.tr(),
      cancelBtnText: cancelBtnText.tr(),
      confirmBtnColor: AppColor.primaryColor,
      onConfirmBtnTap: () {
        alertContext.pop();
        if (onConfirm == null) {
          result = true;
        } else {
          onConfirm();
        }
      },
    );

    // await CoolAlert.show(
    //   confirmBtnColor: AppColor.primaryColor,
    //   context: context,
    //   type: CoolAlertType.confirm,
    //   animType: CoolAlertAnimType.slideInDown,
    //   title: title,
    //   text: text,
    //   cancelBtnText: cancelBtnText.tr(),
    //   confirmBtnText: confirmBtnText.tr(),
    //   closeOnConfirmBtnTap: closeOnConfirmBtnTap,
    //   onConfirmBtnTap: () {
    //     if (onConfirm == null) {
    //       result = true;
    //       AppService().navigatorKey.currentContext?.pop();
    //     } else {
    //       onConfirm();
    //     }
    //   },
    // );

    //
    return result;
  }

  static Future<bool> confirm({
    String? title,
    String? text,
    String confirmBtnText = "Ok",
    String? cancelBtnText = "Cancel",
    Function? onConfirm,
    Function? onCancel,
    BuildContext? context,
  }) async {
    bool result = false;
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show confirm alert");
      return false;
    }

    await QuickAlert.show(
      context: alertContext,
      type: QuickAlertType.confirm,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText.tr(),
      cancelBtnText: (cancelBtnText ?? "Cancel").tr(),
      onConfirmBtnTap: () {
        result = true;
        alertContext.pop();
        if (onConfirm != null) {
          onConfirm();
        }
      },
      onCancelBtnTap: () {
        result = false;
        alertContext.pop();
        if (onCancel != null) {
          onCancel();
        }
      },
    );

    return result;
  }

  static Future<bool> success({
    String? title,
    String? text,
    String confirmBtnText = "Ok",
    String cancelBtnText = "Cancel",
    bool barrierDismissible = true,
    bool closeOnConfirmBtnTap = true,
    Function? onConfirm,
    BuildContext? context, // Added context parameter
    result,
  }) async {
    //
    bool result = false;
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show success alert");
      return false;
    }

    await QuickAlert.show(
      context: alertContext,
      type: QuickAlertType.success,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText.tr(),
      cancelBtnText: cancelBtnText.tr(),
      onConfirmBtnTap: () {
        // if (!closeOnConfirmBtnTap) {
        alertContext.pop(result);
        // }
        result = true;
        if (onConfirm != null) {
          onConfirm();
        }
      },
    );

    // await CoolAlert.show(
    //   context: AppService().navigatorKey.currentContext!,
    //   type: CoolAlertType.success,
    //   title: title,
    //   text: text,
    //   confirmBtnText: confirmBtnText.tr(),
    //   cancelBtnText: cancelBtnText.tr(),
    //   closeOnConfirmBtnTap: closeOnConfirmBtnTap,
    //   onConfirmBtnTap: () {
    //     result = true;
    //     if (onConfirm != null) {
    //       onConfirm();
    //     }
    //     if (!closeOnConfirmBtnTap) {
    //       AppService().navigatorKey.currentContext?.pop();
    //     }
    //   },
    // );

    //
    return result;
  }

  static Future<bool> error({
    String? title,
    String? text,
    String confirmBtnText = "Ok",
    Function? onConfirm,
    BuildContext? context, // Added context parameter
  }) async {
    //
    bool result = false;
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show error alert");
      return false;
    }

    await QuickAlert.show(
      context: alertContext,
      type: QuickAlertType.error,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText.tr(),
      onConfirmBtnTap:
          onConfirm != null
              ? () {
                result = true;
                alertContext.pop();
                onConfirm();
              }
              : null,
    );
    // await CoolAlert.show(
    //   context: AppService().navigatorKey.currentContext!,
    //   type: CoolAlertType.error,
    //   title: title,
    //   text: text,
    //   confirmBtnText: confirmBtnText.tr(),
    //   closeOnConfirmBtnTap: onConfirm == null,
    //   onConfirmBtnTap: onConfirm != null
    //       ? () {
    //           result = true;
    //           AppService().navigatorKey.currentContext?.pop();
    //           onConfirm();
    //         }
    //       : null,
    // );

    //
    return result;
  }

  static Future<bool> warning({
    String? title,
    String? text,
    String confirmBtnText = "Ok",
    Function? onConfirm,
    BuildContext? context, // Added context parameter
  }) async {
    //
    bool result = false;
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show warning alert");
      return false;
    }

    await QuickAlert.show(
      context: alertContext,
      type: QuickAlertType.warning,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText.tr(),
      onConfirmBtnTap:
          onConfirm != null
              ? () {
                result = true;
                alertContext.pop();
                onConfirm();
              }
              : null,
    );

    //
    return result;
  }

  static Future<bool> custom({
    String? title,
    String? text,
    String confirmBtnText = "Ok",
    String? cancelBtnText = "Cancel",
    AlertType? type,
    Function? onConfirm,
    TextStyle? confirmBtnTextStyle,
    TextStyle? cancelBtnTextStyle,
    String? customAsset,
    BuildContext? context,
  }) async {
    bool result = false;
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show custom alert");
      return false;
    }

    await QuickAlert.show(
      context: alertContext,
      type:
          type != null
              ? QuickAlertType.values[type.index]
              : QuickAlertType.info,
      title: title,
      text: text,
      titleColor: alertContext.textTheme.bodyLarge?.color ?? Colors.black,
      textColor: alertContext.textTheme.bodyLarge?.color ?? Colors.black,
      backgroundColor: alertContext.theme.dialogBackgroundColor,
      confirmBtnColor: AppColor.primaryColor,
      confirmBtnText: confirmBtnText.tr(),
      showCancelBtn: ((cancelBtnText ?? "").tr()).isNotEmpty,
      cancelBtnText: (cancelBtnText ?? "").tr(),
      confirmBtnTextStyle: confirmBtnTextStyle,
      cancelBtnTextStyle: cancelBtnTextStyle,
      customAsset: customAsset,
      width: alertContext.percentWidth * 90,
      onConfirmBtnTap:
          onConfirm != null
              ? () {
                result = true;
                alertContext.pop();
                onConfirm();
              }
              : null,
    );
    // await CoolAlert.show(
    //   context: AppService().navigatorKey.currentContext!,
    //   type:
    //       type != null ? CoolAlertType.values[type.index] : CoolAlertType.info,
    //   title: title,
    //   text: text,
    //   confirmBtnText: confirmBtnText.tr(),
    //   cancelBtnText: (cancelBtnText ?? "").tr(),
    //   closeOnConfirmBtnTap: onConfirm == null,
    //   confirmBtnTextStyle: confirmBtnTextStyle,
    //   cancelBtnTextStyle: cancelBtnTextStyle,
    //   onConfirmBtnTap: onConfirm != null
    //       ? () {
    //           result = true;
    //           AppService().navigatorKey.currentContext?.pop();
    //           onConfirm();
    //         }
    //       : null,
    // );

    //
    return result;
  }

  static Future<bool> dynamic({
    String? title,
    String? text,
    String confirmBtnText = "Ok",
    String? cancelBtnText = "Close",
    AlertType? type,
    Function? onConfirm,
    BuildContext? context, // Added context parameter
  }) async {
    //
    bool result = false;
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show dynamic alert");
      return false;
    }

    await QuickAlert.show(
      context: alertContext,
      type:
          type != null
              ? QuickAlertType.values[type.index]
              : QuickAlertType.info,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText.tr(),
      cancelBtnText: (cancelBtnText ?? "").tr(),
      onConfirmBtnTap:
          onConfirm != null
              ? () {
                result = true;
                alertContext.pop();
                onConfirm();
              }
              : null,
    );
    // await CoolAlert.show(
    //   context: AppService().navigatorKey.currentContext!,
    //   type: type ?? CoolAlertType.info,
    //   title: title,
    //   text: text,
    //   confirmBtnText: confirmBtnText.tr(),
    //   closeOnConfirmBtnTap: false,
    //   onConfirmBtnTap: () {
    //     result = true;
    //     AppService().navigatorKey.currentContext?.pop();
    //   },
    // );

    //
    return result;
  }

  static void showLoading({BuildContext? context}) {
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show loading");
      return;
    }

    QuickAlert.show(
      context: alertContext,
      type: QuickAlertType.loading,
      title: '',
      text: "Processing. Please wait...".tr(),
    );
  }

  static void loading({
    bool barrierDismissible = false,
    String? title,
    String? text,
    BuildContext? context, // Added context parameter
  }) {
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    if (alertContext == null) {
      print("AlertService: Context is null, cannot show loading");
      return;
    }

    QuickAlert.show(
      context: alertContext,
      type: QuickAlertType.loading,
      title: '',
      text: "Processing. Please wait...".tr(),
    );
  }

  static void stopLoading({BuildContext? context}) {
    final alertContext = context ?? AppService().navigatorKey.currentContext;
    alertContext?.pop();
  }
}

// enums
// enum AlertType { success, error, warning, confirm, info, loading, custom }
enum AlertType { success, error, warning, confirm, info, loading, custom }
