// Removed dart:developer import

import 'package:country_picker/country_picker.dart';
// Removed Firebase Auth import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/api_response.dart';
import 'package:fuodz/models/user.dart';
import 'package:fuodz/requests/auth.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/services/social_media_login.service.dart';
import 'package:fuodz/services/custom_video_call.service.dart';
import 'package:fuodz/traits/qrcode_scanner.trait.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:fuodz/views/pages/auth/forgot_password.page.dart';
import 'package:fuodz/views/pages/auth/register.page.dart';
import 'package:fuodz/views/pages/home.page.dart';
import 'package:fuodz/widgets/bottomsheets/account_verification_entry.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'base.view_model.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:fuodz/extensions/context.dart';

class LoginViewModel extends MyBaseViewModel with QrcodeScannerTrait {
  //the textediting controllers
  TextEditingController phoneTEC = new TextEditingController();
  TextEditingController emailTEC = new TextEditingController();
  TextEditingController passwordTEC = new TextEditingController();

  //
  AuthRequest authRequest = AuthRequest();
  SocialMediaLoginService socialMediaLoginService = SocialMediaLoginService();
  bool otpLogin = AppStrings.enableOTPLogin;
  Country? selectedCountry;
  String? accountPhoneNumber;

  LoginViewModel(BuildContext context) {
    this.viewContext = context;
  }

  void initialise() async {
    //
    emailTEC.text = kReleaseMode ? "" : "client@demo.com";
    passwordTEC.text = kReleaseMode ? "" : "password";

    //phone login
    try {
      String countryCode = await Utils.getCurrentCountryCode();
      this.selectedCountry = Country.parse(countryCode);
    } catch (error) {
      this.selectedCountry = Country.parse("us");
    }
  }

  toggleLoginType() {
    otpLogin = !otpLogin;
    notifyListeners();
  }

  showCountryDialPicker() {
    showCountryPicker(
      context: viewContext,
      showPhoneCode: true,
      onSelect: countryCodeSelected,
    );
  }

  countryCodeSelected(Country country) {
    selectedCountry = country;
    notifyListeners();
  }

  void processOTPLogin() async {
    //
    accountPhoneNumber = "+${selectedCountry?.phoneCode}${phoneTEC.text}";
    // Validate returns true if the form is valid, otherwise false.
    if (formKey.currentState!.validate()) {
      //

      setBusyForObject(otpLogin, true);
      //phone number verification
      final apiResponse = await authRequest.verifyPhoneAccount(
        accountPhoneNumber!,
      );

      if (!apiResponse.allGood) {
        AlertService.error(title: "Login".tr(), text: apiResponse.message);
        setBusyForObject(otpLogin, false);
        return;
      }

      setBusyForObject(otpLogin, false);
      //
      if (AppStrings.isFirebaseOtp) {
        processFirebaseOTPVerification();
      } else {
        processCustomOTPVerification();
      }
    }
  }

  //PROCESSING VERIFICATION - DISABLED
  processFirebaseOTPVerification() async {
    setBusyForObject(otpLogin, true);
    print("Firebase phone verification disabled - using regular OTP");

    // Show verification entry directly
    showVerificationEntry();
    setBusyForObject(otpLogin, false);
  }

  processCustomOTPVerification() async {
    setBusyForObject(otpLogin, true);
    try {
      await authRequest.sendOTP(accountPhoneNumber!);
      setBusyForObject(otpLogin, false);
      showVerificationEntry();
    } catch (error) {
      setBusyForObject(otpLogin, false);
      viewContext.showToast(msg: "$error", bgColor: Colors.red);
    }
  }

  //
  void showVerificationEntry() async {
    //
    setBusy(false);
    //
    await viewContext.push(
      (context) => AccountVerificationEntry(
        vm: this,
        phone: accountPhoneNumber!,
        onSubmit: (smsCode) {
          //
          if (AppStrings.isFirebaseOtp) {
            verifyFirebaseOTP(smsCode);
          } else {
            verifyCustomOTP(smsCode);
          }

          viewContext.pop();
        },
        onResendCode: () async {
          if (!AppStrings.isCustomOtp) {
            return;
          }
          try {
            final response = await authRequest.sendOTP(accountPhoneNumber!);
            toastSuccessful(response.message ?? "Code sent successfully".tr());
          } catch (error) {
            viewContext.showToast(msg: "$error", bgColor: Colors.red);
          }
        },
      ),
    );
  }

