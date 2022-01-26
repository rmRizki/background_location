import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_location/helper.dart';
import 'package:background_location/location.dart';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import 'location_callback_handler.dart';
import 'location_service_repository.dart';

/// TODO :
/// 1. tambah settingan untuk atur interval

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ReceivePort _port = ReceivePort();

  bool? _isRunning;
  LocationDto? _lastLocation;
  final List<LocationModel> _locationList = [];

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
    var box = await Hive.openBox('location');
    _locationList.clear();
    _locationList.addAll(
      box.toMap().entries.map(
          (e) => LocationModel.fromJson(Map<String, dynamic>.from(e.value))),
    );
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
    if (await _checkLocationPermission()) {
      await _startLocator();
      final isServiceRunning = await BackgroundLocator.isServiceRunning();

      setState(() {
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
          accuracy: LocationAccuracy.NAVIGATION, distanceFilter: 0),
      autoStop: false,
      androidSettings: const AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 0,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
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

  @override
  Widget build(BuildContext context) {
    const info = Text(
      'You need to enable Location Permission : Allow all the time to have access for this app ',
      textAlign: TextAlign.center,
    );
    final start = SizedBox(
      width: double.maxFinite,
      child: ElevatedButton(
        child: const Text('Start'),
        onPressed: () {
          _onStart();
        },
      ),
    );
    final stop = SizedBox(
      width: double.maxFinite,
      child: ElevatedButton(
        child: const Text('Stop'),
        onPressed: () {
          _onStop();
        },
      ),
    );
    final clear = SizedBox(
      width: double.maxFinite,
      child: ElevatedButton(
        child: const Text('Clear Log'),
        onPressed: () async {
          final box = await Hive.openBox('location');
          box.clear();
          setState(() {
            _locationList.clear();
          });
        },
      ),
    );
    String msgStatus = "-";
    if (_isRunning != null) {
      if (_isRunning!) {
        msgStatus = 'Is running';
      } else {
        msgStatus = 'Is not running';
      }
    }
    final status = Text("Status: $msgStatus");

    String lastCoordinate = '';
    if (_lastLocation != null) {
      lastCoordinate =
          "Last Location = lat: ${_lastLocation?.latitude}, long: ${_lastLocation?.longitude}";
    }
    final lastLocation = Text(lastCoordinate);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter background Locator'),
        ),
        body: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            primary: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                info,
                start,
                stop,
                clear,
                status,
                lastLocation,
                const SizedBox(height: 8),
                ListView.builder(
                  itemBuilder: (context, index) {
                    return _buildLocationItem(_locationList[index]);
                  },
                  itemCount: _locationList.length,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  reverse: true,
                ),
              ],
            ),
          ),
        ),
      ),
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
