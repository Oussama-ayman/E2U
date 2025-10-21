// Firebase Auth removed - social media login disabled
import 'package:fuodz/view_models/login.view_model.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class SocialMediaLoginService {
  //Google login - DISABLED
  void googleLogin(LoginViewModel model) async {
    model.setBusy(true);
    model.toastError("Social media login disabled - Firebase removed".tr());
    model.setBusy(false);
  }

  //Facebook login - DISABLED
  void facebookLogin(LoginViewModel model) async {
    model.setBusy(true);
    model.toastError("Social media login disabled - Firebase removed".tr());
    model.setBusy(false);
  }

  //Apple login - DISABLED
  void appleLogin(LoginViewModel model) async {
    model.setBusy(true);
    model.toastError("Social media login disabled - Firebase removed".tr());
    model.setBusy(false);
  }
}
