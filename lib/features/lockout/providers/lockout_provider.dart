import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/models/question.dart';
import 'package:pflege_lock_app/core/providers/app_providers.dart';
import 'package:pflege_lock_app/core/services/overlay_service.dart';
import 'package:pflege_lock_app/core/services/security_service.dart';

enum LockoutStatus {
  loading,
  questionActive,
  correctStreak,
  wrongAnswer,
  unlocked,
}

class LockoutState {
  const LockoutState({
    this.status = LockoutStatus.loading,
    this.currentQuestion,
    this.shuffledOptions = const [],
    this.currentStreak = 0,
    this.streakRequired = AppConstants.defaultStreakRequired,
    this.blockedPackage = '',
    this.blockedAppName = '',
    this.selectedAnswer,
    this.showResult = false,
    this.isCorrect = false,
  });

  final LockoutStatus status;
  final Question? currentQuestion;
  final List<String> shuffledOptions;
  final int currentStreak;
  final int streakRequired;
  final String blockedPackage;
  final String blockedAppName;
  final String? selectedAnswer;
  final bool showResult;
  final bool isCorrect;

  LockoutState copyWith({
    LockoutStatus? status,
    Question? currentQuestion,
    List<String>? shuffledOptions,
    int? currentStreak,
    int? streakRequired,
    String? blockedPackage,
    String? blockedAppName,
    String? selectedAnswer,
    bool? showResult,
    bool? isCorrect,
    bool clearSelectedAnswer = false,
  }) {
    return LockoutState(
      status: status ?? this.status,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      shuffledOptions: shuffledOptions ?? this.shuffledOptions,
      currentStreak: currentStreak ?? this.currentStreak,
      streakRequired: streakRequired ?? this.streakRequired,
      blockedPackage: blockedPackage ?? this.blockedPackage,
      blockedAppName: blockedAppName ?? this.blockedAppName,
      selectedAnswer: clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      showResult: showResult ?? this.showResult,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class LockoutNotifier extends StateNotifier<LockoutState> {
  LockoutNotifier(this._ref) : super(const LockoutState());

  final Ref _ref;

  Future<void> init(String packageName, {bool previewMode = false}) async {
    final safePackage = SecurityService.sanitizePackageName(packageName);
    if (safePackage == null) return;

    state = state.copyWith(
      status: LockoutStatus.loading,
      blockedPackage: safePackage,
      currentStreak: 0,
    );

    final settingsRepo = _ref.read(settingsRepositoryProvider);
    final settings = await settingsRepo.getSettings();
    final blockedApp = await settingsRepo.getBlockedAppByPackage(safePackage);

    if (!previewMode && (blockedApp == null || !blockedApp.isActive)) return;

    state = state.copyWith(
      streakRequired: settings.streakRequired,
      blockedAppName: blockedApp?.appName ?? safePackage,
    );

    await _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    state = state.copyWith(
      status: LockoutStatus.loading,
      clearSelectedAnswer: true,
      showResult: false,
    );

    final settings = await _ref.read(settingsRepositoryProvider).getSettings();
    final question = await _ref.read(questionRepositoryProvider).getRandomQuestion(
          settings.activeCategories,
        );

    if (question == null) {
      state = state.copyWith(status: LockoutStatus.questionActive);
      return;
    }

    final options = List<String>.from(question.allOptions)..shuffle();
    state = state.copyWith(
      status: LockoutStatus.questionActive,
      currentQuestion: question,
      shuffledOptions: options,
    );
  }

  Future<void> selectAnswer(String answer) async {
    if (state.status != LockoutStatus.questionActive || state.showResult) return;

    final question = state.currentQuestion;
    if (question == null) return;

    final correct = answer == question.correctAnswer;
    await _ref.read(statsRepositoryProvider).recordAttempt(
          correct: correct,
          category: question.category,
        );

    state = state.copyWith(
      selectedAnswer: answer,
      showResult: true,
      isCorrect: correct,
    );

    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (correct) {
      final newStreak = state.currentStreak + 1;
      if (newStreak >= state.streakRequired) {
        await _unlock();
      } else {
        state = state.copyWith(
          status: LockoutStatus.correctStreak,
          currentStreak: newStreak,
        );
        await _loadQuestion();
      }
    } else {
      state = state.copyWith(
        status: LockoutStatus.wrongAnswer,
        currentStreak: 0,
      );
      await _loadQuestion();
    }
  }

  Future<void> _unlock() async {
    final blocked = await _ref.read(settingsRepositoryProvider)
        .getBlockedAppByPackage(state.blockedPackage);
    if (blocked == null || !blocked.isActive) return;

    state = state.copyWith(status: LockoutStatus.unlocked);
    final settings = await _ref.read(settingsRepositoryProvider).getSettings();
    final until = DateTime.now().add(
      Duration(minutes: settings.unlockDurationMinutes),
    );
    await _ref.read(settingsRepositoryProvider).setUnlockedUntil(
          state.blockedPackage,
          until,
        );
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await OverlayService.hideOverlay();
  }

  Future<void> emergencyBypass() async {
    final blocked = await _ref.read(settingsRepositoryProvider)
        .getBlockedAppByPackage(state.blockedPackage);
    if (blocked == null || !blocked.isActive) return;

    final stats = await _ref.read(statsRepositoryProvider).getTodayStats();
    if (stats.bypassCount >= AppConstants.maxDailyBypassCount) return;

    await _ref.read(statsRepositoryProvider).recordBypass();
    final until = DateTime.now().add(
      const Duration(minutes: AppConstants.emergencyBypassDurationMinutes),
    );
    await _ref.read(settingsRepositoryProvider).setUnlockedUntil(
          state.blockedPackage,
          until,
        );
    await OverlayService.hideOverlay();
  }
}

final lockoutProvider = StateNotifierProvider<LockoutNotifier, LockoutState>(
  (ref) => LockoutNotifier(ref),
);
