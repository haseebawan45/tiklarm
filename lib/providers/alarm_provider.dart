import 'package:flutter/material.dart';
import 'package:tiklarm/models/alarm_model.dart';
import 'package:tiklarm/services/alarm_service.dart';

class AlarmProvider extends ChangeNotifier {
  final AlarmService _alarmService = AlarmService();
  List<AlarmModel> _alarms = [];
  bool _isLoading = true;

  AlarmProvider() {
    _initAlarms();
  }

  bool get isLoading => _isLoading;
  List<AlarmModel> get alarms => List.unmodifiable(_alarms);

  // Method to load alarms - used when initializing the provider
  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _alarmService.init();
      _alarms = _alarmService.getAlarms();
    } catch (e) {
      debugPrint('Error loading alarms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initAlarms() async {
    try {
      await _alarmService.init();
      _alarms = _alarmService.getAlarms();
    } catch (e) {
      debugPrint('Error initializing alarms: $e');
      // Continue without initializing alarms if there's an error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    try {
      await _alarmService.addAlarm(alarm);
      _alarms = _alarmService.getAlarms();
    } catch (e) {
      debugPrint('Error adding alarm: $e');
    }
    notifyListeners();
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    try {
      await _alarmService.updateAlarm(alarm);
      _alarms = _alarmService.getAlarms();
    } catch (e) {
      debugPrint('Error updating alarm: $e');
    }
    notifyListeners();
  }

  Future<void> deleteAlarm(String id) async {
    try {
      await _alarmService.deleteAlarm(id);
      _alarms = _alarmService.getAlarms();
    } catch (e) {
      debugPrint('Error deleting alarm: $e');
    }
    notifyListeners();
  }

  Future<void> toggleAlarm(String id, bool isActive) async {
    try {
      await _alarmService.toggleAlarm(id, isActive);
      _alarms = _alarmService.getAlarms();
    } catch (e) {
      debugPrint('Error toggling alarm: $e');
    }
    notifyListeners();
  }

  Future<void> snoozeAlarm(String id) async {
    try {
      await _alarmService.snoozeAlarm(id);
    } catch (e) {
      debugPrint('Error snoozing alarm: $e');
    }
  }

  Future<void> dismissAlarm(String id) async {
    try {
      await _alarmService.dismissAlarm(id);
      _alarms = _alarmService.getAlarms();
    } catch (e) {
      debugPrint('Error dismissing alarm: $e');
    }
    notifyListeners();
  }
} 