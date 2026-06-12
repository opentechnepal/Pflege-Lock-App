import 'package:flutter/material.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';

class AnswerOptionsWidget extends StatelessWidget {
  const AnswerOptionsWidget({
    super.key,
    required this.options,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.showResult,
    required this.onSelect,
  });

  final List<String> options;
  final String? correctAnswer;
  final String? selectedAnswer;
  final bool showResult;
  final ValueChanged<String> onSelect;

  Color _buttonColor(String option) {
    if (!showResult) return AppConstants.primaryColor;
    if (option == correctAnswer) return AppConstants.correctColor;
    if (option == selectedAnswer) return AppConstants.wrongColor;
    return AppConstants.surfaceColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: showResult ? null : () => onSelect(option),
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor(option),
                foregroundColor: Colors.white,
                disabledBackgroundColor: _buttonColor(option),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
