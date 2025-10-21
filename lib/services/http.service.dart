import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_http_cache_lts/dio_http_cache_lts.dart';
import 'package:fuodz/constants/api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
// import 'package:fuodz/services/app.service.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart';
// import 'package:supercharged/supercharged.dart';

import 'auth.service.dart';
import 'local_storage.service.dart';

class HttpService {
  String host = Api.baseUrl;
  BaseOptions? baseOptions;
  Dio? dio;
  SharedPreferences? prefs;

  // Cache headers for a short period to avoid repeated heavy operations
  Map<String, String>? _cachedHeaders;
  DateTime? _lastHeaderUpdate;
  static const Duration _headerCacheDuration = Duration(minutes: 5);

  // Track geocoding errors to prevent repeated failed calls
  static bool _geocodingFailed = false;
  static DateTime? _lastGeocodingAttempt;

  Future<Map<String, String>> getHeaders() async {
    // Return cached headers if still valid
    if (_cachedHeaders != null &&
        _lastHeaderUpdate != null &&
        DateTime.now().difference(_lastHeaderUpdate!) < _headerCacheDuration) {
      return _cachedHeaders!;
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    // Get location in background, don't block the request
    double? cLat;
    double? cLng;

    try {
      // Prevent repeated geocoding calls if previous attempts failed
      if (!_geocodingFailed ||
          (_lastGeocodingAttempt != null &&
              DateTime.now().difference(_lastGeocodingAttempt!) >
                  Duration(minutes: 5))) {
        // Use cached location or get last known position (faster)
        final cLoc = await Geolocator.getLastKnownPosition();
        cLat = cLoc?.latitude;
        cLng = cLoc?.longitude;

        // Reset failure tracking on success
        _geocodingFailed = false;
      } else {
        print("Skipping location update due to recent geocoding failure");
      }
    } catch (error) {
      print("Location error (non-blocking): $error");
      // Track geocoding failure to prevent repeated calls
      _geocodingFailed = true;
      _lastGeocodingAttempt = DateTime.now();
      // Don't block the request if location fails
    }

    final userToken = await AuthServices.getAuthBearerToken();

    _cachedHeaders = {
      HttpHeaders.acceptHeader: "application/json",
      HttpHeaders.authorizationHeader: "Bearer $userToken",
      "lang": translator.activeLocale.languageCode,
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'Expires': '0',
      'App-Version': packageInfo.buildNumber,
      'App-Type': 'customer',
      'c-lat': "$cLat",
      'c-lng': "$cLng",
    };

    _lastHeaderUpdate = DateTime.now();
    return _cachedHeaders!;
  }

  HttpService() {
    LocalStorageService.getPrefs();

    baseOptions = new BaseOptions(
      baseUrl: host,
      connectTimeout: Duration(seconds: 30), // ✅ Add connection timeout
      receiveTimeout: Duration(seconds: 30), // ✅ Add receive timeout
      sendTimeout: Duration(seconds: 30), // ✅ Add send timeout
      validateStatus: (status) {
        return status != null && status <= 500;
      },
    );

    dio = new Dio(baseOptions);

    // Add request/response interceptors for debugging
    if (kDebugMode) {
      dio!.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => print('HTTP: $object'),
        ),
      );
    }

