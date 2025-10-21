import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fuodz/models/vendor_type.dart';
import 'package:fuodz/requests/vendor_type.request.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/services/location.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:fuodz/views/pages/vendor/featured_vendors.page.dart';

class WelcomeViewModel extends MyBaseViewModel {
  //
  WelcomeViewModel(BuildContext context) {
    this.viewContext = context;
  }

  Widget? selectedPage;
  List<VendorType> vendorTypes = [];
  VendorType? vendorType; // Added missing vendorType property
  VendorTypeRequest vendorTypeRequest = VendorTypeRequest();
  bool showGrid = true;
  StreamSubscription? authStateSub;

  //
  //
  initialise({bool initial = true}) async {
    //
    preloadDeliveryLocation();
    //
    if (refreshController.isRefresh) {
      refreshController.refreshCompleted();
    }

    if (!initial) {
      pageKey = GlobalKey();
      notifyListeners();
    }

    await getVendorTypes();
    listenToAuth();
    //
    handleLocationStream();
  }

  StreamSubscription? currentLocSub;
  StreamSubscription? currentLoc2Sub;
  handleLocationStream() async {
    await currentLocSub?.cancel();
    currentLocSub = LocationService.currenctDeliveryAddressSubject
        .skipWhile((_) => true)
        .listen((event) {
          initialise(initial: false);
        });

    await currentLoc2Sub?.cancel();
    currentLoc2Sub = LocationService.currenctDeliveryAddressSubject.stream
        .skipWhile((_) => true)
        .listen((event) {
          initialise(initial: false);
        });
  }

  listenToAuth() {
    authStateSub = AuthServices.listenToAuthState().listen((event) {
      genKey = GlobalKey();
      notifyListeners();
    });
  }

  getVendorTypes() async {
    setBusy(true);
    try {
      print("WelcomeViewModel: Loading vendor types...");
      vendorTypes = await vendorTypeRequest.index();
      print("WelcomeViewModel: Loaded ${vendorTypes.length} vendor types");
      // Set the first vendor type as default to prevent null check errors
      if (vendorTypes.isNotEmpty) {
        vendorType = vendorTypes.first;
        print(
          "WelcomeViewModel: Set vendor type to: ${vendorType?.name} (ID: ${vendorType?.id})",
        );
      } else {
        print("WelcomeViewModel: No vendor types available");
      }
      clearErrors();
    } catch (error) {
      print("WelcomeViewModel: Error loading vendor types: $error");
      setError(error);
    }
    setBusy(false);
  }

  openFeaturedVendors() async {
    Navigator.of(
      viewContext,
    ).push(MaterialPageRoute(builder: (context) => FeaturedVendorsPage()));
  }

  // Method to change vendor type
  changeVendorType(VendorType newVendorType) {
    vendorType = newVendorType;
    notifyListeners();
  }

  // Get current vendor type with fallback
  VendorType? get currentVendorType {
    return vendorType ?? (vendorTypes.isNotEmpty ? vendorTypes.first : null);
  }
}
