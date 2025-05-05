import 'dart:async';
import 'package:flutter/material.dart';

class LapData {
  final int number;
  final Duration lapTime;
  final Duration totalTime;

  LapData({
    required this.number,
    required this.lapTime,
    required this.totalTime,
  });
}

class StopwatchProvider extends ChangeNotifier {
  bool _isRunning = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<LapData> _laps = [];
  int _lapCounter = 1;
  
  // For tracking fastest and slowest laps
  int? _fastestLapIndex;
  int? _slowestLapIndex;

  // Getters
  bool get isRunning => _isRunning;
  Duration get elapsed => _stopwatch.elapsed;
  List<LapData> get laps => List.unmodifiable(_laps);
  int? get fastestLapIndex => _fastestLapIndex;
  int? get slowestLapIndex => _slowestLapIndex;

  void start() {
    if (!_isRunning) {
      _isRunning = true;
      _stopwatch.start();
      _startTimer();
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      notifyListeners();
    });
  }

  void stop() {
    if (_isRunning) {
      _isRunning = false;
      _stopwatch.stop();
      _timer?.cancel();
      notifyListeners();
    }
  }

  void reset() {
    _stopwatch.reset();
    _laps.clear();
    _lapCounter = 1;
    _fastestLapIndex = null;
    _slowestLapIndex = null;
    notifyListeners();
  }

  void lap() {
    if (_isRunning) {
      final totalTime = _stopwatch.elapsed;
      final lapTime = _laps.isEmpty
          ? totalTime
          : totalTime - Duration(microseconds: _stopwatch.elapsed.inMicroseconds - _laps.last.totalTime.inMicroseconds);
      
      _laps.add(LapData(
        number: _lapCounter++,
        lapTime: lapTime,
        totalTime: totalTime,
      ));
      
      _updateFastestAndSlowestLaps();
      notifyListeners();
    }
  }
  
  void _updateFastestAndSlowestLaps() {
    if (_laps.length <= 1) {
      _fastestLapIndex = _slowestLapIndex = null;
      return;
    }
    
    int? fastestIndex;
    int? slowestIndex;
    Duration? fastestTime;
    Duration? slowestTime;
    
    for (int i = 0; i < _laps.length; i++) {
      final lapTime = _laps[i].lapTime;
      
      if (fastestTime == null || lapTime < fastestTime) {
        fastestTime = lapTime;
        fastestIndex = i;
      }
      
      if (slowestTime == null || lapTime > slowestTime) {
        slowestTime = lapTime;
        slowestIndex = i;
      }
    }
    
    _fastestLapIndex = fastestIndex;
    _slowestLapIndex = slowestIndex;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
} 