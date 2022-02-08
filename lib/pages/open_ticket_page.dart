import 'package:background_location/common/constant.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:background_location/pages/add_ticket_page.dart';
import 'package:flutter/material.dart';

class OpenTicketPage extends StatefulWidget {
  const OpenTicketPage({Key? key}) : super(key: key);

  @override
  _OpenTicketPageState createState() => _OpenTicketPageState();
}

class _OpenTicketPageState extends State<OpenTicketPage> {
  final _databaseHelper = DatabaseHelper();
  final List<Ticket> _openTicketList = [];

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
      _openTicketList.addAll(tickets);
    });
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
        itemCount: _openTicketList.length,
      ),
    );
  }
}
