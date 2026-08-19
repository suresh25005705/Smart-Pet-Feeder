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
    final connected = await mqttService.connect();

    if (!mounted) return;

    setState(() {
      mqttConnected = connected;
    });
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
          'Smart Pet Feeder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            SizedBox(
              height: 65,
              child: ElevatedButton.icon(
                onPressed: () {
  if (mqttConnected) {
    mqttService.publishFeedCommand();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feeding Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
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

                subtitle: Text(schedule['time']),

                trailing: Switch(
                  value: schedule['enabled'],
                  onChanged: (value) {
                    setState(() {
                      schedules[index]['enabled'] = value;
                    });
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              _addSchedule();
            },

            icon: const Icon(Icons.add),

            label: const Text(
              'ADD FEEDING TIME',
            ),
          ),
        ],
      ),
    );
  }

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

    setState(() {
      schedules.add({
        'name': 'Custom Feed',
        'time': selectedTime.format(context),
        'enabled': true,
      });
    });
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Breakfast'),
              subtitle: Text('08:00 AM'),
              trailing: Text('Automatic'),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Lunch'),
              subtitle: Text('02:00 PM'),
              trailing: Text('Automatic'),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Manual Feed'),
              subtitle: Text('05:30 PM'),
              trailing: Text('Manual'),
            ),
          ),
        ],
      ),
    );
  }
}
