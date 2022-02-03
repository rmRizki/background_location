import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:background_location/common/helper.dart';
import 'package:background_location/data/models/location.dart';
import 'package:background_locator/location_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationServiceRepository {
  static final LocationServiceRepository _instance =
      LocationServiceRepository._();

  LocationServiceRepository._();

  factory LocationServiceRepository() {
    return _instance;
  }

  static const String isolateName = 'LocatorIsolate';

  final _locationStringList = <String>[];

  Future<void> init(Map<dynamic, dynamic> params) async {
    debugPrint("***********Init callback handler");
    debugPrint("${_locationStringList.length}");
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> dispose() async {
    debugPrint("***********Dispose callback handler");
    debugPrint("${_locationStringList.length}");
    _locationStringList.clear();
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> callback(LocationDto locationDto) async {
    debugPrint(
      '${_locationStringList.length} location in dart: ${locationDto.toString()}',
    );
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);

    final location = LocationModel(
      locationDto,
      Helper.formatDateLog(DateTime.now()),
    );

    _locationStringList.add(jsonEncode(location.toJson()));

    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setStringList('location', _locationStringList);

    send?.send(location);
  }
}
