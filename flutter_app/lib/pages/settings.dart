
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  File? _profileImage;
  bool _isCelsius = false;
  final List<String> _deviceNames = ['Device 1', 'Device 2', 'Device 3'];

  // ── Pick profile image ─────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // ── Rename dialog ──────────────────────────────────────────────────────────
  void _showRenameDialog(int index) {
    final controller = TextEditingController(text: _deviceNames[index]);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 48, 117, 152),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _deviceNames[index] = controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Profile Picture 
          const Text(
            'Profile Picture',
            style: TextStyle(
              color: Color.fromARGB(255, 48, 117, 152),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 48, 117, 152),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.person, size: 36, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Tap to change profile picture',
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(Icons.camera_alt, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Temperature Unit ───────────────────────────────────────────────
          const Text(
            'Temperature Unit',
            style: TextStyle(
              color: Color.fromARGB(255, 48, 117, 152),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 48, 117, 152),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // °F button
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCelsius = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !_isCelsius ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white38),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '°F  Fahrenheit',
                        style: TextStyle(
                          color: !_isCelsius
                              ? const Color.fromARGB(255, 48, 117, 152)
                              : Colors.white70,
                          fontWeight: !_isCelsius
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // °C button
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCelsius = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isCelsius ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white38),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '°C  Celsius',
                        style: TextStyle(
                          color: _isCelsius
                              ? const Color.fromARGB(255, 48, 117, 152)
                              : Colors.white70,
                          fontWeight: _isCelsius
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Rename Devices ─────────────────────────────────────────────────
          const Text(
            'Rename Devices',
            style: TextStyle(
              color: Color.fromARGB(255, 48, 117, 152),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_deviceNames.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () => _showRenameDialog(i),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 48, 117, 152),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _deviceNames[i].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(Icons.edit, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}