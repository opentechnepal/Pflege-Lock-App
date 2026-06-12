class BlockedApp {
  final int? id;
  final String packageName;
  final String appName;
  final bool isActive;
  final DateTime? unlockedUntil;

  const BlockedApp({
    this.id,
    required this.packageName,
    required this.appName,
    this.isActive = true,
    this.unlockedUntil,
  });

  bool get isLocked {
    if (unlockedUntil == null) return true;
    return DateTime.now().isAfter(unlockedUntil!);
  }

  factory BlockedApp.fromMap(Map<String, dynamic> map) {
    final unlockedStr = map['unlocked_until'] as String?;
    return BlockedApp(
      id: map['id'] as int?,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      unlockedUntil: unlockedStr != null ? DateTime.tryParse(unlockedStr) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'package_name': packageName,
      'app_name': appName,
      'is_active': isActive ? 1 : 0,
      'unlocked_until': unlockedUntil?.toIso8601String(),
    };
  }

  BlockedApp copyWith({
    int? id,
    String? packageName,
    String? appName,
    bool? isActive,
    DateTime? unlockedUntil,
    bool clearUnlockedUntil = false,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isActive: isActive ?? this.isActive,
      unlockedUntil: clearUnlockedUntil ? null : (unlockedUntil ?? this.unlockedUntil),
    );
  }
}
