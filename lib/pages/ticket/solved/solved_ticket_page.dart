import 'package:background_location/common/constant.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:flutter/material.dart';

class SolvedTicketPage extends StatefulWidget {
  const SolvedTicketPage({Key? key}) : super(key: key);

  @override
  _SolvedTicketPageState createState() => _SolvedTicketPageState();
}

class _SolvedTicketPageState extends State<SolvedTicketPage> {
  final _databaseHelper = DatabaseHelper();
  final List<Ticket> _solvedTicketList = [];

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
      whereArgs: [TicketStatus.solved.name],
    );
    final tickets = TicketList.fromJson(ticketMap).data ?? [];
    setState(() {
      _solvedTicketList.addAll(tickets);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solved Ticket')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final ticket = _solvedTicketList[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 2,
              child: ListTile(
                title: Text(
                  ticket.title ?? '-',
                  overflow: TextOverflow.ellipsis,
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
        itemCount: _solvedTicketList.length,
      ),
    );
  }
}
