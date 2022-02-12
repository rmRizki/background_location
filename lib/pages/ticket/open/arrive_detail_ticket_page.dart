import 'dart:convert';

import 'package:background_location/common/constant.dart';
import 'package:background_location/common/helper.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/models/check_list.dart';
import 'package:background_location/data/models/history.dart';
import 'package:background_location/data/models/location.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArriveDetailTicketPage extends StatefulWidget {
  const ArriveDetailTicketPage({Key? key, required this.ticket})
      : super(key: key);

  final Ticket ticket;

  @override
  _ArriveDetailTicketPageState createState() => _ArriveDetailTicketPageState();
}

class _ArriveDetailTicketPageState extends State<ArriveDetailTicketPage> {
  final _databaseHelper = DatabaseHelper();
  final _checkList = <CheckListItem>[];
  LocationModel? _lastLocation;
  SharedPreferences? _sharedPreferences;

  @override
  void initState() {
    _getLastLocation();
    _getChecklistData();
    super.initState();
  }

  Future<void> _getLastLocation() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    final encodedLocationList =
        _sharedPreferences?.getStringList('location') ?? [];
    final locationList = <LocationModel>[];
    if (encodedLocationList.isNotEmpty) {
      locationList.clear();
      locationList.addAll(
        encodedLocationList.map((e) => LocationModel.fromJson(jsonDecode(e))),
      );
      _lastLocation = locationList.last;
    }
  }

  void _getChecklistData() async {
    final ticketId = widget.ticket.id;
    if (ticketId == null) return;
    final checklistMap = <String, dynamic>{};
    checklistMap['data'] = await _databaseHelper.getDataByQuery(
      TableName.checklist,
      where: 'type = ? and ticket_id = ?',
      whereArgs: [ChecklistType.arrive.name, ticketId],
    );
    final checkList = CheckList.fromJson(checklistMap).data ?? [];
    setState(() {
      _checkList.clear();
      _checkList.addAll(checkList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Detail (Arrived)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const Text('Arrival Checklist : '),
            const SizedBox(height: 8),
            Expanded(
              child: _checkList.isEmpty
                  ? const Text('-- None --')
                  : _buildCheckList(),
            ),
            _buildDoneButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckList() {
    return ListView.builder(
      itemBuilder: (context, index) {
        final checkListItem = _checkList[index];
        final isDone = checkListItem.status == CheckListStatus.done.name;
        final id = checkListItem.id;
        if (id == null) return Container();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: CheckboxListTile(
            title: Text(checkListItem.title ?? '-'),
            value: isDone,
            onChanged: (val) {
              setState(() {
                if (isDone) {
                  checkListItem.status = CheckListStatus.undone.name;
                } else {
                  checkListItem.status = CheckListStatus.done.name;
                }
                _databaseHelper.updateData(
                  TableName.checklist,
                  checkListItem.toJson(),
                  id,
                );
                _databaseHelper.insertData(
                  TableName.history,
                  History(
                    action:
                        'Checklist: ${checkListItem.title} : ${checkListItem.status}',
                    latitude: _lastLocation?.locationDto.latitude.toString(),
                    longitude: _lastLocation?.locationDto.longitude.toString(),
                    time: Helper.formatDateLog(DateTime.now()),
                    ticketId: widget.ticket.id,
                  ).toJson(),
                );
              });
            },
          ),
        );
      },
      itemCount: _checkList.length,
    );
  }

  Widget _buildDoneButton() {
    final ticket = widget.ticket;
    final ticketId = ticket.id;
    if (ticketId == null) return Container();
    final disableButton = _checkList.any(
      (element) => element.status != describeEnum(CheckListStatus.done),
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disableButton
            ? null
            : () async {
                try {
                  ticket.arrivalStatus = ArrivalStatus.done.name;
                  ticket.ticketStatus = TicketStatus.solved.name;
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
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              },
        child: const Text('Done'),
      ),
    );
  }
}
