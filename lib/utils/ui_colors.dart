import 'package:flutter/material.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:velocity_x/velocity_x.dart';

class UIColors {
  static Color get divider {
    final context = AppService().navigatorKey.currentContext;
    if (context != null && context.isDarkMode) {
      return Colors.grey.shade500;
    }
    return Colors.grey.shade300;
  }
}
