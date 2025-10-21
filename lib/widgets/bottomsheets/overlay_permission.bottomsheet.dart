import 'package:flutter/material.dart';
import 'package:fuodz/services/app_permission_handler.service.dart';
import 'package:fuodz/utils/ui_spacer.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:velocity_x/velocity_x.dart';

class OverlayPermissionBottomSheet extends StatelessWidget {
  const OverlayPermissionBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: VStack([
        // Title
        "Overlay Permission Request".tr().text.semiBold.xl.make().py12(),

        // Description
        "This app needs permission to display over other apps for features like video calls and notifications. This permission helps ensure you don't miss important calls or updates."
            .tr()
            .text
            .make()
            .py12(),

        // Additional information about persistence
        "Once you grant this permission, you won't be asked again unless you revoke it in system settings."
            .tr()
            .text
            .italic
            .make()
            .py12(),

        UiSpacer.verticalSpace(),

        // Action buttons
        CustomButton(
          title: "Grant Permission".tr(),
          onPressed: () async {
            Navigator.of(context).pop();
            await _handleGrantPermission();
          },
        ).py8(),

        CustomButton(
          title: "Skip for Now".tr(),
          color: Colors.grey[400],
          onPressed: () async {
            Navigator.of(context).pop();
            await AppPermissionHandlerService.skipOverlayPermission();
          },
        ).py8(),

        CustomButton(
          title: "Don't Ask Again".tr(),
          color: Colors.red[400],
          onPressed: () async {
            Navigator.of(context).pop();
            await AppPermissionHandlerService.permanentlyDisableOverlayPermission();
          },
        ).py8(),

        UiSpacer.verticalSpace(),
      ]),
    );
  }

  Future<void> _handleGrantPermission() async {
    try {
      // Try to request the permission
      final status = await Permission.systemAlertWindow.request();
      if (status.isGranted) {
        await AppPermissionHandlerService.grantOverlayPermission();
      } else if (status.isPermanentlyDenied) {
        await AppPermissionHandlerService.permanentlyDisableOverlayPermission();
      } else {
        await AppPermissionHandlerService.skipOverlayPermission();
      }
    } catch (e) {
      print('Error handling overlay permission: $e');
      await AppPermissionHandlerService.skipOverlayPermission();
    }
  }
}
