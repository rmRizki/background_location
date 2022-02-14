import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_location/common/constant.dart';
import 'package:background_location/common/helper.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/location/background_locator_helper.dart';
import 'package:background_location/data/location/location_service_repository.dart';
import 'package:background_location/data/models/history.dart';
import 'package:background_location/data/models/location.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:background_location/pages/ticket/open/arrive_detail_ticket_page.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DepartDetailTicketPage extends StatefulWidget {
  const DepartDetailTicketPage({Key? key, required this.ticket})
      : super(key: key);

  final Ticket ticket;

  @override
  _DepartDetailTicketPageState createState() => _DepartDetailTicketPageState();
}

class _DepartDetailTicketPageState extends State<DepartDetailTicketPage> {
  final _port = ReceivePort();
  final _backgroundLocatorHelper = BackgroundLocatorHelper();
  final _databaseHelper = DatabaseHelper();
  LocationModel? _lastLocation;
  final List<LocationModel> _locationList = [];
  SharedPreferences? _sharedPreferences;

  bool _isLocationServiceOn = false;

  @override
  void initState() {
    if (IsolateNameServer.lookupPortByName(
          LocationServiceRepository.isolateName,
        ) !=
        null) {
      IsolateNameServer.removePortNameMapping(
        LocationServiceRepository.isolateName,
      );
    }

    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      LocationServiceRepository.isolateName,
    );

    _port.listen(
      (dynamic data) async {
        await _updateLocationData(data);
      },
    );
    _initPlatformState();
    super.initState();
  }

  Future<void> _updateLocationData(LocationModel? location) async {
    await _backgroundLocatorHelper.updateNotificationText(
      location?.locationDto,
    );
    setState(() {
      if (location != null) {
        _lastLocation = location;
        _locationList.add(location);
      }
    });
  }

  Future<void> _initPlatformState() async {
    await _backgroundLocatorHelper.initialize();
    _sharedPreferences = await SharedPreferences.getInstance();
    final encodedLocationList =
        _sharedPreferences?.getStringList('location') ?? [];
    if (encodedLocationList.isNotEmpty) {
      _locationList.clear();
      _locationList.addAll(
        encodedLocationList.map((e) => LocationModel.fromJson(jsonDecode(e))),
      );
      _lastLocation = _locationList.last;
    }
    final isServiceRunning = await _backgroundLocatorHelper.isServiceRunning();
    setState(() => _isLocationServiceOn = isServiceRunning);
    if (!_isLocationServiceOn) _startLocationService();
  }

  void _startLocationService() async {
    if (_isLocationServiceOn) return;
    if (await _backgroundLocatorHelper.checkLocationPermission()) {
      await _backgroundLocatorHelper.startLocator();
      final isServiceRunning =
          await _backgroundLocatorHelper.isServiceRunning();
      setState(() => _isLocationServiceOn = isServiceRunning);
    } else {
      debugPrint('Error check permission');
    }
  }

  void _stopLocationService() async {
    await _backgroundLocatorHelper.unRegisterLocationUpdate();
    final isServiceRunning = await _backgroundLocatorHelper.isServiceRunning();
    _isLocationServiceOn = isServiceRunning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Detail (Departed)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        primary: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticket.title ?? '-',
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 8),
            Text(
              widget.ticket.description ?? '-',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),
            const Text('Departure Location Log : '),
            const SizedBox(height: 8),
            _locationList.isEmpty
                ? const Text(
                    '-- None, Please Activate Your Location Service --',
                  )
                : _buildLocationLogList(),
            _buildArriveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationLogList() {
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
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

  Widget _buildArriveButton() {
    final ticket = widget.ticket;
    final ticketId = ticket.id;
    if (ticketId == null) return Container();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: !_isLocationServiceOn
            ? null
            : () async {
                try {
                  ticket.arrivalStatus = ArrivalStatus.arrived.name;
                  await _databaseHelper.updateData(
                    TableName.ticket,
                    ticket.toJson(),
                    ticketId,
                  );
                  _databaseHelper.insertData(
                    TableName.history,
                    History(
                      action:
                          'Ticket: ${ticket.title} : ${ticket.arrivalStatus}',
                      latitude: _lastLocation?.locationDto.latitude.toString(),
                      longitude:
                          _lastLocation?.locationDto.longitude.toString(),
                      time: Helper.formatDateLog(DateTime.now()),
                      ticketId: widget.ticket.id,
                    ).toJson(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ticket Updated')),
                  );
                  _stopLocationService();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArriveDetailTicketPage(ticket: ticket),
                    ),
                  ).then(
                    (value) => Navigator.pop(context),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              },
        child: const Text('Arrive'),
      ),
    );
  }
}
