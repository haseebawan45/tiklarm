import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:tiklarm/services/settings_service.dart';
import 'package:tiklarm/utils/platform_utils.dart';

/// Service to handle vibration functionality based on user settings
class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  
  factory VibrationService() {
    return _instance;
  }
  
  VibrationService._internal();
  
  final SettingsService _settingsService = SettingsService();
  Timer? _vibrationTimer;
  bool _isVibrating = false;
  int _currentVibrationId = 0;  // To track current vibration session
  
  /// Starts vibration for alarm if enabled in settings
  Future<void> startAlarmVibration() async {
    if (!_settingsService.vibrationEnabled) return;
    if (!await _isVibrationSupported()) return;
    
    // Generate a unique ID for this vibration session
    final int vibrationId = ++_currentVibrationId;
    
    _isVibrating = true;
    
    try {
      // Vibration pattern: 500ms vibrate, 500ms pause, 1000ms vibrate, 500ms pause
      const pattern = [500, 500, 1000, 500];
      
      // Stop any ongoing vibration
      await stopVibration();
      
      // Only proceed if this is still the current vibration session
      if (vibrationId != _currentVibrationId) return;
      
      // Start vibration with pattern and repeat
      Vibration.vibrate(pattern: pattern, repeat: 0);
      
      // Set a backup timer to ensure vibration stops after 30 seconds
      // even if stopVibration is not called (fail-safe)
      _vibrationTimer = Timer(const Duration(seconds: 30), () {
        // Only stop if this is still the current vibration session
        if (vibrationId == _currentVibrationId) {
          stopVibration();
        }
      });
      
      debugPrint('Started alarm vibration (ID: $vibrationId)');
    } catch (e) {
      debugPrint('Error starting vibration: $e');
      _isVibrating = false;
    }
  }
  
  /// Starts vibration for timer if enabled in settings
  Future<void> startTimerVibration() async {
    if (!_settingsService.vibrationEnabled) return;
    if (!await _isVibrationSupported()) return;
    
    // Generate a unique ID for this vibration session
    final int vibrationId = ++_currentVibrationId;
    
    _isVibrating = true;
    
    try {
      // Simpler pattern for timer: 400ms vibrate, 400ms pause
      const pattern = [400, 400, 400, 400, 400, 400];
      
      // Stop any ongoing vibration
      await stopVibration();
      
      // Only proceed if this is still the current vibration session
      if (vibrationId != _currentVibrationId) return;
      
      // Start vibration with pattern, repeat twice
      Vibration.vibrate(pattern: pattern, repeat: 1);
      
      // Set a backup timer to ensure vibration stops after 10 seconds
      _vibrationTimer = Timer(const Duration(seconds: 10), () {
        // Only stop if this is still the current vibration session
        if (vibrationId == _currentVibrationId) {
          stopVibration();
        }
      });
      
      debugPrint('Started timer vibration (ID: $vibrationId)');
    } catch (e) {
      debugPrint('Error starting vibration: $e');
      _isVibrating = false;
    }
  }
  
  /// Stops any ongoing vibration
  Future<void> stopVibration() async {
    try {
      // Increment the ID to invalidate any ongoing vibration sessions
      _currentVibrationId++;
      
      if (_vibrationTimer != null) {
        _vibrationTimer!.cancel();
        _vibrationTimer = null;
      }
      
      if (_isVibrating) {
        await Vibration.cancel();
        _isVibrating = false;
        debugPrint('Stopped vibration');
      }
    } catch (e) {
      debugPrint('Error stopping vibration: $e');
    }
  }
  
  /// Check if vibration is supported on this device
  Future<bool> _isVibrationSupported() async {
    try {
      // Skip vibration check on web
      if (PlatformUtils.isWeb) return false;
      
      // Check if vibration is supported on this device
      bool? hasVibrator = await Vibration.hasVibrator();
      return hasVibrator ?? false;
    } catch (e) {
      debugPrint('Error checking vibration support: $e');
      return false;
    }
  }
  
  /// Dispose of resources
  void dispose() {
    stopVibration();
  }
} 