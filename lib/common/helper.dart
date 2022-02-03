import 'dart:math';

import 'package:background_location/data/models/location.dart';
import 'package:background_locator/location_dto.dart';

class Helper {
  static String setLogPosition(LocationModel data) {
    return '${data.date} --> ${formatLog(data.locationDto)} --- isMocked: ${data.locationDto.isMocked}';
  }

  static double dp(double val, int places) {
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  static String formatDateLog(DateTime date) {
    return date.hour.toString() +
        ":" +
        date.minute.toString() +
        ":" +
        date.second.toString();
  }

  static String formatLog(LocationDto locationDto) {
    return dp(locationDto.latitude, 4).toString() +
        " " +
        dp(locationDto.longitude, 4).toString();
  }
}