    // Add cache manager only for GET requests
    dio!.interceptors.add(getCacheManager().interceptor);
  }

  DioCacheManager getCacheManager() {
    return DioCacheManager(
      CacheConfig(baseUrl: host, defaultMaxAge: Duration(hours: 1)),
    );
  }

  // Add network performance monitoring
  void _logNetworkPerformance(
    String endpoint,
    DateTime startTime,
    DateTime endTime,
  ) {
    final duration = endTime.difference(startTime);
    print("API Performance: $endpoint took ${duration.inMilliseconds}ms");

    if (duration.inSeconds > 5) {
      print("⚠️ SLOW API CALL: $endpoint took ${duration.inSeconds}s");
    }
  }

  //for get api calls
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    bool includeHeaders = true,
  }) async {
    //preparing the api uri/url
    String uri = "$host$url";

    //preparing the post options if header is required
    final mOptions =
        !includeHeaders ? null : Options(headers: await getHeaders());

    Response response;
    final startTime = DateTime.now();

    try {
      response = await dio!.get(
        uri,
        options: mOptions,
        queryParameters: queryParameters,
      );
      _logNetworkPerformance(url, startTime, DateTime.now());
    } on DioError catch (error) {
      _logNetworkPerformance(url, startTime, DateTime.now());
      response = formatDioExecption(error);
    }

    return response;
  }

  //for post api calls
  Future<Response> post(String url, body, {bool includeHeaders = true}) async {
    //preparing the api uri/url
    String uri = "$host$url";

    //preparing the post options if header is required
    final mOptions =
        !includeHeaders ? null : Options(headers: await getHeaders());

    Response response;
    final startTime = DateTime.now();
    try {
      response = await dio!.post(uri, data: body, options: mOptions);
      _logNetworkPerformance(url, startTime, DateTime.now());
    } on DioError catch (error) {
      _logNetworkPerformance(url, startTime, DateTime.now());
      response = formatDioExecption(error);
    }

    return response;
  }

  //for post api calls with file upload
  Future<Response> postWithFiles(
    String url,
    body, {
    bool includeHeaders = true,
  }) async {
    //preparing the api uri/url
    String uri = "$host$url";
    //preparing the post options if header is required
    final mOptions =
        !includeHeaders ? null : Options(headers: await getHeaders());

    Response response;
    final startTime = DateTime.now();
    try {
      response = await dio!.post(
        uri,
        data: body is FormData ? body : FormData.fromMap(body),
        options: mOptions,
      );
      _logNetworkPerformance(url, startTime, DateTime.now());
    } on DioError catch (error) {
      _logNetworkPerformance(url, startTime, DateTime.now());
      response = formatDioExecption(error);
    }

    return response;
  }

  //for patch api calls
  Future<Response> patch(String url, Map<String, dynamic> body) async {
    String uri = "$host$url";
    Response response;
    final startTime = DateTime.now();

    try {
      response = await dio!.patch(
        uri,
        data: body,
        options: Options(headers: await getHeaders()),
      );
      _logNetworkPerformance(url, startTime, DateTime.now());
    } on DioError catch (error) {
      _logNetworkPerformance(url, startTime, DateTime.now());
      response = formatDioExecption(error);
    }

    return response;
  }

  //for delete api calls
  Future<Response> delete(String url) async {
    String uri = "$host$url";

    Response response;
    final startTime = DateTime.now();
    try {
      response = await dio!.delete(
        uri,
        options: Options(headers: await getHeaders()),
      );
      _logNetworkPerformance(url, startTime, DateTime.now());
    } on DioError catch (error) {
      _logNetworkPerformance(url, startTime, DateTime.now());
      response = formatDioExecption(error);
    }
    return response;
  }

  Response formatDioExecption(DioError ex) {
    var response = Response(requestOptions: ex.requestOptions);
    print("type ==> ${ex.type}");
    response.statusCode = 400;
    String? msg = response.statusMessage;

    try {
      if (ex.type == DioErrorType.connectionTimeout) {
        msg =
            "Connection timeout. Please check your internet connection and try again"
                .tr();
      } else if (ex.type == DioErrorType.sendTimeout) {
        msg =
            "Timeout. Please check your internet connection and try again".tr();
      } else if (ex.type == DioErrorType.receiveTimeout) {
        msg =
            "Timeout. Please check your internet connection and try again".tr();
      } else if (ex.type == DioErrorType.connectionTimeout) {
        msg =
            "Connection timeout. Please check your internet connection and try again"
                .tr();
      } else {
        msg = "Please check your internet connection and try again".tr();
      }
      response.data = {"message": msg};
    } catch (error) {
      response.statusCode = 400;
      msg = "Please check your internet connection and try again".tr();
      response.data = {"message": msg};
    }

    throw msg;
  }

  //NEUTRALS
  Future<Response> getExternal(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio!.get(url, queryParameters: queryParameters);
  }
}
