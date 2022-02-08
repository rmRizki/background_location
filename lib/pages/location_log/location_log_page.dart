import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_location/common/helper.dart';
import 'package:background_location/data/location/location_callback_handler.dart';
import 'package:background_location/data/location/location_service_repository.dart';
import 'package:background_location/data/models/location.dart';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationLogPage extends StatefulWidget {
  const LocationLogPage({Key? key}) : super(key: key);

  @override
  _LocationLogPageState createState() => _LocationLogPageState();
}

class _LocationLogPageState extends State<LocationLogPage> {
  final ReceivePort _port = ReceivePort();

  bool _isRunning = false;
  LocationDto? _lastLocation;
  final List<LocationModel> _locationList = [];
  int? _locationUpdateInterval = 5;
  SharedPreferences? _sharedPreferences;

  @override
  void initState() {
    super.initState();

    if (IsolateNameServer.lookupPortByName(
            LocationServiceRepository.isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(
          LocationServiceRepository.isolateName);
    }

    IsolateNameServer.registerPortWithName(
        _port.sendPort, LocationServiceRepository.isolateName);

    _port.listen(
      (dynamic data) async {
        await _updateUI(data);
      },
    );
    _initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateUI(LocationModel? location) async {
    await _updateNotificationText(location?.locationDto);
    setState(() {
      if (location != null) {
        _lastLocation = location.locationDto;
        _locationList.add(
          location,
        );
      }
    });
  }

  Future<void> _updateNotificationText(LocationDto? data) async {
    if (data == null) {
      return;
    }

    await BackgroundLocator.updateNotificationText(
        title: "new location received",
        msg: "${DateTime.now()}",
        bigMsg: "${data.latitude}, ${data.longitude}");
  }

  Future<void> _initPlatformState() async {
    debugPrint('Initializing...');
    await BackgroundLocator.initialize();
    _sharedPreferences = await SharedPreferences.getInstance();
    final encodedLocationList =
        _sharedPreferences?.getStringList('location') ?? [];
    if (encodedLocationList.isNotEmpty) {
      _locationList.clear();
      _locationList.addAll(
        encodedLocationList.map((e) => LocationModel.fromJson(jsonDecode(e))),
      );
    }

    debugPrint('Initialization done');
    final isServiceRunning = await BackgroundLocator.isServiceRunning();
    setState(() {
      _isRunning = isServiceRunning;
    });
    debugPrint('Running ${_isRunning.toString()}');
  }

  void _onStop() async {
    await BackgroundLocator.unRegisterLocationUpdate();
    final isServiceRunning = await BackgroundLocator.isServiceRunning();
    setState(() {
      _isRunning = isServiceRunning;
    });
  }

  void _onStart() async {
    if (_isRunning) return;
    if (await _checkLocationPermission()) {
      if (Platform.isAndroid) {
        final result = await _showInputIntervalDialog(context);
        if (result != null && result) {
          await _startLocator();
        }
      } else {
        await _startLocator();
      }
      final isServiceRunning = await BackgroundLocator.isServiceRunning();
      setState(() {
        _locationList.clear();
        _isRunning = isServiceRunning;
        _lastLocation = null;
      });
    } else {
      debugPrint('Error check permission');
    }
  }

  Future<bool> _checkLocationPermission() async {
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

  Future<void> _startLocator() async {
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
        interval: _locationUpdateInterval ?? 5,
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

  Future<bool?> _showInputIntervalDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Set location request interval'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  _locationUpdateInterval = int.tryParse(value);
                });
              },
              decoration: const InputDecoration(
                hintText: "Interval in seconds (ex: 5)",
              ),
              keyboardType: TextInputType.number,
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    String msgStatus = "-";
    if (_isRunning) {
      msgStatus = 'Is running';
    } else {
      msgStatus = 'Is not running';
    }
    String lastCoordinate = '';
    if (_lastLocation != null) {
      lastCoordinate =
          "Last Location = lat: ${_lastLocation?.latitude}, long: ${_lastLocation?.longitude}";
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Locator'),
      ),
      body: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          primary: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildTextInfo(
                'You need to enable Location Permission : Allow all the time to have access for this app',
              ),
              _buildButton(label: 'Start', onPressed: () => _onStart()),
              if (_isRunning)
                _buildButton(label: 'Stop', onPressed: () => _onStop()),
              if (!_isRunning)
                _buildButton(
                  label: 'Clear Log',
                  onPressed: () async {
                    await _sharedPreferences?.clear();
                    setState(() {
                      _locationList.clear();
                    });
                  },
                ),
              _buildTextInfo('Status: $msgStatus'),
              _buildTextInfo(lastCoordinate),
              const SizedBox(height: 8),
              _buildLocationList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInfo(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.maxFinite,
      child: ElevatedButton(
        child: Text(label),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLocationList() {
    return ListView.builder(
      itemBuilder: (context, index) {
        return _buildLocationItem(_locationList[index]);
      },
      itemCount: _locationList.length,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      reverse: true,
    );
  }

  Widget _buildLocationItem(LocationModel locationModel) {
    final labelText = Helper.setLogPosition(locationModel);
    final latitude = locationModel.locationDto.latitude;
    final longitude = locationModel.locationDto.longitude;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.black12,
      child: ListTile(
        dense: true,
        title: Text(labelText, style: Theme.of(context).textTheme.bodyText2),
        onTap: () async {
          if (await MapLauncher.isMapAvailable(MapType.google) ?? false) {
            await MapLauncher.showMarker(
              mapType: MapType.google,
              coords: Coords(latitude, longitude),
              title: "Detected Location",
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to open map',
                ),
              ),
            );
          }
        },
        trailing: const Icon(Icons.call_made_sharp, size: 16),
      ),
    );
  }
}
