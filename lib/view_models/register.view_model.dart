import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/requests/auth.request.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class RegisterViewModel extends MyBaseViewModel {
  //
  AuthRequest authRequest = AuthRequest();
  TextEditingController nameTEC = TextEditingController();
  TextEditingController emailTEC = TextEditingController();
  TextEditingController phoneTEC = TextEditingController();
  TextEditingController passwordTEC = TextEditingController();
  TextEditingController confirmPasswordTEC = TextEditingController();
  TextEditingController referralCodeTEC = TextEditingController();
  String? accountPhoneNumber;
  String? firebaseVerificationId;
  Country? selectedCountry;
  String? otpCode;
  bool agreed = false;

  RegisterViewModel(BuildContext context) {
    this.viewContext = context;
  }

  showCountryDialPicker() {
    // Show country picker
    toastError("Country picker disabled".tr());
  }

  processRegister() async {
    setBusy(true);
    try {
      final apiResponse = await authRequest.registerRequest(
        name: nameTEC.text,
        email: emailTEC.text,
        phone: phoneTEC.text,
        password: passwordTEC.text,
        countryCode: selectedCountry?.countryCode ?? "US",
      );

      if (apiResponse.allGood) {
        toastSuccessful("Registration successful".tr());
        Navigator.of(viewContext).pop();
      } else {
        toastError(apiResponse.message ?? "Registration failed");
      }
    } catch (error) {
      toastError("$error");
    }
    setBusy(false);
  }

  // Firebase disabled - using regular registration
  processFirebaseOTPVerification() async {
    setBusy(true);
    toastError(
      "Firebase OTP verification disabled - use regular registration".tr(),
    );
    setBusy(false);
  }

  showVerificationEntry() {
    // Show verification UI
  }

  verifyFirebaseOTP(String smsCode) async {
    setBusy(true);
    toastError("Firebase OTP verification disabled".tr());
    setBusy(false);
  }

  finishAccountRegistration() async {
    setBusy(true);
    try {
      final apiResponse = await authRequest.registerRequest(
        name: nameTEC.text,
        email: emailTEC.text,
        phone: phoneTEC.text,
        password: passwordTEC.text,
        countryCode: selectedCountry?.countryCode ?? "US",
      );

      if (apiResponse.allGood) {
        toastSuccessful("Registration successful".tr());
        Navigator.of(viewContext).pop();
      } else {
        toastError(apiResponse.message ?? "Registration failed");
      }
    } catch (error) {
      toastError("$error");
    }
    setBusy(false);
  }
}
