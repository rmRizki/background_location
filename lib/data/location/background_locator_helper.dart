import 'package:background_location/data/location/location_callback_handler.dart';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundLocatorHelper {
  static BackgroundLocatorHelper? _backgroundLocatorHelper;
  BackgroundLocatorHelper._instance() {
    _backgroundLocatorHelper = this;
  }

  factory BackgroundLocatorHelper() =>
      _backgroundLocatorHelper ?? BackgroundLocatorHelper._instance();

  Future<bool> checkLocationPermission() async {
    final access = await Permission.locationAlways.status;
    debugPrint('Location Permission : $access');
    switch (access) {
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        final permission = await Permission.locationWhenInUse.request();
        if (permission == PermissionStatus.granted) {
          final permissionAlways = await Permission.locationAlways.request();
          if (permissionAlways == PermissionStatus.granted) {
            debugPrint('Location always granted');
            return true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      case PermissionStatus.granted:
        return true;
      default:
        return false;
    }
  }

  Future<void> initialize() async {
    await BackgroundLocator.initialize();
  }

  Future<bool> isServiceRunning() async {
    return await BackgroundLocator.isServiceRunning();
  }

  Future<void> unRegisterLocationUpdate() async {
    await BackgroundLocator.unRegisterLocationUpdate();
  }

  Future<void> updateNotificationText(LocationDto? data) async {
    if (data == null) {
      return;
    }

    await BackgroundLocator.updateNotificationText(
        title: "new location received",
        msg: "${DateTime.now()}",
        bigMsg: "${data.latitude}, ${data.longitude}");
  }

  Future<void> startLocator({int? interval}) async {
    Map<String, dynamic> data = {'countInit': 1};
    return await BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      initDataCallback: data,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      iosSettings: const IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 2,
        showsBackgroundLocationIndicator: true,
      ),
      autoStop: false,
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: interval ?? 5,
        distanceFilter: 2,
        client: LocationClient.google,
        androidNotificationSettings: const AndroidNotificationSettings(
          notificationChannelName: 'Location tracking',
          notificationTitle: 'Start Location Tracking',
          notificationMsg: 'Track location in background',
          notificationBigMsg:
              'Background location is on to keep the app up-tp-date with your location. This is required for main features to work properly when the app is not running.',
          notificationIconColor: Colors.grey,
          notificationTapCallback: LocationCallbackHandler.notificationCallback,
        ),
      ),
    );
  }
}
