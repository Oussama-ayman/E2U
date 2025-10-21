import 'package:fuodz/constants/api.dart';
import 'package:fuodz/constants/app_map_settings.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/address.dart';
import 'package:fuodz/models/api_response.dart';
import 'package:fuodz/models/coordinates.dart';
import 'package:fuodz/services/http.service.dart';
import 'package:fuodz/services/location.service.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:singleton/singleton.dart';

export 'package:fuodz/models/address.dart';
export 'package:fuodz/models/coordinates.dart';

class GeocoderService extends HttpService {
  //
  /// Factory method that reuse same instance automatically
  factory GeocoderService() => Singleton.lazy(() => GeocoderService._());

  /// Private constructor
  GeocoderService._() {}

  // Track geocoding errors to prevent repeated failed calls
  static bool _geocodingFailed = false;
  static DateTime? _lastGeocodingAttempt;

  Future<List<Address>> findAddressesFromCoordinates(
    Coordinates coordinates, {
    int limit = 5,
  }) async {
    // Prevent repeated geocoding calls if previous attempts failed
    if (_geocodingFailed) {
      // Allow retry after 30 seconds (reduced from 5 minutes)
      if (_lastGeocodingAttempt != null &&
          DateTime.now().difference(_lastGeocodingAttempt!) <
              Duration(seconds: 30)) {
        print("Skipping geocoding due to recent failure");
        return [];
      }
    }

    //use backend api
    if (!AppMapSettings.useGoogleOnApp) {
      try {
        final apiresult = await get(
          Api.geocoderForward,
          queryParameters: {
            "lat": coordinates.latitude,
            "lng": coordinates.longitude,
            "limit": limit,
          },
        );

        //
        final apiResponse = ApiResponse.fromResponse(apiresult);
        if (apiResponse.allGood) {
          // Check if data is not empty and is a list before processing
          if (apiResponse.data != null &&
              apiResponse.data is List &&
              (apiResponse.data as List).isNotEmpty) {
            // Reset failure tracking when we get valid data
            _geocodingFailed = false;
            _lastGeocodingAttempt = null;

            return (apiResponse.data).map((e) {
              // return Address().fromServerMap(e);
              Address address;
              try {
                address = Address().fromMap(e);
              } catch (error) {
                address = Address().fromServerMap(e);
              }
              return address;
            }).toList();
          } else {
            print(
              "No geocoding data found for coordinates: ${coordinates.latitude},${coordinates.longitude}",
            );
            // Don't mark as failed for empty results, just return empty list
            // Reset failure tracking since we got a successful response from the API
            _geocodingFailed = false;
            _lastGeocodingAttempt = null;
            return [];
          }
        }

        // Only mark as failed for actual API errors
        print("Geocoding API error: ${apiResponse.message}");
        _geocodingFailed = true;
        _lastGeocodingAttempt = DateTime.now();
        return [];
      } catch (error) {
        print("Error in backend geocoding: $error");
        // Track geocoding failure to prevent repeated calls
        _geocodingFailed = true;
        _lastGeocodingAttempt = DateTime.now();
        return [];
      }
    }
    //use in-app geocoding
    try {
      final apiKey = AppStrings.googleMapApiKey;
      // Check if API key is available
      if (apiKey.isEmpty) {
        print("Google Maps API key is missing");
        // Track geocoding failure to prevent repeated calls
        _geocodingFailed = true;
        _lastGeocodingAttempt = DateTime.now();
        return [];
      }

      String url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${coordinates.toString()};key=$apiKey&radius=200";

      final apiResult = await get(
        Api.externalRedirect,
        queryParameters: {"endpoint": url},
      );

      final apiResponse = ApiResponse.fromResponse(apiResult);

      //
      if (apiResponse.allGood) {
        Map<String, dynamic> apiResponseData = apiResponse.body;
        // Check if results exist
        if (apiResponseData["results"] == null ||
            (apiResponseData["results"] as List).isEmpty) {
          print(
            "No geocoding results found for coordinates: ${coordinates.latitude},${coordinates.longitude}",
          );
          // Don't mark as failed for empty results, just return empty list
          // Reset failure tracking since we got a successful response from the API
          _geocodingFailed = false;
          _lastGeocodingAttempt = null;
          return [];
        }

        // Reset failure tracking on success
        _geocodingFailed = false;
        _lastGeocodingAttempt = null;

        return (apiResponseData["results"] as List).map((e) {
          try {
            return Address().fromMap(e);
          } catch (error) {
            return Address().fromServerMap(e);
          }
        }).toList();
      } else {
        print("Geocoding API error: ${apiResponse.message}");
        // Track geocoding failure to prevent repeated calls
        _geocodingFailed = true;
        _lastGeocodingAttempt = DateTime.now();
        return [];
      }
    } catch (error) {
      print("Error in Google Maps geocoding: $error");
      // Track geocoding failure to prevent repeated calls
      _geocodingFailed = true;
      _lastGeocodingAttempt = DateTime.now();
      return [];
    }
  }

