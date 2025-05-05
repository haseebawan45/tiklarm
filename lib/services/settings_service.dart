import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiklarm/services/timer_service.dart';
import 'package:flutter/foundation.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  
  factory SettingsService() {
    return _instance;
  }
  
  SettingsService._internal();
  
  // Sound settings
  String _alarmSound = 'Default';
  double _alarmVolume = 0.8;
  bool _vibrationEnabled = true;
  
  // Timer settings
  bool _keepScreenOn = true;
  String _timeFormat = '24h';
  
  // Notification settings
  bool _showNotifications = true;
  
  // Getters
  String get alarmSound => _alarmSound;
  double get alarmVolume => _alarmVolume;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get keepScreenOn => _keepScreenOn;
  String get timeFormat => _timeFormat;
  bool get showNotifications => _showNotifications;
  
  // Available alarm sounds
  final List<String> availableAlarmSounds = [
    'Default',
    'Gentle',
    'Cosmic',
    'Chimes',
    'Digital',
    'Classic',
  ];
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _alarmSound = prefs.getString('alarmSound') ?? 'Default';
    _alarmVolume = prefs.getDouble('alarmVolume') ?? 0.8;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _keepScreenOn = prefs.getBool('keepScreenOn') ?? true;
    _timeFormat = prefs.getString('timeFormat') ?? '24h';
    _showNotifications = prefs.getBool('showNotifications') ?? true;
    
    notifyListeners();
  }
  
  Future<void> setAlarmSound(String value) async {
    if (_alarmSound == value) return;
    
    _alarmSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarmSound', value);
    notifyListeners();
  }
  
  Future<void> setAlarmVolume(double value) async {
    if (_alarmVolume == value) return;
    
    _alarmVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('alarmVolume', value);
    notifyListeners();
  }
  
  Future<void> setVibrationEnabled(bool value) async {
    if (_vibrationEnabled == value) return;
    
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', value);
    notifyListeners();
  }
  
  Future<void> setKeepScreenOn(bool value) async {
    if (_keepScreenOn == value) return;
    
    _keepScreenOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepScreenOn', value);
    
    // Notify TimerService to apply the new setting if any timers are running
    try {
      TimerService().applySettingsChange();
    } catch (e) {
      debugPrint('Error applying screen wake setting change: $e');
    }
    
    notifyListeners();
  }
  
  Future<void> setTimeFormat(String value) async {
    if (_timeFormat == value) return;
    
    _timeFormat = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timeFormat', value);
    notifyListeners();
  }
  
  Future<void> setShowNotifications(bool value) async {
    if (_showNotifications == value) return;
    
    _showNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNotifications', value);
    notifyListeners();
  }
  
  Future<void> refreshFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    
    _alarmSound = prefs.getString('alarmSound') ?? 'Default';
    _alarmVolume = prefs.getDouble('alarmVolume') ?? 0.8;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _keepScreenOn = prefs.getBool('keepScreenOn') ?? true;
    _timeFormat = prefs.getString('timeFormat') ?? '24h';
    _showNotifications = prefs.getBool('showNotifications') ?? true;
    
    notifyListeners();
  }
} 