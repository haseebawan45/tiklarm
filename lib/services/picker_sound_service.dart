import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PickerSoundService {
  static final PickerSoundService _instance = PickerSoundService._internal();
  
  factory PickerSoundService() {
    return _instance;
  }
  
  PickerSoundService._internal();
  
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }
  
  Future<void> playTickSound() async {
    try {
      // On iOS devices, use selection click for better native feeling
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HapticFeedback.selectionClick();
      } else {
        // On other platforms, use light impact vibration
        await HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error playing picker haptic feedback: $e');
    }
  }
  
  void dispose() {
    // Nothing to dispose
  }
} 