  //
  void verifyFirebaseOTP(String smsCode) async {
    //
    setBusyForObject(otpLogin, true);

    // Sign the user in (or link) with the credential
    try {
      // Firebase OTP verification disabled - proceed with regular verification
      print("Firebase OTP verification disabled");
      await finishOTPLogin(null);
    } catch (error) {
      viewContext.showToast(msg: "$error", bgColor: Colors.red);
    }
    //
    setBusyForObject(otpLogin, false);
  }

  void verifyCustomOTP(String smsCode) async {
    //
    setBusy(true);
    // Sign the user in (or link) with the credential
    try {
      final apiResponse = await authRequest.verifyOTP(
        accountPhoneNumber!,
        smsCode,
        isLogin: true,
      );

      //
      setBusy(false);
      await handleDeviceLogin(apiResponse);
    } catch (error) {
      viewContext.showToast(msg: "$error", bgColor: Colors.red);
    }
    setBusy(false);
    //
  }

  //Login to with firebase token - DISABLED
  finishOTPLogin(dynamic authCredential) async {
    print("Firebase OTP login disabled - use regular OTP verification instead");
    setBusyForObject(otpLogin, false);
  }

  //REGULAR LOGIN
  void processLogin() async {
    // Validate returns true if the form is valid, otherwise false.
    if (formKey.currentState!.validate()) {
      //

      setBusy(true);

      final apiResponse = await authRequest.loginRequest(
        email: emailTEC.text,
        password: passwordTEC.text,
      );
      setBusy(false);

      //
      await handleDeviceLogin(apiResponse);
    }
  }

  //QRCode login
  void initateQrcodeLogin() async {
    //
    final loginCode = await openScanner(viewContext);
    if (loginCode == null) {
      toastError("Operation failed/cancelled".tr());
    } else {
      setBusy(true);

      try {
        final apiResponse = await authRequest.qrLoginRequest(code: loginCode);
        //
        setBusy(false);
        await handleDeviceLogin(apiResponse);
      } catch (error) {
        print("QR Code login error ==> $error");
      }
      setBusy(false);
    }
  }

  ///
  ///
  ///
  handleDeviceLogin(ApiResponse apiResponse) async {
    try {
      if (apiResponse.hasError()) {
        //there was an error
        AlertService.error(
          title: "Server Login Failed".tr(),
          text: apiResponse.message,
        );
      } else {
        //everything works well
        //firebase auth (optional)
        setBusy(true);
        // Firebase custom token authentication disabled
        print("Firebase custom token authentication disabled");

        await AuthServices.saveUser(apiResponse.body["user"]);
        await AuthServices.setAuthBearerToken(apiResponse.body["token"]);
        await AuthServices.isAuthenticated();
        
        // Initialize CustomVideoCallService with actual customer ID and name after successful login
        try {
          final user = User.fromJson(apiResponse.body["user"]);
          final customerId = 'customer_${user.id}';
          await CustomVideoCallService.initializeWithUser(
            customerId,
            user.name ?? 'Customer User',
          );
          debugPrint('CustomVideoCallService initialized with customer ID: $customerId');
        } catch (e) {
          debugPrint('Error initializing CustomVideoCallService after login: $e');
        }
        
        setBusy(false);
        //go to home
        Navigator.of(viewContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    } catch (error) {
      AlertService.error(title: "Login Failed".tr(), text: "${error}");
    }
  }

  ///

  void openRegister({String? email, String? name, String? phone}) async {
    Navigator.of(viewContext).push(
      MaterialPageRoute(
        builder:
            (context) => RegisterPage(email: email, name: name, phone: phone),
      ),
    );
  }

  void openForgotPassword() {
    Navigator.of(
      viewContext,
    ).push(MaterialPageRoute(builder: (context) => ForgotPasswordPage()));
  }
}
