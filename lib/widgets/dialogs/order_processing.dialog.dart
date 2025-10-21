import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:velocity_x/velocity_x.dart';

class OrderProcessingDialog extends StatelessWidget {
  const OrderProcessingDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provide fallback colors in case AppColor fails to load
    Color primaryColor;
    try {
      primaryColor = AppColor.primaryColor;
    } catch (e) {
      primaryColor = Colors.purple; // Default fallback color
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated order icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: primaryColor,
              ),
            ).centered(),

            SizedBox(height: 20),

            // Title
            Text(
              "Order Under Process".tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ).centered(),

            SizedBox(height: 12),

            // Description
            Text(
              "We're processing your order. This may take a few seconds.".tr(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ).centered(),

            SizedBox(height: 24),

            // Progress indicator with custom styling
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              backgroundColor: primaryColor.withOpacity(0.2),
              minHeight: 6,
            ),

            SizedBox(height: 16),

            // Status message
            Text(
              "Please wait...".tr(),
              style: TextStyle(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ).centered(),
          ],
        ),
      ),
    );
  }
}
