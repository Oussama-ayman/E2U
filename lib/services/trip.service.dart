import 'dart:async';
import 'package:singleton/singleton.dart';

class TripService {
  /// Factory method that reuse same instance automatically
  factory TripService() => Singleton.lazy(() => TripService._());

  /// Private constructor
  TripService._() {}

  Future<int?> generatePossibleDriverETA({
    required double lat,
    required double lng,
    int? vehicleTypeId,
  }) async {
    print("Firebase trip service disabled - returning null ETA");
    return null;
  }

  //MISC.
  static int getPrecision(double km) {
    return 4; // Default precision
  }
}
