import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/models/delivery_address.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/services/local_storage.service.dart';
import 'package:fuodz/widgets/bottomsheets/location_permission.bottomsheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
// import 'package:geocoder/geocoder.dart';
import 'package:rxdart/rxdart.dart';
import 'geocoder.service.dart';

class LocationService {
  //
  static Location location = new Location();

  static bool? serviceEnabled;
  static PermissionStatus? _permissionGranted;
  static LocationData? _locationData;
  static Address? currenctAddress;
  static DeliveryAddress? deliveryaddress;
  static StreamSubscription? currentLocationListener;

  // Track geocoding errors to prevent repeated failed calls
  static bool _geocodingFailed = false;
  static DateTime? _lastGeocodingAttempt;

  //
  static PublishSubject<Address> currenctAddressSubject =
      PublishSubject<Address>();
  // stream for delivery address
  static PublishSubject<DeliveryAddress> currenctDeliveryAddressSubject =
      PublishSubject<DeliveryAddress>();
  // static Stream<Address> get currenctAddressStream =>
  //     _currenctAddressSubject.stream;

  static Future<void> prepareLocationListener([bool oneTime = false]) async {
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      //
      bool requestPermission = true;
      if (!Platform.isIOS) {
        requestPermission = await showRequestDialog();
      }
      if (requestPermission) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }
    }

    serviceEnabled = await location.serviceEnabled();
    if (serviceEnabled == null || serviceEnabled! == false) {
      serviceEnabled = await location.requestService();
      if (serviceEnabled == null || serviceEnabled! == false) {
        return;
      }
    }

    _startLocationListner(oneTime);
  }

  // Safer version that doesn't throw exceptions
  static Future<bool> prepareLocationListenerSafely([
    bool oneTime = false,
  ]) async {
    try {
      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        //
        bool requestPermission = true;
        if (!Platform.isIOS) {
          requestPermission = await showRequestDialog();
        }
        if (requestPermission) {
          _permissionGranted = await location.requestPermission();
          if (_permissionGranted != PermissionStatus.granted) {
            return false;
          }
        } else {
          return false;
        }
      }

      serviceEnabled = await location.serviceEnabled();
      if (serviceEnabled == null || serviceEnabled! == false) {
        serviceEnabled = await location.requestService();
        if (serviceEnabled == null || serviceEnabled! == false) {
          return false;
        }
      }

      _startLocationListner(oneTime);
      return true;
    } catch (error) {
      print("Error preparing location listener: $error");
      return false;
    }
  }

  static Future<bool> showRequestDialog() async {
    var requestResult = false;
    final ctx = AppService().currentContext;
    if (ctx == null || !ctx.mounted) {
      // Context not ready; skip showing dialog for now
      return false;
    }
    await showDialog(
      context: ctx,
      builder: (context) {
        return LocationPermissionDialog(
          onResult: (result) {
            requestResult = result;
          },
        );
      },
    );
    return requestResult;
  }

  static void _startLocationListner([bool oneTime = false]) async {
    //
    //update location every 100meters
    // await location.changeSettings(distanceFilter: 50);
    // //listen
    // currentLocationListener =
    //     location.onLocationChanged.listen((LocationData currentLocation) {
    //   // Use current location
    //   _locationData = currentLocation;
    //   //
    //   geocodeCurrentLocation(true);
    // });

    //listen
    currentLocationListener = Geolocator.getPositionStream().listen((
      Position currentLocation,
    ) {
      // Use current location
      _locationData = LocationData.fromMap(currentLocation.toJson());
      //
      geocodeCurrentLocation(true);
    });

    //get the current location on send to listeners
    try {
      _locationData = await location.getLocation();
      geocodeCurrentLocation(oneTime);
    } catch (error) {
      print("Error getting initial location: $error");
      // Try to use last known position as fallback
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _locationData = LocationData.fromMap(lastKnown.toJson());
          geocodeCurrentLocation(oneTime);
        }
      } catch (fallbackError) {
        print("Error getting fallback location: $fallbackError");
      }
    }
  }

  //
  static Future<void> geocodeCurrentLocation([
    bool closeListener = false,
  ]) async {
    // Prevent repeated geocoding calls if previous attempts failed
    if (_geocodingFailed) {
      // Allow retry after 30 seconds (reduced from 1 minute)
      if (_lastGeocodingAttempt != null &&
          DateTime.now().difference(_lastGeocodingAttempt!) <
              Duration(seconds: 30)) {
        print("Skipping geocoding due to recent failure");
        return;
      }
    }

    if (_locationData != null) {
      final coordinates = new Coordinates(
        _locationData?.latitude ?? 0.0,
        _locationData?.longitude ?? 0.0,
      );

      try {
        //
        final addresses = await GeocoderService().findAddressesFromCoordinates(
          coordinates,
        );
        //
        // Check if addresses list is not empty before accessing first element
        if (addresses.isNotEmpty) {
          currenctAddress = addresses.first;
          //
          if (currenctAddress != null) {
            currenctAddressSubject.add(currenctAddress!);
            //set and save for next time
            final mDeliveryaddress = DeliveryAddress(
              name: currenctAddress!.featureName ?? "Unknown Location",
              address: currenctAddress!.addressLine ?? "Unknown Address",
              latitude: currenctAddress!.coordinates?.latitude,
              longitude: currenctAddress!.coordinates?.longitude,
            );
            if (deliveryaddress == null) {
              saveSelectedAddressLocally(mDeliveryaddress);
            }
          }
          // Reset failure tracking on success
          _geocodingFailed = false;
          _lastGeocodingAttempt = null;
        } else {
          print(
            "No addresses found for coordinates: ${coordinates.latitude},${coordinates.longitude}",
          );
          // Create a fallback address even when geocoding returns empty results
          currenctAddress = Address(
            coordinates: coordinates,
            addressLine: "Unknown address",
            featureName: "Unknown location",
          );
          currenctAddressSubject.add(currenctAddress!);

          // Don't mark as failed for empty results, but still provide fallback
          _geocodingFailed = false;
          _lastGeocodingAttempt = null;
        }
      } catch (error) {
        print("Error get location ==> $error");
        // Create a fallback address even when geocoding fails
        final fallbackAddress = Address(
          coordinates: coordinates,
          addressLine: "Unknown address",
          featureName: "Unknown location",
        );
        currenctAddress = fallbackAddress;
        currenctAddressSubject.add(currenctAddress!);

        // Track geocoding failure to prevent repeated calls
        _geocodingFailed = true;
        _lastGeocodingAttempt = DateTime.now();
      }
    }

    //
    if (closeListener) {
      print("Location listener closed");
      currentLocationListener?.cancel();
    }
  }

  //coordinates to address
  static Future<Address?> addressFromCoordinates({
    required double lat,
    required double lng,
  }) async {
    // Prevent repeated geocoding calls if previous attempts failed
    if (_geocodingFailed) {
      // Allow retry after 30 seconds (reduced from 1 minute)
      if (_lastGeocodingAttempt != null &&
          DateTime.now().difference(_lastGeocodingAttempt!) <
              Duration(seconds: 30)) {
        print("Skipping geocoding due to recent failure");
        // Return a basic address object
        return Address(
          coordinates: Coordinates(lat, lng),
          addressLine: "Unknown address",
          featureName: "Unknown location",
        );
      }
    }

    Address? address;
    final coordinates = new Coordinates(lat, lng);

    try {
      //
      final addresses = await GeocoderService().findAddressesFromCoordinates(
        coordinates,
      );
      //
      if (addresses.isNotEmpty) {
        address = addresses.first;
        // Reset failure tracking on success
        _geocodingFailed = false;
        _lastGeocodingAttempt = null;
      } else {
        print("No addresses found for coordinates: $lat,$lng");
        // Don't mark as failed for empty results, just return a basic address object
        _geocodingFailed = false;
        _lastGeocodingAttempt = null;
        // Return a basic address object even if geocoding returns empty results
        address = Address(
          coordinates: coordinates,
          addressLine: "Unknown address",
          featureName: "Unknown location",
        );
      }
    } catch (error) {
      print("Issue with addressFromCoordinates ==> $error");
      // Track geocoding failure to prevent repeated calls
      _geocodingFailed = true;
      _lastGeocodingAttempt = DateTime.now();
      // Return a basic address object even if geocoding fails
      address = Address(
        coordinates: coordinates,
        addressLine: "Unknown address",
        featureName: "Unknown location",
      );
    }
    return address;
  }

  //Helper methods

  //get current lat
  static double? get cLat {
    return LocationService.currenctAddress?.coordinates?.latitude;
  }

  //get current lng
  static double? get cLng {
    return LocationService.currenctAddress?.coordinates?.longitude;
  }

  //
  static saveSelectedAddressLocally(DeliveryAddress? mDeliveryaddress) async {
    deliveryaddress = mDeliveryaddress;
    if (mDeliveryaddress != null) {
      final pref = await LocalStorageService.getPrefs();
      await pref.setString(
        "LOCAL_ADDRESS",
        jsonEncode(mDeliveryaddress.toJson()),
      );
      //
      currenctDeliveryAddressSubject.add(mDeliveryaddress);
      //address
      final mAddress = Address(
        coordinates: Coordinates(
          mDeliveryaddress.latLng.latitude,
          mDeliveryaddress.latLng.longitude,
        ),
        addressLine: mDeliveryaddress.address,
        featureName: mDeliveryaddress.name,
        adminArea: mDeliveryaddress.state,
        subAdminArea: mDeliveryaddress.city,
        countryName: mDeliveryaddress.country,
      );
      currenctAddressSubject.add(mAddress);
    }
  }

  //
  static Future<DeliveryAddress?> getLocallySaveAddress() async {
    final pref = await LocalStorageService.getPrefs();
    final rawData = pref.getString("LOCAL_ADDRESS");
    if (rawData != null && rawData.isNotNullOrBlank) {
      return DeliveryAddress.fromJson(jsonDecode(rawData));
    }
    return null;
  }

  //MISC.
  static Future<double?> getFetchByLocationLat() async {
    final address = await getLocallySaveAddress();
    return address?.latitude ??
        LocationService.currenctAddress?.coordinates?.latitude;
  }

  static Future<double?> getFetchByLocationLng() async {
    final address = await getLocallySaveAddress();
    return address?.longitude ??
        LocationService.currenctAddress?.coordinates?.longitude;
  }
}
