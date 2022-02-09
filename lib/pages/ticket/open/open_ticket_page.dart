import 'package:background_location/common/constant.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:background_location/pages/ticket/add_ticket_page.dart';
import 'package:background_location/pages/ticket/open/arrive_detail_ticket_page.dart';
import 'package:background_location/pages/ticket/open/depart_detail_ticket_page.dart';
import 'package:background_location/pages/ticket/open/open_detail_ticket_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OpenTicketPage extends StatefulWidget {
  const OpenTicketPage({Key? key}) : super(key: key);

  @override
  _OpenTicketPageState createState() => _OpenTicketPageState();
}

class _OpenTicketPageState extends State<OpenTicketPage> {
  final _databaseHelper = DatabaseHelper();
  final List<Ticket> _openTicketList = [];
  bool _inProgressExist = false;

  @override
  void initState() {
    super.initState();
    _getTicketData();
  }

  _getTicketData() async {
    final ticketMap = <String, dynamic>{};
    ticketMap['data'] = await _databaseHelper.getDataByQuery(
      TableName.ticket,
      where: 'ticket_status = ?',
      whereArgs: [TicketStatus.open.name],
    );
    final tickets = TicketList.fromJson(ticketMap).data ?? [];
    setState(() {
      _openTicketList.clear();
      _openTicketList.addAll(tickets);
      _inProgressExist = tickets.any((element) =>
          element.arrivalStatus == ArrivalStatus.arrived.name ||
          element.arrivalStatus == ArrivalStatus.departed.name);
    });
  }

  Future<bool?> _showOpenWarningDialog() async {
    return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Can\'t Open Ticket'),
            content: const Text(
              'You have another ticket need to be resolved first',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Future<void> _navigateToDetail(String? arrivalStatus, Ticket ticket) async {
    if (arrivalStatus == describeEnum(ArrivalStatus.standby)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OpenDetailTicketPage(ticket: ticket),
        ),
      );
    } else if (arrivalStatus == describeEnum(ArrivalStatus.departed)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DepartDetailTicketPage(ticket: ticket),
        ),
      );
    } else if (arrivalStatus == describeEnum(ArrivalStatus.arrived)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArriveDetailTicketPage(ticket: ticket),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Ticket')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final isChanged = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTicketPage(),
            ),
          );
          if (isChanged is bool && isChanged) {
            _getTicketData();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final ticket = _openTicketList[index];
          final arrivalStatus = ticket.arrivalStatus;
          final inProgressTicket =
              arrivalStatus == ArrivalStatus.arrived.name ||
                  arrivalStatus == ArrivalStatus.departed.name;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 2,
              child: ListTile(
                onTap: () async {
                  if (_inProgressExist && !inProgressTicket) {
                    await _showOpenWarningDialog();
                  } else {
                    await _navigateToDetail(arrivalStatus, ticket).then(
                      (_) => _getTicketData(),
                    );
                  }
                },
                title: Text(
                  ticket.title ?? '-',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.subtitle1?.copyWith(
                        color: inProgressTicket ? Colors.green : Colors.black,
                      ),
                ),
                subtitle: Text(
                  ticket.description ?? '-',
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.navigate_next),
              ),
            ),
          );
        },
        itemCount: _openTicketList.length,
      ),
    );
  }
}
