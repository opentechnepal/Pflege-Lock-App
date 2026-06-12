/// Validates Android package names and blocks suspicious input.
class SecurityService {
  static final _packagePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');

  static const String ownPackage = 'com.example.pflege_lock_app';

  static const Set<String> ignoredForegroundPackages = {
    ownPackage,
    'com.android.systemui',
    'com.android.launcher',
    'com.android.launcher3',
    'com.google.android.apps.nexuslauncher',
  };

  static bool isValidPackageName(String? value) {
    if (value == null || value.isEmpty || value.length > 255) return false;
    return _packagePattern.hasMatch(value);
  }

  static bool shouldIgnoreForegroundPackage(String? packageName) {
    if (!isValidPackageName(packageName)) return true;
    return ignoredForegroundPackages.contains(packageName);
  }

  static String? sanitizePackageName(String? value) {
    if (!isValidPackageName(value)) return null;
    return value;
  }
}
