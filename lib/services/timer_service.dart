import 'package:flutter/material.dart';
import 'package:tiklarm/services/settings_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  
  factory TimerService() {
    return _instance;
  }
  
  TimerService._internal() {
    // Listen to settings changes
    _settingsService.addListener(_onSettingsChanged);
  }

  final SettingsService _settingsService = SettingsService();
  bool _wakelockActive = false;
  
  // Called when settings change
  void _onSettingsChanged() {
    // Notify listeners when settings change to refresh UI
    notifyListeners();
    // Apply any settings changes that affect active features
    applySettingsChange();
  }
  
  // Handle screen wakelock based on settings
  Future<void> handleWakelock(bool isTimerRunning) async {
    try {
      // Only change wakelock state if needed
      final bool shouldBeEnabled = isTimerRunning && _settingsService.keepScreenOn;
      
      if (shouldBeEnabled && !_wakelockActive) {
        await WakelockPlus.enable();
        _wakelockActive = true;
        debugPrint('Wakelock enabled');
      } else if (!shouldBeEnabled && _wakelockActive) {
        await WakelockPlus.disable();
        _wakelockActive = false;
        debugPrint('Wakelock disabled');
      }
    } catch (e) {
      debugPrint('Error managing wakelock: $e');
      // Try to ensure wakelock is disabled on error
      try {
        if (_wakelockActive) {
          await WakelockPlus.disable();
          _wakelockActive = false;
        }
      } catch (_) {
        // Ignore secondary errors
      }
    }
  }

  // Format time based on settings (12h or 24h)
  String formatTimeOfDay(TimeOfDay time) {
    final is24HourFormat = _settingsService.timeFormat == '24h';
    
    if (is24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }
  
  // Apply settings changes immediately
  void applySettingsChange() async {
    // Re-evaluate wakelock state based on current timer state and updated settings
    if (_wakelockActive) {
      // If wakelock is currently active, check if it should still be
      await handleWakelock(true);
    }
  }
  
  @override
  void dispose() {
    // Remove the listener when disposed
    _settingsService.removeListener(_onSettingsChanged);
    
    // Ensure wakelock is disabled when service is disposed
    try {
      if (_wakelockActive) {
        WakelockPlus.disable();
        _wakelockActive = false;
        debugPrint('Wakelock disabled on dispose');
      }
    } catch (e) {
      debugPrint('Error disabling wakelock on dispose: $e');
    }
    super.dispose();
  }
} 