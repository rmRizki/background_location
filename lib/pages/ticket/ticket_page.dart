import 'package:background_location/common/constant.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:background_location/pages/location_log/location_log_page.dart';
import 'package:background_location/pages/ticket/open/open_ticket_page.dart';
import 'package:background_location/pages/ticket/solved/solved_ticket_page.dart';
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

  @override
  void initState() {
    super.initState();
    _getCountData();
  }

  _getCountData() async {
    final ticketMap = <String, dynamic>{};
    ticketMap['data'] = await _databaseHelper.getData(TableName.ticket);
    final tickets = TicketList.fromJson(ticketMap).data;
    setState(() {
      _openTicketCount = _getTicketCount(tickets, TicketStatus.open.name);
      _solvedTicketCount = _getTicketCount(tickets, TicketStatus.solved.name);
    });
  }

  int _getTicketCount(List<Ticket>? ticketList, String status) {
    return (ticketList ?? [])
        .where((element) => element.ticketStatus == status)
        .toList()
        .length;
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
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTicketMenu(
              'Open',
              _openTicketCount,
              onTap: () async {
                final isChanged = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OpenTicketPage(),
                  ),
                );
                if (isChanged is bool && isChanged) {
                  _getCountData();
                }
              },
            ),
            const SizedBox(height: 24),
            _buildTicketMenu(
              'Solved',
              _solvedTicketCount,
              onTap: () async {
                final isChanged = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SolvedTicketPage(),
                  ),
                );
                if (isChanged is bool && isChanged) {
                  _getCountData();
                }
              },
            ),
          ],
        ),
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
