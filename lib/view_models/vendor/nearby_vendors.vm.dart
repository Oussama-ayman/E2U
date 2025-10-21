import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_routes.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/vendor.dart';
import 'package:fuodz/models/vendor_type.dart';
import 'package:fuodz/requests/vendor.request.dart';
import 'package:fuodz/services/geocoder.service.dart';
import 'package:fuodz/services/location.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:velocity_x/velocity_x.dart';

class NearbyVendorsViewModel extends MyBaseViewModel {
  NearbyVendorsViewModel(BuildContext context, this.vendorType) {
    this.viewContext = context;
  }

  //
  List<Vendor> vendors = [];
  VendorType? vendorType;
  int selectedType = 1;
  StreamSubscription<Address>? locationStreamSubscription;

  //
  VendorRequest _vendorRequest = VendorRequest();

  //
  initialise() {
    //
    fetchTopVendors();

    //
    locationStreamSubscription = LocationService.currenctAddressSubject.listen((
      value,
    ) {
      //
      fetchTopVendors();
    });
  }

  //
  fetchTopVendors() async {
    print("NearbyVendorsViewModel: Starting to fetch top vendors");
    print(
      "NearbyVendorsViewModel: vendorType: ${vendorType?.name} (ID: ${vendorType?.id})",
    );

          if (LocationService.currenctAddress?.coordinates?.latitude == null) {
        print("NearbyVendorsViewModel: No location available, fetching without location");
        // Optional: cancel listener to avoid redundant calls
        locationStreamSubscription?.cancel();
        // If vendorType is missing, try generic fetch
        final int? typeId = vendorType?.id;
        setBusy(true);
        try {
          vendors = await _vendorRequest.vendorsRequest(
            byLocation: false,
            params: typeId != null ? {"vendor_type_id": typeId} : {},
          );
          if (selectedType == 2) {
            vendors = vendors.filter((e) => e.pickup == 1).toList();
          } else if (selectedType == 1) {
            vendors = vendors.filter((e) => e.delivery == 1).toList();
          }
          clearErrors();
        } catch (error) {
          setError(error);
        }
        setBusy(false);
        return;
      } else {
        locationStreamSubscription?.cancel();
      }

    // Add null safety check
    if (vendorType?.id == null) {
      print("NearbyVendorsViewModel: vendorType or vendorType.id is null");
      setError("No vendor type available");
      setBusy(false);
      return;
    }

    setBusy(true);
    try {
      print(
        "NearbyVendorsViewModel: Fetching vendors for vendor type ID: ${vendorType?.id}",
      );
      //filter by location if user selects delivery address
      vendors = await _vendorRequest.nearbyVendorsRequest(
        byLocation: AppStrings.enableFatchByLocation,
        params: {"vendor_type_id": vendorType?.id},
      );
      print("NearbyVendorsViewModel: Loaded ${vendors.length} vendors");

      //
      if (selectedType == 2) {
        vendors = vendors.filter((e) => e.pickup == 1).toList();
      } else if (selectedType == 1) {
        vendors = vendors.filter((e) => e.delivery == 1).toList();
      }
      clearErrors();
    } catch (error) {
      setError(error);
    }
    setBusy(false);
  }

  //
  changeType(int type) {
    selectedType = type;
    fetchTopVendors();
  }

  vendorSelected(Vendor vendor) async {
    Navigator.of(
      viewContext,
    ).pushNamed(AppRoutes.shopDetails, arguments: vendor);
  }
}
