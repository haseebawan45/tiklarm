import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiklarm/services/theme_service.dart';
import 'package:tiklarm/services/settings_service.dart';
import 'package:tiklarm/screens/about_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Theme settings
  late bool _useSystemTheme;
  late bool _isDarkMode;
  
  // Sound settings
  late String _alarmSound;
  late double _alarmVolume;
  late bool _vibrationEnabled;
  
  // Timer settings
  late bool _keepScreenOn;
  late String _timeFormat;
  
  // Notification settings
  late bool _showNotifications;
  
  @override
  void initState() {
    super.initState();
    
    // Get services
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    // Initialize settings from services
    _useSystemTheme = themeService.useSystemTheme;
    _isDarkMode = themeService.isDarkMode;
    
    _alarmSound = settingsService.alarmSound;
    _alarmVolume = settingsService.alarmVolume;
    _vibrationEnabled = settingsService.vibrationEnabled;
    _keepScreenOn = settingsService.keepScreenOn;
    _timeFormat = settingsService.timeFormat;
    _showNotifications = settingsService.showNotifications;
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final settingsService = Provider.of<SettingsService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Theme', colorScheme, Icons.palette_outlined),
            
            // System theme
            SwitchListTile(
              title: const Text('Use system theme'),
              subtitle: const Text('Automatically switch between light and dark theme'),
              value: _useSystemTheme,
              onChanged: (value) {
                setState(() {
                  _useSystemTheme = value;
                });
                // Apply theme setting immediately
                themeService.setUseSystemTheme(value);
              },
              secondary: Icon(Icons.brightness_auto, color: colorScheme.primary),
            ),
            
            // Dark mode (only if not using system theme)
            if (!_useSystemTheme)
              SwitchListTile(
                title: const Text('Dark theme'),
                subtitle: const Text('Use dark theme throughout the app'),
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  // Apply theme setting immediately
                  themeService.setDarkMode(value);
                },
                secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: colorScheme.primary),
              ),
            
            _buildSectionHeader('Time', colorScheme, Icons.access_time),
            
            // Time format
            ListTile(
              title: const Text('Time format'),
              subtitle: Text(_timeFormat == '24h' ? '24-hour format' : '12-hour format'),
              leading: Icon(Icons.schedule, color: colorScheme.primary),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '12h', label: Text('12h')),
                  ButtonSegment(value: '24h', label: Text('24h')),
                ],
                selected: {_timeFormat},
                onSelectionChanged: (Set<String> selection) {
                  final value = selection.first;
                  setState(() {
                    _timeFormat = value;
                  });
                  // Apply time format setting immediately
                  settingsService.setTimeFormat(value);
                },
              ),
            ),
            
            _buildSectionHeader('Alarm', colorScheme, Icons.alarm),
            
            // Alarm sound
            ListTile(
              title: const Text('Alarm sound'),
              subtitle: Text(_alarmSound),
              leading: Icon(Icons.music_note, color: colorScheme.primary),
              trailing: DropdownButton<String>(
                value: _alarmSound,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _alarmSound = newValue;
                    });
                    // Apply alarm sound change immediately
                    settingsService.setAlarmSound(newValue);
                  }
                },
                underline: Container(),
                items: settingsService.availableAlarmSounds
                    .map((sound) => DropdownMenuItem(
                          value: sound,
                          child: Text(sound),
                        ))
                    .toList(),
              ),
            ),
            
            // Volume slider
            ListTile(
              title: Text('Alarm volume: ${(_alarmVolume * 100).round()}%'),
              leading: Icon(Icons.volume_up, color: colorScheme.primary),
              subtitle: Slider(
                value: _alarmVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _alarmVolume = value;
                  });
                },
                onChangeEnd: (value) {
                  // Save volume when sliding ends
                  settingsService.setAlarmVolume(value);
                },
              ),
            ),
            
            // Vibration setting
            SwitchListTile(
              title: const Text('Vibrate on alarm'),
              subtitle: const Text('Device will vibrate when alarm goes off'),
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                // Apply vibration setting immediately
                settingsService.setVibrationEnabled(value);
              },
              secondary: Icon(Icons.vibration, color: colorScheme.primary),
            ),
            
            _buildSectionHeader('Timer', colorScheme, Icons.timer_outlined),
            
            // Keep screen on setting
            SwitchListTile(
              title: const Text('Keep screen on'),
              subtitle: const Text('Prevent screen from turning off while timer is running'),
              value: _keepScreenOn,
              onChanged: (value) {
                setState(() {
                  _keepScreenOn = value;
                });
                // Apply screen on setting immediately
                settingsService.setKeepScreenOn(value);
              },
              secondary: Icon(Icons.screen_lock_portrait, color: colorScheme.primary),
            ),
            
            _buildSectionHeader('Notifications', colorScheme, Icons.notifications_outlined),
            
            // Notifications
            SwitchListTile(
              title: const Text('Show notifications'),
              subtitle: const Text('Display notifications for alarms and timers'),
              value: _showNotifications,
              onChanged: (value) {
                setState(() {
                  _showNotifications = value;
                });
                // Apply notification setting immediately
                settingsService.setShowNotifications(value);
              },
              secondary: Icon(Icons.notifications, color: colorScheme.primary),
            ),
            
            // About Us Section
            _buildSectionTitle(context, 'About'),
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('About Us'),
                    subtitle: const Text('App information and developer details'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, ColorScheme colorScheme, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: colorScheme.primary.withOpacity(0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
} 