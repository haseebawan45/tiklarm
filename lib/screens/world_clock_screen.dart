import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tiklarm/services/settings_service.dart';
import 'package:tiklarm/services/timer_service.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({Key? key}) : super(key: key);

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  late TimerService _timerService;
  
  final List<Map<String, dynamic>> _worldClocks = [
    {
      'city': 'London',
      'timezone': 'GMT+0',
      'offset': 0,
      'country': 'United Kingdom',
      'icon': Icons.castle,
      'color': Colors.red.shade700,
    },
    {
      'city': 'New York',
      'timezone': 'GMT-5',
      'offset': -5,
      'country': 'United States',
      'icon': Icons.location_city,
      'color': Colors.indigo.shade700,
    },
    {
      'city': 'Tokyo',
      'timezone': 'GMT+9',
      'offset': 9,
      'country': 'Japan',
      'icon': Icons.temple_buddhist,
      'color': Colors.orange.shade700,
    },
    {
      'city': 'Sydney',
      'timezone': 'GMT+11',
      'offset': 11,
      'country': 'Australia',
      'icon': Icons.beach_access,
      'color': Colors.teal.shade700,
    },
    {
      'city': 'Dubai',
      'timezone': 'GMT+4',
      'offset': 4,
      'country': 'United Arab Emirates',
      'icon': Icons.corporate_fare,
      'color': Colors.amber.shade700,
    },
    {
      'city': 'Paris',
      'timezone': 'GMT+2',
      'offset': 2,
      'country': 'France',
      'icon': Icons.tour,
      'color': Colors.blue.shade700,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timerService = TimerService();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Format time based on user's preference (12h or 24h)
  String _formatTime(DateTime dateTime) {
    // Extract hour and minute from dateTime to create a TimeOfDay
    final timeOfDay = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    
    // Use TimerService for consistent formatting
    return _timerService.formatTimeOfDay(timeOfDay);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          // Local time card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: _buildLocalTimeCard(isDark),
          ),
          
          // World clocks
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: _worldClocks.length,
                itemBuilder: (context, index) {
                  final clock = _worldClocks[index];
                  final cityTime = _now.toUtc().add(Duration(hours: clock['offset']));
                  
                  return _buildWorldClockCard(
                    cityName: clock['city'],
                    countryName: clock['country'],
                    timeZone: clock['timezone'],
                    dateTime: cityTime,
                    icon: clock['icon'],
                    color: clock['color'],
                    isDark: isDark,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(
          onPressed: () {
            // Add new city
          },
          child: const Icon(Icons.add),
          tooltip: 'Add City',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildLocalTimeCard(bool isDark) {
    final localTime = _formatTime(_now);
    final localDate = DateFormat('EEEE, d MMMM y').format(_now);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
              ? [
                  Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ]
              : [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Local Time',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('z').format(_now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              localTime,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localDate,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorldClockCard({
    required String cityName,
    required String countryName,
    required String timeZone,
    required DateTime dateTime,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final time = _formatTime(dateTime);
    final date = DateFormat('EEE, d MMM').format(dateTime);
    final isNight = dateTime.hour >= 18 || dateTime.hour < 6;
    
    final Color bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surface;
    
    final BoxDecoration boxDecoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(isDark ? 0.2 : 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: color.withOpacity(0.2),
        width: 1,
      ),
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: boxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // City icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // City info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cityName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    countryName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      isNight ? Icons.nightlight_round : Icons.wb_sunny,
                      size: 16,
                      color: isNight 
                          ? Colors.indigo.shade300 
                          : Colors.orange.shade300,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 