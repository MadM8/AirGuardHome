import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  // List of connected devices - add more here as you connect them
  final List<Map<String, dynamic>> _devices = [
    {
      'id': 'esp32_dht22',
      'defaultName': 'ESP32 DHT22',
      'firebasePath': '/airguard',
      'type': 'Temperature & Humidity Sensor',
      'icon': Icons.device_hub,
    }
  ];

  // Track custom names
  final Map<String, String> _deviceNames = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Device',
            onPressed: _showAddDeviceDialog,
          )
        ],
      ),
      body: _devices.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final deviceId = device['id'] as String;
                final displayName =
                    _deviceNames[deviceId] ?? device['defaultName'] as String;
                return _DeviceCard(
                  device: device,
                  displayName: displayName,
                  onRename: () => _showRenameDialog(deviceId, displayName),
                  onRemove: () => _showRemoveDialog(index, displayName),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.device_hub, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No devices connected',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Tap + to add a device',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _showRenameDialog(String deviceId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _deviceNames[deviceId] = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(int index, String deviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Are you sure you want to remove "$deviceName"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _devices.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Device'),
        content: const Text(
            'Connect a new ESP32 device and it will appear here automatically.'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatefulWidget {
  final Map<String, dynamic> device;
  final String displayName;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  const _DeviceCard({
    required this.device,
    required this.displayName,
    required this.onRename,
    required this.onRemove,
  });

  @override
  State<_DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<_DeviceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Device Header - tap to expand
          InkWell(
            borderRadius: _isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.device['icon'] as IconData,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.displayName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(widget.device['type'] as String,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  // Online indicator
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(_isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded) ...[
            const Divider(height: 1),

            // Live Sensor Data from Firebase
            StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref(widget.device['firebasePath'] as String)
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No data received yet'),
                  );
                }

                final data = Map<dynamic, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);

                // DHT22 data is nested under 'dht22' key
                final dht22 = Map<dynamic, dynamic>.from(data['dht22'] ?? {});
                final sensor = SensorData.fromMap(dht22);

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sensor Readings
                      const Text('Live Readings',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ReadingChip(
                            label: 'Temperature',
                            value: '${sensor.temperature.toStringAsFixed(1)}°C\n${(sensor.temperature * 9 / 5 + 32).toStringAsFixed(1)}°F',                            icon: Icons.thermostat,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _ReadingChip(
                            label: 'Humidity',
                            value: '${sensor.humidity.toStringAsFixed(1)}%',
                            icon: Icons.water_drop,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _ReadingChip(
                            label: 'Heat Index',
                            value:
                                '${sensor.heatIndex.toStringAsFixed(1)}°C',
                            icon: Icons.sunny,
                            color: Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Device Settings
                      const Text('Device Settings',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),

                      // Rename
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit, color: Colors.blue),
                        title: const Text('Rename Device'),
                        subtitle: Text(widget.displayName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: widget.onRename,
                      ),

                      // Refresh interval setting
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.timer, color: Colors.green),
                        title: const Text('Update Interval'),
                        subtitle: const Text('Every 2 seconds'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),

                      // Notifications
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications,
                            color: Colors.purple),
                        title: const Text('Alerts & Notifications'),
                        subtitle: const Text('Set temperature thresholds'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),

                      // Remove device
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.delete, color: Colors.red),
                        title: const Text('Remove Device',
                            style: TextStyle(color: Colors.red)),
                        onTap: widget.onRemove,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ReadingChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}