import 'package:flutter/material.dart';
import 'package:background_location/pages/location_log_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LocationLogPage(),
    );
  }
}