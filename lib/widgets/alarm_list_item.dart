import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:tiklarm/models/alarm_model.dart';
import 'package:tiklarm/services/timer_service.dart';
import 'package:provider/provider.dart';

class AlarmListItem extends StatelessWidget {
  final AlarmModel alarm;
  final Function(bool) onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AlarmListItem({
    Key? key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = alarm.isActive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerService = Provider.of<TimerService>(context);
    
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (_) async {
        return await _showDeleteConfirmation(context);
      },
      onDismissed: (_) {
        onDelete();
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isActive 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            Theme.of(context).colorScheme.primary.withOpacity(0.25),
                          ]
                        : [
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ],
                  )
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: isActive ? ImageFilter.blur(sigmaX: 8, sigmaY: 8) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark 
                          ? Colors.white.withOpacity(0.07)
                          : Colors.white.withOpacity(0.7))
                      : (isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.white.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.4 : 0.2)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Time and details container
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Time indicator dot
                          if (isActive)
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          
                          // Time and alarm info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Time display
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      timerService.formatTimeOfDay(alarm.time),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 4),
                                
                                // Label
                                if (alarm.label.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      alarm.label,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isActive
                                            ? Theme.of(context).colorScheme.onSurface
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                
                                // Repeat days
                                Text(
                                  _getRepeatText(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isActive
                                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                // Features/badges row
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 8,
                                    children: [
                                      if (alarm.isVibrate)
                                        _buildFeatureBadge(
                                          isActive: isActive,
                                          icon: Icons.vibration,
                                          label: 'Vibrate',
                                          context: context,
                                        ),
                                      _buildFeatureBadge(
                                        isActive: isActive,
                                        icon: Icons.music_note,
                                        label: alarm.soundPath ?? 'Default',
                                        context: context,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Toggle Switch
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Transform.scale(
                        scale: 0.9,
                        child: Switch.adaptive(
                          value: isActive,
                          onChanged: onToggle,
                          activeColor: Theme.of(context).colorScheme.primary,
                          activeTrackColor: isDark
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          inactiveThumbColor: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade400,
                          inactiveTrackColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({
    required bool isActive,
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  String _getRepeatText() {
    if (!alarm.days.contains(true)) {
      return 'One time';
    }
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = <String>[];
    
    for (int i = 0; i < alarm.days.length; i++) {
      if (alarm.days[i]) {
        selectedDays.add(days[i]);
      }
    }
    
    // Check for every day
    if (selectedDays.length == 7) {
      return 'Every day';
    }
    
    // Check for weekdays
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    if (selectedDays.length == 5 && weekdays.every((day) => selectedDays.contains(day))) {
      return 'Weekdays';
    }
    
    // Check for weekends
    final weekends = ['Sat', 'Sun'];
    if (selectedDays.length == 2 && weekends.every((day) => selectedDays.contains(day))) {
      return 'Weekends';
    }
    
    return selectedDays.join(', ');
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final timerService = Provider.of<TimerService>(context, listen: false);
    
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Alarm?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this alarm?',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timerService.formatTimeOfDay(alarm.time),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (alarm.label.isNotEmpty)
                        Text(
                          alarm.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }
} 