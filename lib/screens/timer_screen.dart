import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:tiklarm/services/timer_service.dart';
import 'package:tiklarm/services/notification_service.dart';
import 'package:tiklarm/services/sound_service.dart';
import 'package:tiklarm/services/picker_sound_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  Timer? _timer;
  
  // Controllers for animations
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  // Quick time presets in seconds
  final List<Map<String, dynamic>> _presets = [
    {'label': '1 min', 'seconds': 60},
    {'label': '5 min', 'seconds': 300},
    {'label': '10 min', 'seconds': 600},
    {'label': '15 min', 'seconds': 900},
    {'label': '30 min', 'seconds': 1800},
    {'label': '1 hour', 'seconds': 3600},
  ];
  
  final TimerService _timerService = TimerService();
  final NotificationService _notificationService = NotificationService();
  final SoundService _soundService = SoundService();
  final PickerSoundService _pickerSoundService = PickerSoundService();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize picker sound service
    _pickerSoundService.initialize();
    
    // Pulse animation for the timer when running
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Rotation animation for the circular progress
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    // Wave animation for the background
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    // Start background animation
    _waveController.repeat();
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _soundService.stopSound();
    _timerService.handleWakelock(false);
    super.dispose();
  }

  void _startTimer() {
    final totalSeconds = _hours * 3600 + _minutes * 60 + _seconds;
    if (totalSeconds <= 0) return;
    
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _totalSeconds = totalSeconds;
      _pulseController.repeat(reverse: true);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSeconds <= 0) {
        _cancelTimer();
        _onTimerComplete();
      } else {
        setState(() {
          _totalSeconds--;
          _hours = _totalSeconds ~/ 3600;
          _minutes = (_totalSeconds % 3600) ~/ 60;
          _seconds = _totalSeconds % 60;
        });
      }
    });

    _timerService.handleWakelock(true);
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _isRunning = false;
        _pulseController.stop();
      });
    }

    _timerService.handleWakelock(false);
  }

  void _cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _isRunning = false;
        _pulseController.stop();
      });
    }

    _timerService.handleWakelock(false);
  }

  void _resetTimer() {
    _cancelTimer();
    setState(() {
      _hours = 0;
      _minutes = 0;
      _seconds = 0;
      _totalSeconds = 0;
      _isCompleted = false;
    });

    _timerService.handleWakelock(false);
  }

  void _onTimerComplete() {
    setState(() {
      _isCompleted = true;
    });
    _pulseController.stop();
    _timerService.handleWakelock(false);
    _notificationService.showTimerCompleteNotification();
    _soundService.playTimerCompleteSound();
    _showTimerCompleteDialog();
  }

  void _applyPreset(int seconds) {
    setState(() {
      _totalSeconds = seconds;
      _hours = seconds ~/ 3600;
      _minutes = (seconds % 3600) ~/ 60;
      _seconds = seconds % 60;
    });
  }

  void _showTimerCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Timer Complete!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your timer has finished.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startTimer();
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _totalSeconds > 0 
        ? 1 - ((_hours * 3600 + _minutes * 60 + _seconds) / _totalSeconds) 
        : 0.0;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        colorScheme.background,
                        colorScheme.background,
                        colorScheme.primary.withOpacity(0.05 + 0.03 * math.sin(_waveController.value * math.pi)),
                      ]
                    : [
                        colorScheme.background,
                        colorScheme.primary.withOpacity(0.03 + 0.02 * math.sin(_waveController.value * math.pi)),
                        colorScheme.background,
                      ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top section with title - removing this redundant title
                  const SizedBox(height: 10),
                  
                  // Timer display with animations
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isRunning ? _pulseAnimation.value : 1.0,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer circle with rotating gradient
                                AnimatedBuilder(
                                  animation: _rotationController,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _rotationController.value * 2 * math.pi,
                                      child: Container(
                                        width: 220,
                                        height: 220,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: SweepGradient(
                                            colors: [
                                              colorScheme.primary.withOpacity(0.1),
                                              colorScheme.primary.withOpacity(0.3),
                                              colorScheme.primary.withOpacity(0.1),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                // Progress indicator
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isCompleted
                                          ? Colors.green
                                          : (_isRunning
                                              ? colorScheme.primary
                                              : colorScheme.primary.withOpacity(0.7)),
                                    ),
                                  ),
                                ),
                                
                                // Inner circle with time display
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.surface,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Time display
                                        Text(
                                          '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                            color: _isCompleted
                                                ? Colors.green
                                                : (_isRunning
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Status text
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _isCompleted
                                                ? Colors.green.withOpacity(0.1)
                                                : (_isRunning 
                                                    ? colorScheme.primary.withOpacity(0.1) 
                                                    : colorScheme.surfaceVariant.withOpacity(0.3)),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _isCompleted
                                                ? 'Completed'
                                                : (_isRunning ? 'Running' : 'Ready'),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _isCompleted
                                                  ? Colors.green
                                                  : (_isRunning
                                                      ? colorScheme.primary
                                                      : colorScheme.onSurface.withOpacity(0.7)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Remaining controls and inputs
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        // Time input section
                        if (!_isRunning)
                          Container(
                            margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildScrollableTimePicker(),
                              ],
                            ),
                          ),
                        
                        // Quick preset buttons
                        if (!_isRunning)
                          Container(
                            height: 90,
                            margin: const EdgeInsets.fromLTRB(24, 4, 24, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Presets',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: _presets.map((preset) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: InkWell(
                                          onTap: () => _applyPreset(preset['seconds']),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            width: 70,
                                            decoration: BoxDecoration(
                                              color: colorScheme.primaryContainer.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              preset['label'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Expanding spacer when running
                        if (_isRunning) 
                          const Expanded(child: SizedBox())
                        else
                          const Spacer(),
                        
                        // Control buttons
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildControlButton(
                                  icon: Icons.refresh,
                                  label: 'Reset',
                                  onPressed: _resetTimer,
                                  color: colorScheme.error,
                                  isOutlined: true,
                                ),
                                _isRunning
                                    ? _buildControlButton(
                                        icon: Icons.pause,
                                        label: 'Pause',
                                        onPressed: _pauseTimer,
                                        color: colorScheme.tertiary,
                                      )
                                    : _buildControlButton(
                                        icon: Icons.play_arrow,
                                        label: 'Start',
                                        onPressed: _startTimer,
                                        color: colorScheme.primary,
                                        isLarge: true,
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollableTimePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    final selectedTextStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: colorScheme.primary,
    );
    
    final unselectedTextStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      color: isDark ? Colors.white60 : Colors.black54,
    );
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Hours label
        Column(
          children: [
            Text(
              'Hours',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            // Hours scroll wheel
            Container(
              width: 70,
              height: 120,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                  bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: CupertinoPicker(
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
                      bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
                    ),
                    color: colorScheme.primary.withOpacity(0.05),
                  ),
                ),
                looping: true,
                itemExtent: 40,
                backgroundColor: Colors.transparent,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _hours = index;
                  });
                  _pickerSoundService.playTickSound();
                },
                children: List<Widget>.generate(24, (index) {
                  return Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: unselectedTextStyle,
                    ),
                  );
                }),
                scrollController: FixedExtentScrollController(
                  initialItem: _hours,
                ),
              ),
            ),
          ],
        ),
        
        // Minutes label
        Column(
          children: [
            Text(
              'Minutes',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            // Minutes scroll wheel
            Container(
              width: 70,
              height: 120,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                  bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: CupertinoPicker(
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
                      bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
                    ),
                    color: colorScheme.primary.withOpacity(0.05),
                  ),
                ),
                looping: true,
                itemExtent: 40,
                backgroundColor: Colors.transparent,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _minutes = index;
                  });
                  _pickerSoundService.playTickSound();
                },
                children: List<Widget>.generate(60, (index) {
                  return Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: unselectedTextStyle,
                    ),
                  );
                }),
                scrollController: FixedExtentScrollController(
                  initialItem: _minutes,
                ),
              ),
            ),
          ],
        ),
        
        // Seconds label
        Column(
          children: [
            Text(
              'Seconds',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            // Seconds scroll wheel
            Container(
              width: 70,
              height: 120,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                  bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: CupertinoPicker(
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
                      bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
                    ),
                    color: colorScheme.primary.withOpacity(0.05),
                  ),
                ),
                looping: true,
                itemExtent: 40,
                backgroundColor: Colors.transparent,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _seconds = index;
                  });
                  _pickerSoundService.playTickSound();
                },
                children: List<Widget>.generate(60, (index) {
                  return Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: unselectedTextStyle,
                    ),
                  );
                }),
                scrollController: FixedExtentScrollController(
                  initialItem: _seconds,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isOutlined = false,
    bool isLarge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isLarge ? 45 : 35),
        child: Ink(
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(isLarge ? 45 : 35),
            border: isOutlined ? Border.all(color: color, width: 2) : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 28 : 20,
            vertical: isLarge ? 14 : 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isOutlined ? color : Colors.white,
                size: isLarge ? 26 : 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isLarge ? 15 : 13,
                  fontWeight: FontWeight.bold,
                  color: isOutlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 