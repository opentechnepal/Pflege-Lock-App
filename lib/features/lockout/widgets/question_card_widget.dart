import 'package:flutter/material.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';

class QuestionCardWidget extends StatelessWidget {
  const QuestionCardWidget({super.key, required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppConstants.surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
