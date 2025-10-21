// import 'package:flutter/material.dart';
// import 'package:cool_alert/cool_alert.dart' as CoolAlertMain;

// class CoolAlert {
//   //
//   static Future<void> show({
//     /// BuildContext
//     required BuildContext context,

//     /// Title of the dialog
//     String? title,

//     /// Text of the dialog
//     String? text,

//     /// Custom Widget of the dialog
//     Widget? widget,

//     // Alert type [success, error, warning, confirm, info, loading, custom]
//     required CoolAlertType type,

//     /// Barrier Dissmisable
//     bool barrierDismissible = true,

//     // Triggered when confirm button is tapped
//     VoidCallback? onConfirmBtnTap,

//     /// Triggered when cancel button is tapped
//     VoidCallback? onCancelBtnTap,

//     /// Confirmation button text
//     String confirmBtnText = 'Ok',

//     /// Cancel button text
//     String cancelBtnText = 'Cancel',

//     /// Color for confirm button
//     Color confirmBtnColor = const Color(0xFF3085D6),

//     /// TextStyle for confirm button
//     TextStyle? confirmBtnTextStyle,

//     /// TextStyle for cancel button
//     TextStyle? cancelBtnTextStyle,

//     /// TextStyle for title
//     TextStyle? titleTextStyle,

//     /// TextStyle for text
//     TextStyle? textTextStyle,

//     /// Determines if cancel button is shown or not
//     bool showCancelBtn = false,

//     /// Dialog Border Radius
//     double borderRadius = 10.0,

//     /// Header background color
//     Color backgroundColor = const Color(0xFF515C6F),

//     /// Flare asset path
//     String? flareAsset,

//     /// Flare animation name
//     String flareAnimationName = 'play',

//     /// Asset path of your lottie file
//     String? lottieAsset,

//     /// Width of the dialog
//     double? width,

//     /// Determines how long the dialog stays open for before closing
//     /// [default] is null
//     /// When it is null, it won't autoclose
//     Duration? autoCloseDuration,

//     /// Detemines if the animation loops or not
//     bool loopAnimation = false,

//     /// Detemines if dialog closes when the confirm button is tapped
//     /// [default] is true
//     /// When it is true, it will close
//     /// When it is false, you will have to close it manually by using Navigator.of(context).pop();
//     bool closeOnConfirmBtnTap = false,

//     /// Reverse the order of the buttons
//     bool reverseBtnOrder = false,
//   }) async {
//     final result = await CoolAlertMain.CoolAlert.show(
//       context: context,
//       title: title,
//       text: text,
//       widget: widget,
//       type: CoolAlertMain.CoolAlertType.values[type.index],
//       barrierDismissible: barrierDismissible,
//       onCancelBtnTap: onCancelBtnTap,
//       confirmBtnText: confirmBtnText,
//       cancelBtnText: cancelBtnText,
//       confirmBtnColor: confirmBtnColor,
//       confirmBtnTextStyle: confirmBtnTextStyle,
//       cancelBtnTextStyle: cancelBtnTextStyle,
//       titleTextStyle: titleTextStyle,
//       textTextStyle: textTextStyle,
//       showCancelBtn: showCancelBtn,
//       borderRadius: borderRadius,
//       backgroundColor: backgroundColor,
//       flareAsset: flareAsset,
//       flareAnimationName: flareAnimationName,
//       lottieAsset: lottieAsset,
//       width: width,
//       loopAnimation: loopAnimation,
//       closeOnConfirmBtnTap: closeOnConfirmBtnTap,
//       autoCloseDuration: autoCloseDuration,
//       reverseBtnOrder: reverseBtnOrder,
//       onConfirmBtnTap: () {
//         onConfirmBtnTap!();
//       },
//     );
//   }

//   //
// }

// enum CoolAlertType { success, error, warning, confirm, info, loading, custom }
