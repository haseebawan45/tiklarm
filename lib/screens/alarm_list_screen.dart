import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiklarm/models/alarm_model.dart';
import 'package:tiklarm/providers/alarm_provider.dart';
import 'package:tiklarm/screens/alarm_edit_screen.dart';
import 'package:tiklarm/widgets/alarm_list_item.dart';
import 'package:intl/intl.dart';
import 'package:tiklarm/utils/platform_utils.dart';
import 'package:tiklarm/services/timer_service.dart';
import 'dart:math' as math;

class AlarmListScreen extends StatelessWidget {
  final bool showAppBar;
  
  const AlarmListScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add TimerService as a provider so the UI rebuilds when settings change
    return ChangeNotifierProvider.value(
      value: TimerService(),
      child: _AlarmListContent(showAppBar: showAppBar),
    );
  }
}

class _AlarmListContent extends StatelessWidget {
  final bool showAppBar;
  
  const _AlarmListContent({Key? key, required this.showAppBar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This will listen to both AlarmProvider and TimerService changes
    final alarmProvider = Provider.of<AlarmProvider>(context);
    // Listen to TimerService changes - this ensures we rebuild when time format changes
    final timerService = Provider.of<TimerService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [
                    Color(0xFF1E1E2E), 
                    Color(0xFF2D2D44)
                  ]
                : [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Theme.of(context).colorScheme.surface,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              if (showAppBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Alarms',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          // Navigate to settings
                        },
                        iconSize: 28,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ],
                  ),
                ),
              
              // Current time display
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.7) 
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        final now = DateTime.now();
                        final timeFormat = DateFormat.jm();
                        final formattedTime = timeFormat.format(now);
                        final formattedDate = DateFormat('EEEE, MMMM d').format(now);
                        
                        return Column(
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Web platform notice
              if (PlatformUtils.isWeb)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade200.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(Icons.info_outline, color: Colors.amber.shade800),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Limited functionality on web platform. '
                          'For full alarm features, please use the mobile app.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Alarms section title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Upcoming Alarms',
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
                        alarmProvider.alarms.where((a) => a.isActive).length.toString(),
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
              
              // Alarms list
              alarmProvider.isLoading
                  ? const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : alarmProvider.alarms.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  child: Icon(
                                    Icons.alarm_off_rounded,
                                    size: 60,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No alarms yet',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Add your first alarm',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: AnimatedList(
                            key: GlobalKey<AnimatedListState>(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            initialItemCount: alarmProvider.alarms.length,
                            itemBuilder: (context, index, animation) {
                              final alarm = alarmProvider.alarms[index];
                              
                              // Calculate a staggered animation delay based on index
                              final staggeredAnimation = Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Interval(
                                    0.05 * math.min(index, 10), // Cap the delay at 10 items
                                    1.0,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              );
                              
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(staggeredAnimation),
                                child: FadeTransition(
                                  opacity: staggeredAnimation,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: AlarmListItem(
                                      alarm: alarm,
                                      onToggle: (isActive) =>
                                          alarmProvider.toggleAlarm(alarm.id, isActive),
                                      onTap: () => _editAlarm(context, alarm),
                                      onDelete: () => alarmProvider.deleteAlarm(alarm.id),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 5, right: 5),
        child: FloatingActionButton.extended(
          onPressed: () => _addAlarm(context),
          label: Text(
            'Add Alarm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: const Icon(Icons.add, size: 20),
          elevation: 4,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _addAlarm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(
          isNew: true,
          alarm: AlarmModel(
            id: '',
            time: TimeOfDay.now(),
            isActive: true,
            label: '',
            days: List.filled(7, false),
            isVibrate: true,
          ),
        ),
      ),
    );
  }

  void _editAlarm(BuildContext context, AlarmModel alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(alarm: alarm, isNew: false),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AlarmModel alarm) {
    final timerService = Provider.of<TimerService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text(
          'Are you sure you want to delete the alarm set for ${timerService.formatTimeOfDay(alarm.time)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AlarmProvider>(context, listen: false)
                  .deleteAlarm(alarm.id);
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 