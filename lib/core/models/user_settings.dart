class UserSettings {
  final int streakRequired;
  final int unlockDurationMinutes;
  final bool serviceEnabled;
  final bool soundEnabled;
  final List<String> activeCategories;

  const UserSettings({
    this.streakRequired = 3,
    this.unlockDurationMinutes = 30,
    this.serviceEnabled = true,
    this.soundEnabled = true,
    this.activeCategories = const [
      'fachbegriff',
      'berechnung',
      'pflegeplanung',
      'anatomie',
    ],
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    final categoriesStr = map['active_categories'] as String? ??
        'fachbegriff,berechnung,pflegeplanung,anatomie';
    return UserSettings(
      streakRequired: map['streak_required'] as int? ?? 3,
      unlockDurationMinutes: map['unlock_duration_minutes'] as int? ?? 30,
      serviceEnabled: (map['service_enabled'] as int? ?? 1) == 1,
      soundEnabled: (map['sound_enabled'] as int? ?? 1) == 1,
      activeCategories: categoriesStr.split(',').where((c) => c.isNotEmpty).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'streak_required': streakRequired,
      'unlock_duration_minutes': unlockDurationMinutes,
      'service_enabled': serviceEnabled ? 1 : 0,
      'sound_enabled': soundEnabled ? 1 : 0,
      'active_categories': activeCategories.join(','),
    };
  }

  UserSettings copyWith({
    int? streakRequired,
    int? unlockDurationMinutes,
    bool? serviceEnabled,
    bool? soundEnabled,
    List<String>? activeCategories,
  }) {
    return UserSettings(
      streakRequired: streakRequired ?? this.streakRequired,
      unlockDurationMinutes: unlockDurationMinutes ?? this.unlockDurationMinutes,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      activeCategories: activeCategories ?? this.activeCategories,
    );
  }
}
