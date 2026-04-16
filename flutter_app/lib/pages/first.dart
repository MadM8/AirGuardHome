import 'package:air_guard/pages/fourth.dart';
import 'package:air_guard/pages/second.dart';
import 'package:air_guard/pages/third.dart';
import 'package:flutter/material.dart';
import 'package:air_guard/pages/settings.dart'; 


class First extends StatefulWidget {
  const First({super.key});

  @override
  State<First> createState() => _FirstState();
}

class _FirstState extends State<First> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index){
    setState (() {
      _selectedIndex = index;
    });
  }

  final List _page = [Home(), Devices(), Thermostat(), Settings()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AirGuard Home", style: TextStyle(color: Colors.white)),
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
            ),
          
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_accessibility_outlined),
            label: 'Settings',
            ),
             

        ]
      ),
    );
  }
}

