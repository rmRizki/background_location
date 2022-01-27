import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:background_location/helper.dart';
import 'package:background_location/location.dart';
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

  int _count = -1;

  SharedPreferences? _sharedPreferences;
  final List<LocationModel> _locationList = [];

  Future<void> init(Map<dynamic, dynamic> params) async {
    debugPrint("***********Init callback handler");
    _sharedPreferences = await SharedPreferences.getInstance();
    final locationJsonString =
        _sharedPreferences?.getStringList('location') ?? [];
    if (locationJsonString.isNotEmpty) {
      _locationList.clear();
      _locationList.addAll(
        locationJsonString.map((e) => LocationModel.fromJson(jsonDecode(e))),
      );
    }
    if (params.containsKey('countInit')) {
      dynamic tmpCount = params['countInit'];
      if (tmpCount is double) {
        _count = tmpCount.toInt();
      } else if (tmpCount is String) {
        _count = int.parse(tmpCount);
      } else if (tmpCount is int) {
        _count = tmpCount;
      } else {
        _count = -2;
      }
    } else {
      _count = 0;
    }
    debugPrint("$_count");
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> dispose() async {
    debugPrint("***********Dispose callback handler");
    debugPrint("$_count");
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> callback(LocationDto locationDto) async {
    debugPrint('$_count location in dart: ${locationDto.toString()}');
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);

    final location = LocationModel(
      locationDto,
      Helper.formatDateLog(DateTime.now()),
    );

    _locationList.add(location);
    _sharedPreferences?.setStringList(
      'location',
      List<String>.from(_locationList.map((e) => jsonEncode(e.toJson()))),
    );

    send?.send(location);
    _count++;
  }
}
