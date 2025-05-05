import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiklarm/models/alarm_model.dart';
import 'package:tiklarm/providers/alarm_provider.dart';
import 'package:intl/intl.dart';
import 'package:tiklarm/services/timer_service.dart';
import 'package:tiklarm/services/sound_service.dart';
import 'package:tiklarm/services/vibration_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:math' as math;

class AlarmTriggerScreen extends StatefulWidget {
  final AlarmModel alarm;
  
  const AlarmTriggerScreen({
    Key? key,
    required this.alarm,
  }) : super(key: key);

  @override
  State<AlarmTriggerScreen> createState() => _AlarmTriggerScreenState();
}

class _AlarmTriggerScreenState extends State<AlarmTriggerScreen> 
    with SingleTickerProviderStateMixin {
  final SoundService _soundService = SoundService();
  final VibrationService _vibrationService = VibrationService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
    
    _startAlarm();
  }
  
  void _startAlarm() async {
    try {
      // Keep screen on while alarm is active
      await WakelockPlus.enable();
      
      // Play alarm sound
      await _soundService.playAlarmSound();
      
      // Start vibration if enabled
      if (widget.alarm.isVibrate) {
        await _vibrationService.startAlarmVibration();
      }
    } catch (e) {
      debugPrint('Error starting alarm features: $e');
      // Still try to play sound and vibrate even if wakelock fails
      try {
        await _soundService.playAlarmSound();
        
        if (widget.alarm.isVibrate) {
          await _vibrationService.startAlarmVibration();
        }
      } catch (soundError) {
        debugPrint('Error playing alarm sound/vibration: $soundError');
      }
    }
  }
  
  @override
  void dispose() {
    try {
      // Stop sound and vibration when screen is closed
      _soundService.stopSound();
      _vibrationService.stopVibration();
      
      // Allow screen to turn off again
      WakelockPlus.disable();
      
      // Dispose animation controller
      _animationController.dispose();
    } catch (e) {
      debugPrint('Error cleaning up alarm resources: $e');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerService = TimerService();
    final formattedTime = timerService.formatTimeOfDay(widget.alarm.time);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ]
                : [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background animated circles
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CirclesPainter(
                        animation: _animationController.value,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                      ),
                    );
                  },
                ),
              ),
              
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  
                  // Date
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Animated Alarm Icon
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * math.pi,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: Icon(
                              Icons.alarm,
                              size: 60,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Alarm Time
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds);
                    },
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Alarm Label
                  if (widget.alarm.label.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.alarm.label,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  
                  const Spacer(flex: 1),
                  
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        // Snooze Button
                        Expanded(
                          child: _buildAnimatedActionButton(
                            context,
                            Icons.snooze_rounded,
                            'Snooze',
                            Colors.amber.shade700,
                            () => _snoozeAlarm(context),
                          ),
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Dismiss Button
                        Expanded(
                          child: _buildAnimatedActionButton(
                            context,
                            Icons.alarm_off_rounded,
                            'Dismiss',
                            Colors.red.shade700,
                            () => _dismissAlarm(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snoozeAlarm(BuildContext context) {
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    alarmProvider.snoozeAlarm(widget.alarm.id);
    Navigator.pop(context);
  }

  void _dismissAlarm(BuildContext context) {
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    alarmProvider.dismissAlarm(widget.alarm.id);
    Navigator.pop(context);
  }
}

// Custom painter for background circles
class CirclesPainter extends CustomPainter {
  final double animation;
  final Color color;
  
  CirclesPainter({required this.animation, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    
    // Draw multiple circles with varying sizes
    _drawCircle(canvas, size, paint, 0.1, animation * 0.7);
    _drawCircle(canvas, size, paint, 0.3, animation * 0.9);
    _drawCircle(canvas, size, paint, 0.5, animation * 0.5);
    _drawCircle(canvas, size, paint, 0.7, animation * 0.8);
    _drawCircle(canvas, size, paint, 0.9, animation * 0.6);
  }
  
  void _drawCircle(Canvas canvas, Size size, Paint paint, double positionFactor, double animationOffset) {
    final center = Offset(
      size.width * (0.2 + positionFactor * 0.8),
      size.height * (0.1 + positionFactor * 0.8),
    );
    
    final radius = size.width * 0.15 * (0.8 + animationOffset * 0.4);
    
    canvas.drawCircle(center, radius, paint);
  }
  
  @override
  bool shouldRepaint(CirclesPainter oldDelegate) => animation != oldDelegate.animation;
} 