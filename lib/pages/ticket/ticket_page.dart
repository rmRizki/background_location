import 'package:background_location/common/constant.dart';
import 'package:background_location/common/file_util.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:background_location/pages/location_log/location_log_page.dart';
import 'package:background_location/pages/ticket/open/arrive_detail_ticket_page.dart';
import 'package:background_location/pages/ticket/open/depart_detail_ticket_page.dart';
import 'package:background_location/pages/ticket/open/open_detail_ticket_page.dart';
import 'package:background_location/pages/ticket/open/open_ticket_page.dart';
import 'package:background_location/pages/ticket/solved/solved_ticket_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TicketPage extends StatefulWidget {
  const TicketPage({Key? key}) : super(key: key);

  @override
  _TicketPageState createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  final _databaseHelper = DatabaseHelper();
  int _openTicketCount = 0;
  int _solvedTicketCount = 0;
  Ticket? _activeTicket;

  @override
  void initState() {
    super.initState();
    _getTicketData();
  }

  _getTicketData() async {
    final ticketMap = <String, dynamic>{};
    ticketMap['data'] = await _databaseHelper.getData(TableName.ticket);
    final tickets = TicketList.fromJson(ticketMap).data;
    setState(() {
      _openTicketCount = _getTicketCount(tickets, TicketStatus.open.name);
      _solvedTicketCount = _getTicketCount(tickets, TicketStatus.solved.name);
      _activeTicket = _getActiveTicket(tickets);
    });
  }

  int _getTicketCount(List<Ticket>? ticketList, String status) {
    return (ticketList ?? [])
        .where((element) => element.ticketStatus == status)
        .toList()
        .length;
  }

  Ticket? _getActiveTicket(List<Ticket>? ticketList) {
    try {
      return (ticketList ?? []).firstWhere(
        (element) =>
            element.arrivalStatus == describeEnum(ArrivalStatus.departed) ||
            element.arrivalStatus == describeEnum(ArrivalStatus.arrived),
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool?> _showDeleteTicketDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete All Ticket'),
            content: const Text('Delete All Ticket Data?'),
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

  Future<void> _navigateToTicketDetail(
    String? arrivalStatus,
    Ticket? ticket,
  ) async {
    if (ticket == null) return;
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
      appBar: AppBar(
        title: const Text('Track Ticket'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationLogPage(),
                ),
              );
            },
            icon: const Icon(Icons.location_pin),
          ),
          IconButton(
            onPressed: () async {
              final isDelete = await _showDeleteTicketDialog(context);
              if (isDelete is bool && isDelete) {
                try {
                  await _databaseHelper.removeDataByQuery(TableName.ticket);
                  await _databaseHelper.removeDataByQuery(TableName.checklist);
                  await _databaseHelper.removeDataByQuery(TableName.history);
                  await FileUtil().deleteAllFile(folder: 'media');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All Data Deleted')),
                  );
                  _getTicketData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Active Ticket',
            style: Theme.of(context).textTheme.headline5,
          ),
          const SizedBox(height: 8),
          _activeTicket == null
              ? Text(
                  '--None--',
                  style: Theme.of(context).textTheme.subtitle1,
                )
              : Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListTile(
                    onTap: () async {
                      await _navigateToTicketDetail(
                        _activeTicket?.arrivalStatus,
                        _activeTicket,
                      ).then(
                        (_) => _getTicketData(),
                      );
                    },
                    title: Text(
                      _activeTicket?.title ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.subtitle1?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                    subtitle: Text(
                      _activeTicket?.description ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.navigate_next),
                  ),
                ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTicketMenu(
                'Open',
                _openTicketCount,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OpenTicketPage(),
                    ),
                  ).then(
                    (_) => _getTicketData(),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildTicketMenu(
                'Solved',
                _solvedTicketCount,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SolvedTicketPage(),
                    ),
                  ).then(
                    (_) => _getTicketData(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketMenu(
    String title,
    int count, {
    GestureTapCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 136,
        height: 120,
        child: Card(
          color: Colors.green,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: Theme.of(context)
                      .textTheme
                      .headline4
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
