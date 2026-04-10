import 'package:flutter/material.dart';

class Hometile extends StatelessWidget {
  final String dropName;

  const Hometile({super.key, required this.dropName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Container(
        padding: EdgeInsets.all(50),
        decoration: BoxDecoration(color: const Color.fromARGB(255, 49, 84, 120), borderRadius: BorderRadius.circular(24)),
        child: Text(dropName, style: TextStyle(color:  Colors.white),),
      ),
      //child: ExpansionTile(),
    );
  }
}