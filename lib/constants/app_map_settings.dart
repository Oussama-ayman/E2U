import 'package:fuodz/constants/app_strings.dart';

class AppMapSettings extends AppStrings {
  static bool get useGoogleOnApp {
    // Force backend geocoding until server configuration is updated
    return false;
  }
}
