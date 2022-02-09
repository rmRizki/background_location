import 'package:flutter/material.dart';

class ArriveDetailTicketPage extends StatefulWidget {
  const ArriveDetailTicketPage({Key? key}) : super(key: key);

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
