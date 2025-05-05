import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tiklarm/services/timer_service.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:tiklarm/providers/stopwatch_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({Key? key}) : super(key: key);

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> with TickerProviderStateMixin {
  bool _isRunning = false;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<Map<String, dynamic>> _laps = [];
  int _lapCounter = 1;
  
  // Controllers for animations
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late AnimationController _initialAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  // For tracking fastest and slowest laps
  int? _fastestLapIndex;
  int? _slowestLapIndex;
  
  // Service for wakelock management
  final TimerService _timerService = TimerService();

  final GlobalKey _timeDisplayKey = GlobalKey();
  final GlobalKey _controlsKey = GlobalKey();
  final GlobalKey _lapListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the stopwatch when running
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Scale animation for UI elements
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Rotation animation for the decorative elements
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    
    // Wave animation for the background elements
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    
    // Initialize animation controller for initial animations
    _initialAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Start background animations
    _rotationController.repeat();
    _waveController.repeat(reverse: true);
    
    // Add a small delay for initial animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _pulseController.forward();
    });

    // Start the initial animation when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialAnimationController.forward();
    });
    
    // Enable wakelock when the stopwatch screen is active
    try {
      _timerService.handleWakelock(true);
    } catch (e) {
      debugPrint('Error enabling wakelock: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _initialAnimationController.dispose();
    
    // Disable wakelock when leaving the screen
    try {
      _timerService.handleWakelock(false);
    } catch (e) {
      debugPrint('Error disabling wakelock: $e');
    }
    
    super.dispose();
  }

  void _startStopwatch() {
    if (!_isRunning) {
      setState(() {
        _isRunning = true;
        _stopwatch.start();
        _pulseController.repeat(reverse: true);
      });
      
      _startTimer();
      
      // Enable wakelock if running
      try {
        _timerService.handleWakelock(true);
      } catch (e) {
        debugPrint('Error enabling wakelock: $e');
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        // This will trigger a rebuild to update the displayed time
      });
    });
  }

  void _stopStopwatch() {
    if (_isRunning) {
      setState(() {
        _isRunning = false;
        _stopwatch.stop();
        _pulseController.stop();
      });
      _timer?.cancel();
      
      // Disable wakelock when stopped
      try {
        _timerService.handleWakelock(false);
      } catch (e) {
        debugPrint('Error disabling wakelock: $e');
      }
    }
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
      _laps.clear();
      _lapCounter = 1;
      _fastestLapIndex = null;
      _slowestLapIndex = null;
    });
    
    // Ensure wakelock is disabled on reset
    try {
      _timerService.handleWakelock(false);
    } catch (e) {
      debugPrint('Error disabling wakelock: $e');
    }
  }

  void _recordLap() {
    if (_isRunning) {
      final lapTime = _stopwatch.elapsedMilliseconds;
      final previousLapTime = _laps.isNotEmpty ? _laps.first['totalTime'] as int : 0;
      final lapDuration = lapTime - previousLapTime;
      
      setState(() {
        _laps.insert(0, {
          'number': _lapCounter++,
          'lapTime': lapDuration,
          'totalTime': lapTime,
        });
        
        // Update fastest and slowest laps
        _updateFastestAndSlowestLaps();
      });
    }
  }
  
  void _updateFastestAndSlowestLaps() {
    if (_laps.length <= 1) {
      _fastestLapIndex = _slowestLapIndex = null;
      return;
    }
    
    int? fastestIndex;
    int? slowestIndex;
    int? fastestTime;
    int? slowestTime;
    
    for (int i = 0; i < _laps.length; i++) {
      final lapTime = _laps[i]['lapTime'] as int;
      
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

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate() % 100;
    int seconds = (milliseconds / 1000).truncate() % 60;
    int minutes = (milliseconds / 60000).truncate() % 60;
    int hours = (milliseconds / 3600000).truncate();

    String hoursStr = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');
    String hundredsStr = hundreds.toString().padLeft(2, '0');

    return '$hoursStr$minutesStr:$secondsStr.$hundredsStr';
  }
  
  String _formatLapTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate() % 100;
    int seconds = (milliseconds / 1000).truncate() % 60;
    int minutes = (milliseconds / 60000).truncate() % 60;
    
    String minutesStr = minutes > 0 ? '${minutes.toString()}:' : '';
    String secondsStr = seconds.toString().padLeft(2, '0');
    String hundredsStr = hundreds.toString().padLeft(2, '0');
    
    return '$minutesStr$secondsStr.$hundredsStr';
  }

  @override
  Widget build(BuildContext context) {
    final stopwatchProvider = Provider.of<StopwatchProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Create the animations for each section
    final timeDisplayAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _initialAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    
    final controlsAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _initialAnimationController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));
    
    final lapListAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _initialAnimationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF1A1A2E),
                    ]
                  : [
                      colorScheme.primary.withOpacity(0.05),
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.05),
                    ],
            ),
          ),
          child: CustomPaint(
            painter: BackgroundPainter(
              waveValue: _waveController.value,
              rotationValue: _rotationController.value,
              isDark: isDark,
              colorScheme: colorScheme,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Stopwatch',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Time display
                SlideTransition(
                  position: timeDisplayAnimation,
                  child: FadeTransition(
                    opacity: _initialAnimationController,
                    child: Container(
                      key: _timeDisplayKey,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          // Animated circles behind the time
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background circles
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _rotationController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _rotationController.value * 2 * math.pi,
                                        child: CustomPaint(
                                          painter: CirclesPainter(
                                            isRunning: stopwatchProvider.isRunning,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                // Center time display
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? const Color(0xFF1A1A2E) 
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(90),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      final scale = stopwatchProvider.isRunning
                                          ? 1.0 + (_pulseController.value * 0.05)
                                          : 1.0;
                                      
                                      return Transform.scale(
                                        scale: scale,
                                        child: child,
                                      );
                                    },
                                    child: Center(
                                      child: Text(
                                        _formatTime(stopwatchProvider.elapsed.inMilliseconds),
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Milliseconds
                          Text(
                            _formatMilliseconds(stopwatchProvider.elapsed),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Controls
                SlideTransition(
                  position: controlsAnimation,
                  child: FadeTransition(
                    opacity: _initialAnimationController,
                    child: Container(
                      key: _controlsKey,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Reset button
                          if (stopwatchProvider.elapsed.inMilliseconds > 0)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              child: ElevatedButton(
                                onPressed: () {
                                  stopwatchProvider.reset();
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                                  backgroundColor: isDark 
                                      ? const Color(0xFF2D2D44) 
                                      : Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.all(16),
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.3),
                                ),
                                child: const Icon(Icons.refresh, size: 28),
                              ),
                            ),
                          
                          // Start/stop button
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            child: ElevatedButton(
                              onPressed: () {
                                if (stopwatchProvider.isRunning) {
                                  stopwatchProvider.stop();
                                } else {
                                  stopwatchProvider.start();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: stopwatchProvider.isRunning
                                    ? Colors.red.shade600
                                    : Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.all(24),
                                shape: const CircleBorder(),
                                elevation: 6,
                                shadowColor: Colors.black.withOpacity(0.3),
                              ),
                              child: Icon(
                                stopwatchProvider.isRunning ? Icons.pause : Icons.play_arrow,
                                size: 36,
                              ),
                            ),
                          ),
                          
                          // Lap button
                          if (stopwatchProvider.isRunning || 
                              (!stopwatchProvider.isRunning && stopwatchProvider.laps.isNotEmpty))
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (stopwatchProvider.isRunning) {
                                    stopwatchProvider.lap();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                                  backgroundColor: isDark 
                                      ? const Color(0xFF2D2D44) 
                                      : Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.all(16),
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.3),
                                  disabledBackgroundColor: isDark 
                                      ? const Color(0xFF2D2D44).withOpacity(0.5) 
                                      : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                  disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                                child: const Icon(Icons.flag, size: 28),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Lap times
                FadeTransition(
                  opacity: lapListAnimation,
                  child: Container(
                    key: _lapListKey,
                    margin: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        if (stopwatchProvider.laps.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Text(
                                  'Laps',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    stopwatchProvider.laps.length.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (stopwatchProvider.laps.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: AnimationLimiter(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: stopwatchProvider.laps.length,
                                itemBuilder: (context, index) {
                                  // Reverse the index to show newest laps first
                                  final reversedIndex = stopwatchProvider.laps.length - 1 - index;
                                  final lap = stopwatchProvider.laps[reversedIndex];
                                  
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 500),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isDark 
                                                ? const Color(0xFF2A2A3C) 
                                                : Theme.of(context).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(18),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '${reversedIndex + 1}',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Lap time',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatDuration(lap.lapTime),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Total',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatDuration(lap.totalTime),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatMilliseconds(Duration duration) {
    return '.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}';
  }
}

// Custom background painter for animated visual elements
class BackgroundPainter extends CustomPainter {
  final double waveValue;
  final double rotationValue;
  final bool isDark;
  final ColorScheme colorScheme;
  
  BackgroundPainter({
    required this.waveValue,
    required this.rotationValue,
    required this.isDark,
    required this.colorScheme,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Paint for the circles
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw decorative elements
    _drawDecorations(canvas, size, paint);
  }
  
  void _drawDecorations(Canvas canvas, Size size, Paint paint) {
    final width = size.width;
    final height = size.height;
    
    // Draw top-right decoration
    paint.color = isDark
        ? colorScheme.primary.withOpacity(0.1)
        : colorScheme.primary.withOpacity(0.1);
        
    final topRightCircleX = width * 0.9 + (width * 0.1 * math.sin(waveValue * math.pi));
    final topRightCircleY = height * 0.15 + (height * 0.05 * math.cos(waveValue * math.pi));
    final topRightCircleRadius = width * 0.2 + (width * 0.02 * math.sin(waveValue * math.pi * 2));
    
    canvas.drawCircle(
      Offset(topRightCircleX, topRightCircleY),
      topRightCircleRadius,
      paint,
    );
    
    // Draw bottom-left decoration
    paint.color = isDark
        ? colorScheme.secondary.withOpacity(0.1)
        : colorScheme.secondary.withOpacity(0.1);
        
    final bottomLeftCircleX = width * 0.15 + (width * 0.05 * math.cos(waveValue * math.pi));
    final bottomLeftCircleY = height * 0.85 + (height * 0.03 * math.sin(waveValue * math.pi));
    final bottomLeftCircleRadius = width * 0.25 + (width * 0.015 * math.cos(waveValue * math.pi * 2));
    
    canvas.drawCircle(
      Offset(bottomLeftCircleX, bottomLeftCircleY),
      bottomLeftCircleRadius,
      paint,
    );
    
    // Draw a third decoration
    paint.color = isDark
        ? colorScheme.tertiary.withOpacity(0.1)
        : colorScheme.tertiary.withOpacity(0.1);
        
    final thirdCircleX = width * 0.3 + (width * 0.03 * math.sin(waveValue * math.pi * 1.5));
    final thirdCircleY = height * 0.3 + (height * 0.02 * math.cos(waveValue * math.pi * 1.5));
    final thirdCircleRadius = width * 0.15 + (width * 0.01 * math.sin(waveValue * math.pi * 3));
    
    canvas.drawCircle(
      Offset(thirdCircleX, thirdCircleY),
      thirdCircleRadius,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return oldDelegate.waveValue != waveValue || 
           oldDelegate.rotationValue != rotationValue;
  }
}

class CirclesPainter extends CustomPainter {
  final bool isRunning;
  final Color color;

  CirclesPainter({
    required this.isRunning,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw outer circle
    final outerPaint = Paint()
      ..color = color.withOpacity(isRunning ? 0.15 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    
    canvas.drawCircle(center, radius, outerPaint);
    
    // Draw middle circle
    final middlePaint = Paint()
      ..color = color.withOpacity(isRunning ? 0.1 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    canvas.drawCircle(center, radius * 0.75, middlePaint);
    
    // Draw inner circle
    final innerPaint = Paint()
      ..color = color.withOpacity(isRunning ? 0.2 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, radius * 0.5, innerPaint);
    
    if (isRunning) {
      // Draw accent circle segment
      final accentPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      
      const startAngle = -math.pi / 2;
      const sweepAngle = math.pi / 3;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.85),
        startAngle,
        sweepAngle,
        false,
        accentPaint,
      );
      
      // Draw small dots
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      for (int i = 0; i < 12; i++) {
        final angle = 2 * math.pi * (i / 12);
        final dotSize = i % 3 == 0 ? 6.0 : 3.0;
        final dotOffset = Offset(
          center.dx + math.cos(angle) * (radius * 0.9),
          center.dy + math.sin(angle) * (radius * 0.9),
        );
        
        final dotColor = color.withOpacity(i % 3 == 0 ? 0.8 : 0.4);
        final dotPaintWithColor = Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(dotOffset, dotSize, dotPaintWithColor);
      }
    }
  }

  @override
  bool shouldRepaint(CirclesPainter oldDelegate) {
    return oldDelegate.isRunning != isRunning || oldDelegate.color != color;
  }
} 