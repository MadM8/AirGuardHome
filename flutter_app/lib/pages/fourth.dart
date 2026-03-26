import 'package:air_guard/util/fourtha.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Hometile(dropName: "R A D O N"),
          Hometile(dropName: "M O L D"),
          Hometile(dropName: "T E M P E R A T U R E"),
        ],
      )
    );
  }
}