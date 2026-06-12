class UserStats {
  final int? id;
  final DateTime date;
  final int totalAttempts;
  final int correctCount;
  final int bypassCount;
  final String hardestCategory;

  const UserStats({
    this.id,
    required this.date,
    this.totalAttempts = 0,
    this.correctCount = 0,
    this.bypassCount = 0,
    this.hardestCategory = '',
  });

  double get accuracy =>
      totalAttempts == 0 ? 0 : (correctCount / totalAttempts) * 100;

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      totalAttempts: map['total_attempts'] as int? ?? 0,
      correctCount: map['correct_count'] as int? ?? 0,
      bypassCount: map['bypass_count'] as int? ?? 0,
      hardestCategory: map['hardest_category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String().split('T').first,
      'total_attempts': totalAttempts,
      'correct_count': correctCount,
      'bypass_count': bypassCount,
      'hardest_category': hardestCategory,
    };
  }

  UserStats copyWith({
    int? id,
    DateTime? date,
    int? totalAttempts,
    int? correctCount,
    int? bypassCount,
    String? hardestCategory,
  }) {
    return UserStats(
      id: id ?? this.id,
      date: date ?? this.date,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctCount: correctCount ?? this.correctCount,
      bypassCount: bypassCount ?? this.bypassCount,
      hardestCategory: hardestCategory ?? this.hardestCategory,
    );
  }
}
