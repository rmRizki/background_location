import 'package:background_location/common/constant.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/models/check_list.dart';
import 'package:background_location/data/models/history.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';

class SolvedDetailTicketPage extends StatefulWidget {
  const SolvedDetailTicketPage({Key? key, required this.ticket})
      : super(key: key);

  final Ticket ticket;

  @override
  _SolvedDetailTicketPageState createState() => _SolvedDetailTicketPageState();
}

class _SolvedDetailTicketPageState extends State<SolvedDetailTicketPage> {
  final _databaseHelper = DatabaseHelper();
  final _departureCheckList = <CheckListItem>[];
  final _arrivalCheckList = <CheckListItem>[];
  final _historyList = <History>[];

  @override
  void initState() {
    super.initState();
    _getChecklistData();
    _getHistoryData();
  }

  void _getChecklistData() async {
    final ticketId = widget.ticket.id;
    if (ticketId == null) return;
    final checklistMap = <String, dynamic>{};
    checklistMap['data'] = await _databaseHelper.getDataByQuery(
      TableName.checklist,
      where: 'ticket_id = ?',
      whereArgs: [ticketId],
    );
    final checkList = CheckList.fromJson(checklistMap).data ?? [];
    setState(() {
      _departureCheckList.clear();
      _arrivalCheckList.clear();
      _departureCheckList.addAll(checkList.where(
        (element) => element.type == describeEnum(ChecklistType.depart),
      ));
      _arrivalCheckList.addAll(checkList.where(
        (element) => element.type == describeEnum(ChecklistType.arrive),
      ));
    });
  }

  void _getHistoryData() async {
    final ticketId = widget.ticket.id;
    if (ticketId == null) return;
    final historyMap = <String, dynamic>{};
    historyMap['data'] = await _databaseHelper.getDataByQuery(
      TableName.history,
      where: 'ticket_id = ?',
      whereArgs: [ticketId],
    );
    final historyList = HistoryList.fromJson(historyMap).data ?? [];
    setState(() {
      _historyList.clear();
      _historyList.addAll(historyList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solved Ticket Detail')),
      body: SingleChildScrollView(
        primary: true,
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
            const Text('Departure Checklist : '),
            const SizedBox(height: 8),
            _departureCheckList.isEmpty
                ? const Text('-- None --')
                : _buildCheckList(_departureCheckList),
            const SizedBox(height: 8),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),
            const Text('Arrival Checklist : '),
            const SizedBox(height: 8),
            _arrivalCheckList.isEmpty
                ? const Text('-- None --')
                : _buildCheckList(_arrivalCheckList),
            const SizedBox(height: 8),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),
            const Text('History : '),
            const SizedBox(height: 8),
            _historyList.isEmpty
                ? const Text('-- None --')
                : _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckList(List<CheckListItem> chechList) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final checkListItem = chechList[index];
        final isDone = checkListItem.status == CheckListStatus.done.name;
        final id = checkListItem.id;
        if (id == null) return Container();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: CheckboxListTile(
            title: Text(checkListItem.title ?? '-'),
            value: isDone,
            onChanged: null,
          ),
        );
      },
      itemCount: chechList.length,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      itemBuilder: (context, index) {
        return _buildLocationItem(_historyList[index]);
      },
      itemCount: _historyList.length,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
    );
  }

  Widget _buildLocationItem(History history) {
    final latitude = double.tryParse(history.latitude ?? '0');
    final longitude = double.tryParse(history.longitude ?? '0');
    final labelText = '${history.time} -> $latitude,$longitude)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          history.action ?? '-',
          style: Theme.of(context).textTheme.bodyText2,
        ),
        subtitle: Text(labelText),
        onTap: () async {
          if (await MapLauncher.isMapAvailable(MapType.google) ?? false) {
            await MapLauncher.showMarker(
              mapType: MapType.google,
              coords: Coords(latitude ?? 0, longitude ?? 0),
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
