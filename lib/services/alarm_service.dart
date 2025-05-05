import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/model/notification_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tiklarm/models/alarm_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:alarm/model/volume_settings.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tiklarm/utils/platform_utils.dart';
import 'package:tiklarm/services/settings_service.dart';

class AlarmService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  List<AlarmModel> _alarms = [];
  bool _isNativeAlarmsSupported = false;
  final SettingsService _settingsService = SettingsService();
  
  // Singleton pattern
  static final AlarmService _instance = AlarmService._internal();
  
  factory AlarmService() {
    return _instance;
  }
  
  AlarmService._internal();
  
  // Check if the platform supports native alarms
  bool get isNativeAlarmsSupported => _isNativeAlarmsSupported;
  
  Future<void> init() async {
    _isNativeAlarmsSupported = PlatformUtils.isNativeAlarmsSupported;
    
    try {
      // Initialize notifications
      if (!PlatformUtils.isWeb) {
        const AndroidInitializationSettings androidSettings = 
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings iosSettings =
            DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            );
        const InitializationSettings initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );
        
        await _notifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTap,
        ).timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('Notification initialization timed out');
          return;
        });
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
    
    try {
      // Initialize alarm plugin
      if (_isNativeAlarmsSupported) {
        try {
          await Alarm.init().timeout(const Duration(seconds: 5), onTimeout: () {
            debugPrint('Alarm initialization timed out');
            return;
          });
        } catch (e) {
          debugPrint('Error initializing alarm plugin: $e');
          // Specifically handle MissingPluginException for flutter_fgbg
          if (e.toString().contains('MissingPluginException') && 
              e.toString().contains('flutter_fgbg')) {
            debugPrint('Flutter FGBG plugin not available on this platform');
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing alarm plugin: $e');
    }
    
    try {
      // Request permissions only on platforms that support them
      if (PlatformUtils.arePermissionsAvailable) {
        await _requestPermissions();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
    
    try {
      // Load alarms from storage
      await loadAlarms();
    } catch (e) {
      debugPrint('Error loading alarms: $e');
    }
  }
  
  void _onNotificationTap(NotificationResponse details) {
    // Handle notification tap
  }
  
  Future<void> _requestPermissions() async {
    try {
      // Request notification permissions
      await Permission.notification.request();
      
      // Request alarm permissions (only on Android)
      if (PlatformUtils.isAndroid) {
        try {
          if (await Permission.ignoreBatteryOptimizations.isGranted == false) {
            await Permission.ignoreBatteryOptimizations.request();
          }
        } catch (e) {
          debugPrint('Error requesting battery optimization permission: $e');
          // Ignore this error as it's not critical
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      // Continue without permissions - the app will handle gracefully
    }
  }
  
  // Load alarms from storage
  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? alarmsJson = prefs.getStringList('alarms');
    
    if (alarmsJson != null) {
      _alarms = alarmsJson
          .map((alarmJson) => AlarmModel.fromMap(jsonDecode(alarmJson)))
          .toList();
    }
  }
  
  // Save alarms to storage
  Future<void> saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmsJson = _alarms
        .map((alarm) => jsonEncode(alarm.toMap()))
        .toList();
    
    await prefs.setStringList('alarms', alarmsJson);
  }
  
  // Get all alarms
  List<AlarmModel> getAlarms() {
    return List.unmodifiable(_alarms);
  }
  
  // Add a new alarm
  Future<void> addAlarm(AlarmModel alarm) async {
    _alarms.add(alarm);
    await _scheduleAlarm(alarm);
    await saveAlarms();
  }
  
  // Update an existing alarm
  Future<void> updateAlarm(AlarmModel alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      // Cancel the old alarm
      await _cancelAlarm(_alarms[index]);
      
      // Update the alarm in the list
      _alarms[index] = alarm;
      
      // Schedule the new alarm if active
      if (alarm.isActive) {
        await _scheduleAlarm(alarm);
      }
      
      await saveAlarms();
    }
  }
  
  // Delete an alarm
  Future<void> deleteAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      
      // Cancel the alarm
      await _cancelAlarm(alarm);
      
      // Remove from the list
      _alarms.removeAt(index);
      
      await saveAlarms();
    }
  }
  
  // Toggle alarm active status
  Future<void> toggleAlarm(String id, bool isActive) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updatedAlarm = _alarms[index].copyWith(isActive: isActive);
      
      if (isActive) {
        await _scheduleAlarm(updatedAlarm);
      } else {
        await _cancelAlarm(_alarms[index]);
      }
      
      _alarms[index] = updatedAlarm;
      await saveAlarms();
    }
  }
  
  // Schedule an alarm
  Future<void> _scheduleAlarm(AlarmModel alarm) async {
    // Calculate the next trigger time
    final DateTime now = DateTime.now();
    final int currentDay = now.weekday - 1; // 0 = Monday, 6 = Sunday
    
    // Check if any day is selected
    if (!alarm.days.contains(true)) {
      return; // No days selected, don't schedule
    }
    
    // Find the next day to trigger
    int daysToAdd = 0;
    for (int i = 0; i < 7; i++) {
      final int dayToCheck = (currentDay + i) % 7;
      if (alarm.days[dayToCheck]) {
        daysToAdd = i;
        break;
      }
    }
    
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );
    
    // Add days to get to the next scheduled day
    scheduledDate = scheduledDate.add(Duration(days: daysToAdd));
    
    // If the time today has already passed, add a day
    if (scheduledDate.isBefore(now) && daysToAdd == 0) {
      // Find the next day in the sequence
      for (int i = 1; i < 7; i++) {
        final int dayToCheck = (currentDay + i) % 7;
        if (alarm.days[dayToCheck]) {
          scheduledDate = scheduledDate.add(Duration(days: i));
          break;
        }
      }
    }
    
    // Skip setting the native alarm if not supported (e.g., on web)
    if (!_isNativeAlarmsSupported) return;
    
    // Create the alarm using the Alarm plugin
    final alarmSettings = AlarmSettings(
      id: int.parse(alarm.id),
      dateTime: scheduledDate,
      assetAudioPath: 'sounds/${alarm.soundPath}.mp3',
      loopAudio: true,
      vibrate: alarm.isVibrate,
      notificationSettings: NotificationSettings(
        title: 'Alarm',
        body: alarm.label.isNotEmpty ? alarm.label : 'Time to wake up!',
      ),
      volumeSettings: VolumeSettings.fixed(volume: _settingsService.alarmVolume),
    );
    
    await Alarm.set(alarmSettings: alarmSettings);
  }
  
  // Cancel an alarm
  Future<void> _cancelAlarm(AlarmModel alarm) async {
    if (_isNativeAlarmsSupported) {
      await Alarm.stop(int.parse(alarm.id));
    }
  }
  
  // Snooze an alarm
  Future<void> snoozeAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      
      // Cancel the current alarm
      await _cancelAlarm(alarm);
      
      // Skip setting the native alarm if not supported (e.g., on web)
      if (!_isNativeAlarmsSupported) return;
      
      // Create a new temporary alarm for snooze
      final now = DateTime.now();
      final snoozeTime = now.add(Duration(minutes: alarm.snoozeTime));
      
      final alarmSettings = AlarmSettings(
        id: int.parse('${alarm.id}9'), // Add 9 to the ID to make it unique
        dateTime: snoozeTime,
        assetAudioPath: 'sounds/${alarm.soundPath}.mp3',
        loopAudio: true,
        vibrate: alarm.isVibrate,
        notificationSettings: NotificationSettings(
          title: 'Snoozed Alarm',
          body: alarm.label.isNotEmpty 
              ? '${alarm.label} (Snoozed)' 
              : 'Snoozed alarm',
        ),
        volumeSettings: VolumeSettings.fixed(volume: _settingsService.alarmVolume),
      );
      
      await Alarm.set(alarmSettings: alarmSettings);
    }
  }
  
  // Dismiss an alarm
  Future<void> dismissAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      
      // Cancel the alarm
      await _cancelAlarm(alarm);
      
      // If it's not a repeating alarm, set it to inactive
      if (!alarm.days.contains(true)) {
        final updatedAlarm = alarm.copyWith(isActive: false);
        _alarms[index] = updatedAlarm;
        await saveAlarms();
      } else {
        // Reschedule for the next occurrence
        await _scheduleAlarm(alarm);
      }
    }
  }
} 