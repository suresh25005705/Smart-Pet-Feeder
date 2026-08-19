import 'dart:async';

import 'package:flutter/material.dart';
import 'mqtt_service.dart';

void main() {
  runApp(const SmartPetFeederApp());
}

class SmartPetFeederApp extends StatelessWidget {
  const SmartPetFeederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Pet Feeder',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
      ),
      home: const MainScreen(),
    );
  }
}

// --------------------------------------------------
// MAIN SCREEN
// --------------------------------------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    SchedulePage(),
    HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// HOME PAGE
// --------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MqttService mqttService = MqttService();

  bool mqttConnected = false;

  @override
  void initState() {
    super.initState();
    connectMqtt();
  }

  Future<void> connectMqtt() async {
    print('==============================');
    print('Flutter MQTT: Connecting...');
    print('==============================');

    final connected = await mqttService.connect();

    if (!mounted) return;

    setState(() {
      mqttConnected = connected;
    });

    if (connected) {
      print('Flutter MQTT: CONNECTED');
    } else {
      print('Flutter MQTT: CONNECTION FAILED');
    }
  }

  @override
  void dispose() {
    mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🐾 Smart Pet Feeder',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DEVICE STATUS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Online',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('ESP32 Smart Feeder'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FOOD LEVEL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Food Level',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: 0.75,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    const Text('75% remaining'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // LAST/NEXT FEED
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    Icons.access_time,
                    'Last Feed',
                    '08:00 AM',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    Icons.schedule,
                    'Next Feed',
                    '02:00 PM',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // FEED NOW
            SizedBox(
              height: 65,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (mqttConnected) {
                    mqttService.publishFeedCommand();

                    print('==============================');
                    print('FEED NOW PRESSED');
                    print('FEED command sent through MQTT');
                    print('==============================');

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FEED command sent through MQTT'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('MQTT is not connected'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.pets),
                label: const Text(
                  'FEED NOW',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// SCHEDULE PAGE
// --------------------------------------------------

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final MqttService mqttService = MqttService();

  bool mqttConnected = false;

  final List<Map<String, dynamic>> schedules = [
    {
      'name': 'Breakfast',
      'time': '08:00 AM',
      'enabled': true,
    },
    {
      'name': 'Lunch',
      'time': '02:00 PM',
      'enabled': true,
    },
    {
      'name': 'Dinner',
      'time': '08:00 PM',
      'enabled': true,
    },
  ];

  final Map<int, Timer> _timers = {};

  @override
  void initState() {
    super.initState();

    _initializeScheduler();
  }

  // --------------------------------------------------
  // INITIALIZE SCHEDULER
  // --------------------------------------------------

  Future<void> _initializeScheduler() async {
    print('');
    print('==============================');
    print('SCHEDULER INITIALIZING');
    print('==============================');

    mqttConnected = await mqttService.connect();

    if (mqttConnected) {
      print('Scheduler MQTT connection: SUCCESS');
    } else {
      print('Scheduler MQTT connection: FAILED');
    }

    // Create timers for existing schedules.
    for (int i = 0; i < schedules.length; i++) {
      if (schedules[i]['enabled'] == true) {
        _scheduleFeed(i);
      }
    }

    print('Scheduler initialized.');
    print('==============================');
  }

  // --------------------------------------------------
  // SCHEDULE A FEED
  // --------------------------------------------------

  void _scheduleFeed(int index) {
    // Cancel an existing timer for this schedule.
    _timers[index]?.cancel();

    if (index < 0 || index >= schedules.length) {
      return;
    }

    if (schedules[index]['enabled'] != true) {
      print(
        'Schedule ${index + 1} is disabled. Timer not created.',
      );
      return;
    }

    final String timeString = schedules[index]['time'];

    final Duration? duration = _durationUntilTime(timeString);

    if (duration == null) {
      print(
        'Could not understand scheduled time: $timeString',
      );
      return;
    }

    final String scheduleName = schedules[index]['name'];

    print('');
    print('==============================');
    print('SCHEDULE CREATED');
    print('Name: $scheduleName');
    print('Time: $timeString');
    print('Feed in: ${duration.inSeconds} seconds');
    print('==============================');

    _timers[index] = Timer(
      duration,
      () async {
        await _executeScheduledFeed(index);
      },
    );
  }

  // --------------------------------------------------
  // CALCULATE TIME UNTIL NEXT OCCURRENCE
  // --------------------------------------------------

  Duration? _durationUntilTime(String timeString) {
    try {
      final parsed = _parseTimeString(timeString);

      if (parsed == null) {
        return null;
      }

      final now = DateTime.now();

      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsed.hour,
        parsed.minute,
      );

      // If today's time has already passed,
      // schedule it for tomorrow.
      if (!scheduledTime.isAfter(now)) {
        scheduledTime = scheduledTime.add(
          const Duration(days: 1),
        );
      }

      return scheduledTime.difference(now);
    } catch (e) {
      print('Time calculation error: $e');
      return null;
    }
  }

  // --------------------------------------------------
  // PARSE "08:00 AM", "2:00 PM", ETC.
  // --------------------------------------------------

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.trim().split(' ');

      if (parts.length != 2) {
        return null;
      }

      final timePart = parts[0];
      final amPm = parts[1].toUpperCase();

      final timeParts = timePart.split(':');

      if (timeParts.length != 2) {
        return null;
      }

      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      if (minute < 0 || minute > 59) {
        return null;
      }

      if (amPm == 'AM') {
        if (hour == 12) {
          hour = 0;
        }
      } else if (amPm == 'PM') {
        if (hour != 12) {
          hour += 12;
        }
      } else {
        return null;
      }

      if (hour < 0 || hour > 23) {
        return null;
      }

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      print('Could not parse time "$timeString": $e');
      return null;
    }
  }

  // --------------------------------------------------
  // EXECUTE SCHEDULED FEED
  // --------------------------------------------------

  Future<void> _executeScheduledFeed(int index) async {
    if (index < 0 || index >= schedules.length) {
      return;
    }

    final schedule = schedules[index];

    if (schedule['enabled'] != true) {
      print(
        'Scheduled feed skipped because it is disabled.',
      );
      return;
    }

    final String name = schedule['name'];
    final String time = schedule['time'];

    print('');
    print('==============================');
    print('SCHEDULED FEED TRIGGERED');
    print('Name: $name');
    print('Scheduled time: $time');
    print('Current time: ${TimeOfDay.now().format(context)}');
    print('==============================');

    // Make sure MQTT is connected.
    if (!mqttConnected) {
      print('Scheduler MQTT is not connected.');
      print('Attempting MQTT reconnection...');

      mqttConnected = await mqttService.connect();

      if (mqttConnected) {
        print('Scheduler MQTT reconnected successfully.');
      } else {
        print('Scheduler MQTT reconnection FAILED.');
      }
    }

    if (mqttConnected) {
      print('Sending scheduled FEED command...');

      mqttService.publishFeedCommand();

      print('Scheduled FEED command sent through MQTT.');
      print('==============================');
    } else {
      print(
        'Scheduled FEED command NOT sent because MQTT is disconnected.',
      );
      print('==============================');
    }

    // Schedule the same feeding time for tomorrow.
    if (mounted && schedule['enabled'] == true) {
      _scheduleFeed(index);
    }
  }

  // --------------------------------------------------
  // ADD NEW SCHEDULE
  // --------------------------------------------------

  void _addSchedule() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final String formattedTime =
        selectedTime.format(context);

    setState(() {
      schedules.add({
        'name': 'Custom Feed',
        'time': formattedTime,
        'enabled': true,
      });
    });

    final int newIndex = schedules.length - 1;

    // Immediately create the timer.
    _scheduleFeed(newIndex);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Feed scheduled for $formattedTime',
        ),
      ),
    );

    print('');
    print('NEW CUSTOM SCHEDULE ADDED');
    print('Time: $formattedTime');
    print('Index: $newIndex');
  }

  // --------------------------------------------------
  // ENABLE / DISABLE SCHEDULE
  // --------------------------------------------------

  void _toggleSchedule(
    int index,
    bool enabled,
  ) {
    setState(() {
      schedules[index]['enabled'] = enabled;
    });

    if (enabled) {
      print(
        'Schedule ${index + 1} ENABLED.',
      );

      _scheduleFeed(index);
    } else {
      print(
        'Schedule ${index + 1} DISABLED.',
      );

      _timers[index]?.cancel();
      _timers.remove(index);
    }
  }

  // --------------------------------------------------
  // BUILD SCHEDULE PAGE
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feeding Schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Automatic Feeding',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'The feeder will automatically dispense food '
            'at the enabled times.',
          ),

          const SizedBox(height: 20),

          ...schedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;

            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.restaurant,
                  size: 30,
                ),

                title: Text(
                  schedule['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  schedule['time'],
                ),

                trailing: Switch(
                  value: schedule['enabled'],
                  onChanged: (value) {
                    _toggleSchedule(
                      index,
                      value,
                    );
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _addSchedule,
            icon: const Icon(Icons.add),
            label: const Text(
              'ADD FEEDING TIME',
            ),
          ),

          const SizedBox(height: 20),

          // MQTT STATUS
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    mqttConnected
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    color: mqttConnected
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mqttConnected
                        ? 'Scheduler MQTT Connected'
                        : 'Scheduler MQTT Disconnected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  @override
  void dispose() {
    print('Stopping all scheduler timers...');

    for (final timer in _timers.values) {
      timer.cancel();
    }

    _timers.clear();

    mqttService.disconnect();

    super.dispose();
  }
}

// --------------------------------------------------
// HISTORY PAGE
// --------------------------------------------------

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feeding History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
              ),
              title: Text(
                'Breakfast',
              ),
              subtitle: Text(
                '08:00 AM',
              ),
              trailing: Text(
                'Automatic',
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
              ),
              title: Text(
                'Lunch',
              ),
              subtitle: Text(
                '02:00 PM',
              ),
              trailing: Text(
                'Automatic',
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
              ),
              title: Text(
                'Manual Feed',
              ),
              subtitle: Text(
                '05:30 PM',
              ),
              trailing: Text(
                'Manual',
              ),
            ),
          ),
        ],
      ),
    );
  }
}