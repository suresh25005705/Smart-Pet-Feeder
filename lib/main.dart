import 'dart:async';

import 'package:flutter/material.dart';
import 'mqtt_service.dart';

void main() {
  runApp(const SmartPetFeederApp());
}

// ============================================================
// GLOBAL FEED HISTORY
// ============================================================
//
// Each entry contains:
// name      -> Breakfast / Lunch / Custom Feed / Manual Feed
// time      -> actual time when feeding occurred
// type      -> Manual / Scheduled
//
final List<Map<String, String>> feedHistory = [];

// ============================================================
// APP
// ============================================================

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

// ============================================================
// MAIN SCREEN
// ============================================================

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

// ============================================================
// HOME PAGE
// ============================================================

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

  // ==========================================================
  // RECORD MANUAL FEED
  // ==========================================================

  void recordManualFeed() {
    final now = TimeOfDay.now();

    setState(() {
      feedHistory.insert(0, {
        'name': 'Manual Feed',
        'time': now.format(context),
        'type': 'Manual',
      });
    });

    print('History updated: Manual Feed');
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

            // LAST / NEXT FEED
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    Icons.access_time,
                    'Last Feed',
                    feedHistory.isNotEmpty
                        ? feedHistory.first['time']!
                        : '--:--',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    Icons.schedule,
                    'Next Feed',
                    'Scheduled',
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
                  if (!mqttConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'MQTT is not connected',
                        ),
                      ),
                    );
                    return;
                  }

                  // This is the existing working MQTT command.
                  mqttService.publishFeedCommand();

                  // Record the manual feed.
                  recordManualFeed();

                  print('==============================');
                  print('FEED NOW PRESSED');
                  print('FEED command sent through MQTT');
                  print('Manual feed added to history');
                  print('==============================');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'FEED command sent through MQTT',
                      ),
                    ),
                  );
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

// ============================================================
// SCHEDULE PAGE
// ============================================================

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

  // ==========================================================
  // INITIALIZE SCHEDULER
  // ==========================================================

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

    for (int i = 0; i < schedules.length; i++) {
      if (schedules[i]['enabled'] == true) {
        _scheduleFeed(i);
      }
    }

    print('Scheduler initialized.');
    print('==============================');
  }

  // ==========================================================
  // CREATE TIMER
  // ==========================================================

  void _scheduleFeed(int index) {
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

    final Duration? duration =
        _durationUntilTime(timeString);

    if (duration == null) {
      print(
        'Could not understand scheduled time: $timeString',
      );
      return;
    }

    final String scheduleName =
        schedules[index]['name'];

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

  // ==========================================================
  // CALCULATE NEXT OCCURRENCE
  // ==========================================================

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

      if (!scheduledTime.isAfter(now)) {
        scheduledTime =
            scheduledTime.add(const Duration(days: 1));
      }

      return scheduledTime.difference(now);
    } catch (e) {
      print('Time calculation error: $e');
      return null;
    }
  }

  // ==========================================================
  // PARSE TIME
  // ==========================================================

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
      print(
        'Could not parse time "$timeString": $e',
      );
      return null;
    }
  }

  // ==========================================================
  // EXECUTE SCHEDULED FEED
  // ==========================================================

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
    print(
      'Current time: ${TimeOfDay.now().format(context)}',
    );
    print('==============================');

    // Make sure MQTT is connected.
    if (!mqttConnected) {
      print('Scheduler MQTT is not connected.');
      print('Attempting MQTT reconnection...');

      mqttConnected = await mqttService.connect();

      if (mqttConnected) {
        print(
          'Scheduler MQTT reconnected successfully.',
        );
      } else {
        print(
          'Scheduler MQTT reconnection FAILED.',
        );
      }
    }

    if (mqttConnected) {
      print(
        'Sending scheduled FEED command...',
      );

      // Same working MQTT function as Feed Now.
      mqttService.publishFeedCommand();

      // ======================================================
      // ADD SCHEDULED FEED TO HISTORY
      // ======================================================

      final actualTime = TimeOfDay.now();

      feedHistory.insert(0, {
        'name': name,
        'time': actualTime.format(context),
        'type': 'Scheduled',
      });

      print(
        'Scheduled feed added to history.',
      );

      print(
        'Scheduled FEED command sent through MQTT.',
      );

      print('==============================');

      if (mounted) {
        setState(() {});
      }
    } else {
      print(
        'Scheduled FEED command NOT sent because MQTT '
        'is disconnected.',
      );

      print('==============================');
    }

    // Schedule the same feed for tomorrow.
    if (mounted &&
        schedule['enabled'] == true) {
      _scheduleFeed(index);
    }
  }

  // ==========================================================
  // ADD CUSTOM SCHEDULE
  // ==========================================================

  void _addSchedule() async {
    final TimeOfDay? selectedTime =
        await showTimePicker(
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

    final int newIndex =
        schedules.length - 1;

    // Actually create the timer.
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

  // ==========================================================
  // ENABLE / DISABLE
  // ==========================================================

  void _toggleSchedule(
    int index,
    bool enabled,
  ) {
    setState(() {
      schedules[index]['enabled'] =
          enabled;
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

  // ==========================================================
  // BUILD
  // ==========================================================

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
            'The feeder will automatically dispense '
            'food at the enabled times.',
          ),

          const SizedBox(height: 20),

          ...schedules.asMap().entries.map(
            (entry) {
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
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _addSchedule,
            icon: const Icon(Icons.add),
            label: const Text(
              'ADD FEEDING TIME',
            ),
          ),

          const SizedBox(height: 20),

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

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    print(
      'Stopping all scheduler timers...',
    );

    for (final timer in _timers.values) {
      timer.cancel();
    }

    _timers.clear();

    mqttService.disconnect();

    super.dispose();
  }
}

// ============================================================
// HISTORY PAGE
// ============================================================

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() =>
      _HistoryPageState();
}

class _HistoryPageState
    extends State<HistoryPage> {

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

      body: feedHistory.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No feeding history yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manual and scheduled feeds '
                    'will appear here.',
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  feedHistory.length,
              itemBuilder:
                  (context, index) {
                final feed =
                    feedHistory[index];

                final String name =
                    feed['name'] ??
                        'Feed';

                final String time =
                    feed['time'] ??
                        '--:--';

                final String type =
                    feed['type'] ??
                        'Unknown';

                final bool isManual =
                    type == 'Manual';

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        isManual
                            ? Icons.touch_app
                            : Icons.schedule,
                      ),
                    ),

                    title: Text(
                      name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    subtitle:
                        Text(time),

                    trailing: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        color: isManual
                            ? Colors.blue
                                .withOpacity(
                                0.12,
                              )
                            : Colors.orange
                                .withOpacity(
                                0.12,
                              ),
                      ),
                      child: Text(
                        type,
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: isManual
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}