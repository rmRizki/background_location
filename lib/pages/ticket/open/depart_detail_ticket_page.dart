import 'package:background_location/data/models/ticket.dart';
import 'package:flutter/material.dart';

class DepartDetailTicketPage extends StatefulWidget {
  const DepartDetailTicketPage({Key? key, required this.ticket})
      : super(key: key);

  final Ticket ticket;

  @override
  _DepartDetailTicketPageState createState() => _DepartDetailTicketPageState();
}

class _DepartDetailTicketPageState extends State<DepartDetailTicketPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Detail (Departed)')),
    );
  }
}
