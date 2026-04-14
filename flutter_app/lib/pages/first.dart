import 'package:air_guard/pages/fourth.dart';
import 'package:air_guard/pages/devices_screen.dart';
import 'package:air_guard/pages/third.dart';
import 'package:flutter/material.dart';

class First extends StatefulWidget {
  const First({super.key});

  @override
  State<First> createState() => _FirstState();
}

class _FirstState extends State<First> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  final List _page = [Home(), DevicesScreen(), Thermostat()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("A I R G U A R D  H O M E", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 48, 117, 152),
      ),
      body: _page[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            ),

          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
            ),

          BottomNavigationBarItem(
            icon: Icon(Icons.device_thermostat_outlined),
            label: 'Thermostat',
            )
        ]
      ),
    );
  }
}