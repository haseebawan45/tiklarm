import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final List<bool> days;
  final Function(int, bool) onChanged;

  const DaySelector({
    Key? key,
    required this.days,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        return _buildDayToggle(
          context,
          dayLabels[index],
          days[index],
          () => onChanged(index, !days[index]),
        );
      }),
    );
  }

  Widget _buildDayToggle(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
} 