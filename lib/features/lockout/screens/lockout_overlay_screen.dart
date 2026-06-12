import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/database/database_helper.dart';
import 'package:pflege_lock_app/core/services/security_service.dart';
import 'package:pflege_lock_app/features/lockout/providers/lockout_provider.dart';
import 'package:pflege_lock_app/features/lockout/widgets/answer_options_widget.dart';
import 'package:pflege_lock_app/features/lockout/widgets/emergency_bypass_widget.dart';
import 'package:pflege_lock_app/features/lockout/widgets/question_card_widget.dart';
import 'package:pflege_lock_app/features/lockout/widgets/streak_indicator_widget.dart';

class LockoutOverlayScreen extends ConsumerStatefulWidget {
  const LockoutOverlayScreen({super.key, this.previewPackageName});

  /// When set, runs in-app preview mode (no system overlay listener).
  final String? previewPackageName;

  @override
  ConsumerState<LockoutOverlayScreen> createState() => _LockoutOverlayScreenState();
}

class _LockoutOverlayScreenState extends ConsumerState<LockoutOverlayScreen> {
  @override
  void initState() {
    super.initState();
    _initOverlay();
  }

  Future<void> _initOverlay() async {
    await DatabaseHelper.instance.database;

    if (widget.previewPackageName != null) {
      await ref.read(lockoutProvider.notifier).init(
            widget.previewPackageName!,
            previewMode: true,
          );
      return;
    }

    FlutterOverlayWindow.overlayListener.listen((event) {
      final package = SecurityService.sanitizePackageName(event?.toString());
      if (package != null && mounted) {
        ref.read(lockoutProvider.notifier).init(package);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lockoutProvider);
    final question = state.currentQuestion;
    final categoryLabel =
        AppConstants.categoryLabels[state.currentQuestion?.category ?? ''] ?? '';

    return Material(
      color: AppConstants.backgroundColor,
      child: SafeArea(
        child: Stack(
          children: [
            if (state.status == LockoutStatus.unlocked)
              Container(
                color: AppConstants.correctColor.withValues(alpha: 0.3),
                child: const Center(
                  child: Text(
                    '🎉 Freigeschaltet!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (categoryLabel.isNotEmpty)
                        Chip(
                          label: Text(categoryLabel),
                          backgroundColor: AppConstants.primaryColor,
                          labelStyle: const TextStyle(color: Colors.white),
                        )
                      else
                        const SizedBox.shrink(),
                      StreakIndicatorWidget(
                        current: state.currentStreak,
                        required: state.streakRequired,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.blockedAppName} gesperrt',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: state.status == LockoutStatus.loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppConstants.primaryColor,
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                if (question != null)
                                  QuestionCardWidget(prompt: question.promptDe),
                                const SizedBox(height: 20),
                                if (question != null)
                                  AnswerOptionsWidget(
                                    options: state.shuffledOptions,
                                    correctAnswer: question.correctAnswer,
                                    selectedAnswer: state.selectedAnswer,
                                    showResult: state.showResult,
                                    onSelect: (a) =>
                                        ref.read(lockoutProvider.notifier).selectAnswer(a),
                                  ),
                                if (state.showResult &&
                                    question?.explanation != null &&
                                    question!.explanation!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      question.explanation!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const EmergencyBypassWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
