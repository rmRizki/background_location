/// TODO tampilkan : 
/// - detail ticket
/// - checklist yang selesai
/// - history
/// 
import 'package:background_location/data/models/ticket.dart';
import 'package:flutter/material.dart';

class SolvedDetailTicketPage extends StatefulWidget {
  const SolvedDetailTicketPage({Key? key, required this.ticket})
      : super(key: key);

  final Ticket ticket;

  @override
  _SolvedDetailTicketPageState createState() => _SolvedDetailTicketPageState();
}

class _SolvedDetailTicketPageState extends State<SolvedDetailTicketPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solved Ticket Detail')),
    );
  }
}