  Future<List<Address>> findAddressesFromQuery(String address) async {
    // Prevent repeated geocoding calls if previous attempts failed
    if (_geocodingFailed) {
      // Allow retry after 30 seconds (reduced from 5 minutes)
      if (_lastGeocodingAttempt != null &&
          DateTime.now().difference(_lastGeocodingAttempt!) <
              Duration(seconds: 30)) {
        print("Skipping geocoding due to recent failure");
        return [];
      }
    }

    //use in-app geocoding
    String myLatLng = "";
    if (LocationService.currenctAddress != null) {
      myLatLng = "${LocationService.currenctAddress?.coordinates?.latitude},";
      myLatLng += "${LocationService.currenctAddress?.coordinates?.longitude}";
    }

    //get current device region
    String? region;
    try {
      region = await Utils.getCurrentCountryCode();
    } catch (error) {
      region = "";
    }

    //use backend api
    if (!AppMapSettings.useGoogleOnApp) {
      try {
        final apiresult = await get(
          Api.geocoderReserve,
          queryParameters: {
            "keyword": address,
            "location": myLatLng,
            "region": region,
          },
        );

        //
        final apiResponse = ApiResponse.fromResponse(apiresult);
        if (apiResponse.allGood) {
          return (apiResponse.data).map((e) {
            Address address;
            try {
              address = Address().fromMap(e);
            } catch (error) {
              address = Address().fromServerMap(e);
            }
            address.gMapPlaceId = e["place_id"] ?? "";
            return address;
          }).toList();
        }

        return [];
      } catch (error) {
        print("Error in backend reverse geocoding: $error");
        // Track geocoding failure to prevent repeated calls
        _geocodingFailed = true;
        _lastGeocodingAttempt = DateTime.now();
        return [];
      }
    }

    //use in-app geocoding
    try {
      final apiKey = AppStrings.googleMapApiKey;
      // Check if API key is available
      if (apiKey.isEmpty) {
        print("Google Maps API key is missing");
        // Track geocoding failure to prevent repeated calls
        _geocodingFailed = true;
        _lastGeocodingAttempt = DateTime.now();
        return [];
      }

      address = address.replaceAll(" ", "+");
      String url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$address;key=$apiKey;location=$myLatLng;region=$region;radius=200";
      final result = await get(
        Api.externalRedirect,
        queryParameters: {"endpoint": url},
      );

      final apiResult = ApiResponse.fromResponse(result);

      //
      if (apiResult.allGood) {
        //
        Map<String, dynamic> apiResponse = apiResult.body;
        // Reset failure tracking on success
        _geocodingFailed = false;
        return (apiResponse["predictions"] as List).map((e) {
          Address address;
          try {
            address = Address().fromMap(e);
          } catch (error) {
            address = Address().fromServerMap(e);
          }
          address.gMapPlaceId = e["place_id"];
          return address;
        }).toList();
      } else {
        print("Reverse geocoding API error: ${apiResult.message}");
        // Track geocoding failure to prevent repeated calls
        _geocodingFailed = true;
        _lastGeocodingAttempt = DateTime.now();
        return [];
      }
    } catch (error) {
      print("Error in Google Maps reverse geocoding: $error");
      // Track geocoding failure to prevent repeated calls
      _geocodingFailed = true;
      _lastGeocodingAttempt = DateTime.now();
      return [];
    }
  }

  Future<Address> fecthPlaceDetails(Address address) async {
    //use backend api
    if (!AppMapSettings.useGoogleOnApp) {
      try {
        final apiresult = await get(
          Api.geocoderPlaceDetails,
          queryParameters: {"place_id": address.gMapPlaceId, "plain": true},
        );

        //
        final apiResponse = ApiResponse.fromResponse(apiresult);
        if (apiResponse.allGood) {
          return Address().fromPlaceDetailsMap(apiResponse.body as Map);
        }

        return address;
      } catch (error) {
        print("Error in backend place details: $error");
        return address;
      }
    }

    //use in-app geocoding
    try {
      final apiKey = AppStrings.googleMapApiKey;
      // Check if API key is available
      if (apiKey.isEmpty) {
        print("Google Maps API key is missing");
        return address;
      }

      String url =
          "https://maps.googleapis.com/maps/api/place/details/json?fields=address_component,formatted_address,name,geometry;place_id=${address.gMapPlaceId};key=$apiKey";
      final result = await get(
        Api.externalRedirect,
        queryParameters: {"endpoint": url},
      );
      final apiResult = ApiResponse.fromResponse(result);

      //
      if (apiResult.allGood) {
        Map<String, dynamic> apiResponse = apiResult.body;
        address = address.fromPlaceDetailsMap(apiResponse["result"]);
        return address;
      }
      throw "Failed".tr();
    } catch (error) {
      print("Error in Google Maps place details: $error");
      throw "Failed".tr();
    }
  }
}
