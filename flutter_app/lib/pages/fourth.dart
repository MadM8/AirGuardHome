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
        //padding: const EdgeInsets.all(0),
        shrinkWrap: false,
        reverse: true,
        children: [
          Container(
            padding: EdgeInsets.all(0),
            height: 250,
            child: const Center(child: Text('Monitor Your Readings', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic,fontSize:30, color: Color.fromARGB(255, 38, 119, 186)))),
          ),
          Hometile(dropName: "R A D O N"),
          Hometile(dropName: "M O L D"),
          Hometile(dropName: "T E M P E R A T U R E"),
        ].reversed.toList(),
      )
    );
  }
}