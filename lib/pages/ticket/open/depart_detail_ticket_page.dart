import 'package:flutter/material.dart';

class DepartDetailTicketPage extends StatefulWidget {
  const DepartDetailTicketPage({Key? key}) : super(key: key);

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
