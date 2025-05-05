import 'package:audioplayers/audioplayers.dart';
import 'package:tiklarm/services/settings_service.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  
  factory SoundService() {
    return _instance;
  }
  
  SoundService._internal();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SettingsService _settingsService = SettingsService();
  
  // Play alarm sound based on settings
  Future<void> playAlarmSound() async {
    try {
      String sound = _settingsService.alarmSound.toLowerCase().replaceAll(' ', '_');
      if (sound == 'default') {
        sound = 'default_alarm';
      }
      
      // Set volume from settings
      await _audioPlayer.setVolume(_settingsService.alarmVolume);
      
      // Play selected sound using the corrected path structure
      await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
      
      debugPrint('Playing alarm sound: $sound at volume: ${_settingsService.alarmVolume}');
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
      // Fallback to default sound if there's an error
      try {
        await _audioPlayer.play(AssetSource('sounds/default_alarm.mp3'));
      } catch (fallbackError) {
        debugPrint('Error playing fallback sound: $fallbackError');
      }
    }
  }
  
  // Play timer completion sound
  Future<void> playTimerCompleteSound() async {
    try {
      // Set volume from settings
      await _audioPlayer.setVolume(_settingsService.alarmVolume);
      
      // Play timer complete sound with corrected path
      await _audioPlayer.play(AssetSource('sounds/timer_complete.mp3'));
    } catch (e) {
      debugPrint('Error playing timer completion sound: $e');
      // Try fallback sound
      try {
        await _audioPlayer.play(AssetSource('sounds/default_alarm.mp3'));
      } catch (fallbackError) {
        debugPrint('Error playing fallback sound: $fallbackError');
      }
    }
  }
  
  // Stop any playing sounds
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping sound: $e');
    }
  }
  
  // Dispose audio player resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
  }
} 