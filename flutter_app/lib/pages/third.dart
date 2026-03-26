import 'package:flutter/material.dart';

class Thermostat extends StatelessWidget {
  const Thermostat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Temperature"),
      )
    );
  }
}