import 'package:background_location/data/models/ticket.dart';
import 'package:flutter/material.dart';

class OpenDetailTicketPage extends StatefulWidget {
  const OpenDetailTicketPage({Key? key, required this.ticket})
      : super(key: key);

  final Ticket ticket;

  @override
  _OpenDetailTicketPageState createState() => _OpenDetailTicketPageState();
}

class _OpenDetailTicketPageState extends State<OpenDetailTicketPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Detail (Preparation)')),
    );
  }
}
