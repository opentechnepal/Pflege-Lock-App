import 'package:flutter/material.dart';

class AppConstants {
  static const int defaultStreakRequired = 3;
  static const int defaultUnlockDurationMinutes = 30;
  static const int emergencyBypassDurationMinutes = 5;
  static const int maxDailyBypassCount = 10;
  static const int monitorIntervalSeconds = 2;
  static const String dbName = 'pflegelock.db';
  static const int dbVersion = 1;
  static const String seededKey = 'seeded_v1';
  static const String onboardingKey = 'onboarding_done';
  static const String notificationChannelId = 'pflege_lock_service';
  static const String notificationChannelName = 'PflegeLock Service';
  static const String notificationTitle = 'PflegeLock aktiv';
  static const String notificationBody = 'Dein Lernschutz ist eingeschaltet 🔒';

  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color surfaceColor = Color(0xFF16213E);
  static const Color primaryColor = Color(0xFF0D7377);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color correctColor = Color(0xFF2ECC71);
  static const Color wrongColor = Color(0xFFE74C3C);

  static const List<String> allCategories = [
    'fachbegriff',
    'berechnung',
    'pflegeplanung',
    'anatomie',
  ];

  static const Map<String, String> categoryLabels = {
    'fachbegriff': 'Fachbegriff',
    'berechnung': 'Berechnung',
    'pflegeplanung': 'Pflegeplanung',
    'anatomie': 'Anatomie',
  };

  static const List<Map<String, String>> defaultBlockedPackages = [
    {'package': 'com.instagram.android', 'name': 'Instagram'},
    {'package': 'com.zhiliaoapp.musically', 'name': 'TikTok'},
    {'package': 'com.google.android.youtube', 'name': 'YouTube'},
    {'package': 'com.twitter.android', 'name': 'X (Twitter)'},
    {'package': 'com.snapchat.android', 'name': 'Snapchat'},
    {'package': 'com.facebook.katana', 'name': 'Facebook'},
    {'package': 'com.netflix.mediaclient', 'name': 'Netflix'},
  ];
}
