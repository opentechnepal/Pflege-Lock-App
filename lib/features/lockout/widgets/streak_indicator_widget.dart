import 'package:flutter/material.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';

class StreakIndicatorWidget extends StatelessWidget {
  const StreakIndicatorWidget({
    super.key,
    required this.current,
    required this.required,
  });

  final int current;
  final int required;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🔥 $current / $required',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
