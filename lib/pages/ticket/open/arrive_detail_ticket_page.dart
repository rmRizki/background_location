import 'package:background_location/data/models/ticket.dart';
import 'package:flutter/material.dart';

class ArriveDetailTicketPage extends StatefulWidget {
  const ArriveDetailTicketPage({Key? key, required this.ticket})
      : super(key: key);

  final Ticket ticket;

  @override
  _ArriveDetailTicketPageState createState() => _ArriveDetailTicketPageState();
}

class _ArriveDetailTicketPageState extends State<ArriveDetailTicketPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Detail (Arrived)')),
    );
  }
}
