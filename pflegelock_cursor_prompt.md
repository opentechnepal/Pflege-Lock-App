# PflegeLock — Complete Cursor AI Development Prompt

> Paste this entire document into Cursor as your starting prompt.
> Cursor should scaffold the full project from this spec.

---

## What You Are Building

Build **"PflegeLock"** — an Android-only Flutter app that works as a distraction blocker for international *Pflegefachmann* trainees in Germany. When the user tries to open a blocked app (Instagram, TikTok, YouTube, etc.), PflegeLock immediately draws a full-screen overlay that prevents access until the user correctly answers a streak of Pflegefachmann exam-style questions in German.

**Target user:** International nursing trainees (*Azubis*) doing the *Pflegefachmann* apprenticeship in Germany who struggle with German medical *Fachsprache* and want a forced-study mechanic built into their daily phone use.

**Core loop:**
1. User opens Instagram
2. PflegeLock detects it via a background foreground-monitoring service
3. Full-screen overlay fires immediately over Instagram
4. User must answer 3 correct questions in a row (configurable streak) to unlock for 30 minutes
5. Wrong answer → streak resets, new question rolls in
6. All questions are Pflegefachmann-specific (Fachbegriffe, Pflegeplanung, Berechnungen, Anatomie)

---

## Technical Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (Android only — no iOS) |
| Language | Dart |
| Min SDK | Android 23 (API 23) |
| Target SDK | Android 34 |
| State Management | flutter_riverpod ^2.5.1 |
| Database | sqflite ^2.3.3 |
| Background Service | flutter_foreground_task ^8.0.1 |
| Overlay Window | flutter_overlay_window ^0.4.0 |
| App Listing | installed_apps ^1.4.0 |
| Permissions | permission_handler ^11.3.1 |
| Navigation | go_router ^14.2.7 |
| Local Settings | shared_preferences ^2.3.2 |
| UI | Material 3, no external UI packages |

---

## pubspec.yaml — Dependencies Section

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  sqflite: ^2.3.3
  sqflite_common_ffi: ^2.3.3
  flutter_foreground_task: ^8.0.1
  flutter_overlay_window: ^0.4.0
  installed_apps: ^1.4.0
  permission_handler: ^11.3.1
  go_router: ^14.2.7
  shared_preferences: ^2.3.2
  intl: ^0.19.0
```

---

## Android Manifest — Required Additions

File: `android/app/src/main/AndroidManifest.xml`

Add these permissions inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

Add these inside `<application>`:

```xml
<!-- Boot receiver to restart service after device reboot -->
<receiver
    android:name=".BootReceiver"
    android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
  </intent-filter>
</receiver>

<!-- Foreground service for flutter_foreground_task -->
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundTaskService"
    android:foregroundServiceType="dataSync"
    android:exported="false"/>
```

---

## android/app/build.gradle

```groovy
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 23
        targetSdkVersion 34
    }
}
```

---

## Project File Structure

Generate this exact structure:

```
lib/
├── main.dart                              # App entry point + ProviderScope
├── overlay_main.dart                      # Overlay entry point (separate from main)
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── database/
│   │   ├── database_helper.dart           # SQLite init + migrations
│   │   └── seed_data.dart                 # 50 seed questions
│   ├── models/
│   │   ├── question.dart
│   │   ├── blocked_app.dart
│   │   ├── user_stats.dart
│   │   └── user_settings.dart
│   ├── repositories/
│   │   ├── question_repository.dart
│   │   ├── stats_repository.dart
│   │   └── settings_repository.dart
│   └── services/
│       ├── monitor_service.dart           # Foreground task handler
│       ├── overlay_service.dart           # Show/hide overlay
│       └── permission_service.dart        # Permission checks + requests
│
├── features/
│   ├── onboarding/
│   │   └── screens/
│   │       ├── welcome_screen.dart
│   │       └── permission_setup_screen.dart
│   ├── app_picker/
│   │   └── screens/
│   │       └── app_picker_screen.dart
│   ├── lockout/
│   │   ├── screens/
│   │   │   └── lockout_overlay_screen.dart
│   │   ├── widgets/
│   │   │   ├── question_card_widget.dart
│   │   │   ├── streak_indicator_widget.dart
│   │   │   ├── answer_options_widget.dart
│   │   │   └── emergency_bypass_widget.dart
│   │   └── providers/
│   │       └── lockout_provider.dart
│   └── dashboard/
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── stats_screen.dart
│       │   └── settings_screen.dart
│       ├── widgets/
│       │   ├── blocked_apps_card.dart
│       │   ├── weekly_stats_card.dart
│       │   └── settings_tile.dart
│       └── providers/
│           ├── dashboard_provider.dart
│           └── settings_provider.dart
│
└── router/
    └── app_router.dart

android/app/src/main/kotlin/com/example/pflegelock/
├── MainActivity.kt                        # + MethodChannel for UsageStats
└── BootReceiver.kt                        # Restart service on reboot
```

---

## Data Models

### lib/core/models/question.dart

```dart
class Question {
  final int? id;
  final String category;        // 'fachbegriff' | 'berechnung' | 'pflegeplanung' | 'anatomie'
  final String difficulty;      // 'easy' | 'medium' | 'hard'
  final String promptDe;        // Scenario or casual German phrase shown to user
  final String correctAnswer;   // Correct Fachbegriff or answer
  final String wrongOpt1;
  final String wrongOpt2;
  final String wrongOpt3;       // 4 answer options total (1 correct + 3 wrong)
  final String? explanation;    // Shown after answering (optional)
}
```

### lib/core/models/blocked_app.dart

```dart
class BlockedApp {
  final int? id;
  final String packageName;      // e.g. "com.instagram.android"
  final String appName;          // e.g. "Instagram"
  final bool isActive;
  final DateTime? unlockedUntil; // null = locked; future DateTime = temporarily unlocked
}
```

### lib/core/models/user_stats.dart

```dart
class UserStats {
  final int? id;
  final DateTime date;
  final int totalAttempts;
  final int correctCount;
  final int bypassCount;
  final String hardestCategory;
}
```

### lib/core/models/user_settings.dart

```dart
class UserSettings {
  final int streakRequired;        // Default: 3
  final int unlockDurationMinutes; // Default: 30
  final bool serviceEnabled;
  final bool soundEnabled;
  final List<String> activeCategories; // which question categories to pull from
}
```

---

## SQLite Database Schema

Database name: `pflegelock.db` | Version: 1

```sql
CREATE TABLE questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  difficulty TEXT NOT NULL DEFAULT 'medium',
  prompt_de TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  wrong_opt_1 TEXT NOT NULL,
  wrong_opt_2 TEXT NOT NULL,
  wrong_opt_3 TEXT NOT NULL,
  explanation TEXT
);

CREATE TABLE blocked_apps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  package_name TEXT NOT NULL UNIQUE,
  app_name TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  unlocked_until TEXT
);

CREATE TABLE user_stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  total_attempts INTEGER NOT NULL DEFAULT 0,
  correct_count INTEGER NOT NULL DEFAULT 0,
  bypass_count INTEGER NOT NULL DEFAULT 0,
  hardest_category TEXT NOT NULL DEFAULT ''
);

CREATE TABLE user_settings (
  id INTEGER PRIMARY KEY DEFAULT 1,
  streak_required INTEGER NOT NULL DEFAULT 3,
  unlock_duration_minutes INTEGER NOT NULL DEFAULT 30,
  service_enabled INTEGER NOT NULL DEFAULT 1,
  sound_enabled INTEGER NOT NULL DEFAULT 1,
  active_categories TEXT NOT NULL DEFAULT 'fachbegriff,berechnung,pflegeplanung,anatomie'
);
```

---

## Seed Question Bank (50 Questions)

### lib/core/database/seed_data.dart

Check `SharedPreferences` for key `seeded_v1` before inserting. Insert all rows on first launch only.

#### Category: fachbegriff (20 questions)

```dart
// Insert all of the following as Question objects:

// 1
promptDe: "Herr Müller hat blaue Flecken am Rücken"
correctAnswer: "Hämatombildung"
wrongOpt1: "Wundnekrose" | wrongOpt2: "Petechien" | wrongOpt3: "Erythem"
explanation: "Ein Hämatom ist eine Blutansammlung im Gewebe nach Gefäßverletzung."

// 2
promptDe: "Die Wunde riecht unangenehm"
correctAnswer: "Fötider Wundgeruch / Hinweis auf Wundinfektion"
wrongOpt1: "Granulationsgewebe" | wrongOpt2: "Serom" | wrongOpt3: "Epithelisierung"

// 3
promptDe: "Frau Schmidt kann nicht schlucken"
correctAnswer: "Dysphagie"
wrongOpt1: "Dysarthrie" | wrongOpt2: "Aphasie" | wrongOpt3: "Dyspnoe"
explanation: "Dysphagie = Schluckstörung. Wichtig: Aspirationsprophylaxe!"

// 4
promptDe: "Der Patient hat Schwierigkeiten beim Atmen"
correctAnswer: "Dyspnoe"
wrongOpt1: "Tachykardie" | wrongOpt2: "Zyanose" | wrongOpt3: "Orthopnoe"

// 5
promptDe: "Die Haut des Patienten ist gelblich"
correctAnswer: "Ikterus"
wrongOpt1: "Zyanose" | wrongOpt2: "Erythem" | wrongOpt3: "Vitiligo"
explanation: "Ikterus = Gelbfärbung durch Bilirubinerhöhung, oft bei Leber-/Gallenerkrankungen."

// 6
promptDe: "Der Patient hat Wassereinlagerungen in den Beinen"
correctAnswer: "Periphere Ödeme"
wrongOpt1: "Thrombose" | wrongOpt2: "Hämatom" | wrongOpt3: "Lipödem"

// 7
promptDe: "Frau Braun kann ihren linken Arm nicht bewegen"
correctAnswer: "Hemiparese / Hemiplegie links"
wrongOpt1: "Ataxie" | wrongOpt2: "Tremor" | wrongOpt3: "Spastik"

// 8
promptDe: "Der Patient hat Durchfall"
correctAnswer: "Diarrhö"
wrongOpt1: "Obstipation" | wrongOpt2: "Meteorismus" | wrongOpt3: "Flatulenz"

// 9
promptDe: "Der Patient erbricht sich wiederholt"
correctAnswer: "Emesis / rezidivierendes Erbrechen"
wrongOpt1: "Hämatemesis" | wrongOpt2: "Regurgitation" | wrongOpt3: "Nausea"

// 10
promptDe: "Der Patient hat starken Schwindel"
correctAnswer: "Vertigo"
wrongOpt1: "Synkope" | wrongOpt2: "Ataxie" | wrongOpt3: "Nystagmus"

// 11
promptDe: "Die Wunde zeigt rosa, körniges Gewebe"
correctAnswer: "Granulationsgewebe"
wrongOpt1: "Fibrinbelag" | wrongOpt2: "Nekrose" | wrongOpt3: "Mazeration"
explanation: "Granulationsgewebe ist ein gutes Zeichen — die Wunde heilt."

// 12
promptDe: "Der Patient spricht unverständlich / verwaschen"
correctAnswer: "Dysarthrie"
wrongOpt1: "Aphasie" | wrongOpt2: "Dysphagie" | wrongOpt3: "Mutismus"

// 13
promptDe: "Frau Meier uriniert sehr häufig, aber nur wenig"
correctAnswer: "Pollakisurie"
wrongOpt1: "Polyurie" | wrongOpt2: "Oligurie" | wrongOpt3: "Strangurie"

// 14
promptDe: "Der Patient hat Fieber über 38,5 Grad"
correctAnswer: "Hyperthermie / Fieber"
wrongOpt1: "Hypothermie" | wrongOpt2: "Subfebrile Temperatur" | wrongOpt3: "Sepsis"

// 15
promptDe: "Die Haut ist trocken, rissig und schuppt sich"
correctAnswer: "Xerosis cutis"
wrongOpt1: "Intertrigo" | wrongOpt2: "Dermatitis" | wrongOpt3: "Psoriasis"

// 16
promptDe: "Der Patient klagt über brennenden Schmerz beim Wasserlassen"
correctAnswer: "Dysurie"
wrongOpt1: "Pollakisurie" | wrongOpt2: "Hämaturie" | wrongOpt3: "Anurie"

// 17
promptDe: "Der Patient ist kaum wach zu bekommen"
correctAnswer: "Somnolenz / Bewusstseinstrübung"
wrongOpt1: "Koma" | wrongOpt2: "Synkope" | wrongOpt3: "Lethargie"

// 18
promptDe: "Frau Schmidt ist verwirrt und weiß nicht, wo sie ist"
correctAnswer: "Desorientiertheit / Orientierungsstörung"
wrongOpt1: "Demenz" | wrongOpt2: "Delir" | wrongOpt3: "Amnesie"

// 19
promptDe: "Die Wundränder liegen aufeinander, kein Infektzeichen"
correctAnswer: "Primäre Wundheilung (per primam intentionem)"
wrongOpt1: "Sekundärheilung" | wrongOpt2: "Granulationsphase" | wrongOpt3: "Fibrinbelag"

// 20
promptDe: "Der Patient hat Blut im Urin"
correctAnswer: "Hämaturie"
wrongOpt1: "Proteinurie" | wrongOpt2: "Glukosurie" | wrongOpt3: "Pyurie"
```

#### Category: berechnung (10 questions)

```dart
// 21
promptDe: "500ml Infusion über 4 Stunden. Tropfzahl: 20 gtt/ml. Wie viele Tropfen/min?"
correctAnswer: "42 gtt/min"
wrongOpt1: "25 gtt/min" | wrongOpt2: "50 gtt/min" | wrongOpt3: "33 gtt/min"
explanation: "Formel: (500 × 20) / (4 × 60) = 41,6 ≈ 42 gtt/min"

// 22
promptDe: "Patient wiegt 80kg. Dosis: 5mg/kg/Tag in 2 Einzeldosen. Wie viel mg pro Gabe?"
correctAnswer: "200mg"
wrongOpt1: "400mg" | wrongOpt2: "100mg" | wrongOpt3: "250mg"

// 23
promptDe: "1000ml NaCl 0,9% über 8 Stunden. Wie viel ml/Stunde?"
correctAnswer: "125 ml/h"
wrongOpt1: "100 ml/h" | wrongOpt2: "150 ml/h" | wrongOpt3: "80 ml/h"

// 24
promptDe: "Normaler Blutzucker nüchtern — welcher Bereich in mmol/L?"
correctAnswer: "3,9 – 5,5 mmol/L"
wrongOpt1: "6,0 – 8,0 mmol/L" | wrongOpt2: "2,0 – 3,5 mmol/L" | wrongOpt3: "5,6 – 7,0 mmol/L"

// 25
promptDe: "Patient: 170cm, 85kg. Was ist sein BMI und wie wird er eingeordnet?"
correctAnswer: "BMI 29,4 — Präadipositas"
wrongOpt1: "BMI 25,0 — Normalgewicht" | wrongOpt2: "BMI 31,5 — Adipositas Grad I" | wrongOpt3: "BMI 27,0 — Normalgewicht"

// 26
promptDe: "Atemfrequenz des Patienten: 22/min. Wie ist das zu bewerten?"
correctAnswer: "Tachypnoe — erhöht (Normwert Erwachsene: 12–18/min)"
wrongOpt1: "Bradypnoe" | wrongOpt2: "Normalbefund" | wrongOpt3: "Hyperventilation"

// 27
promptDe: "250ml Infusion über 2h mit Infusionspumpe. Wie viel ml/h?"
correctAnswer: "125 ml/h"
wrongOpt1: "100 ml/h" | wrongOpt2: "250 ml/h" | wrongOpt3: "50 ml/h"

// 28
promptDe: "Optimaler systolischer Blutdruck beim Erwachsenen?"
correctAnswer: "< 120 mmHg (optimal)"
wrongOpt1: "< 90 mmHg" | wrongOpt2: "130–139 mmHg" | wrongOpt3: "≥ 140 mmHg"

// 29
promptDe: "Patient trinkt: 250ml Tee, 150ml Wasser, 300ml Suppe. Einfuhr gesamt?"
correctAnswer: "700 ml"
wrongOpt1: "500 ml" | wrongOpt2: "650 ml" | wrongOpt3: "750 ml"

// 30
promptDe: "SpO2 91% gemessen. Wie ist das einzuordnen?"
correctAnswer: "Hypoxämie — Handlungsbedarf, Arzt informieren"
wrongOpt1: "Normalbefund" | wrongOpt2: "Leichte Abweichung, nur beobachten" | wrongOpt3: "Hyperoxie"
```

#### Category: pflegeplanung (10 questions)

```dart
// 31
promptDe: "Welches Pflegeproblem hat ein Patient mit Dekubitus Grad II?"
correctAnswer: "Chronische Wunde mit Hautdefekt — Risiko für Wundinfektion und verzögerte Heilung"
wrongOpt1: "Infektionsgefahr durch Blasenkatheter" | wrongOpt2: "Sturzgefahr" | wrongOpt3: "Mangelernährung"

// 32
promptDe: "Was ist die ERSTE Maßnahme beim Sturz eines Patienten?"
correctAnswer: "Sturzsituation sichern, Patient nicht sofort bewegen, Arzt informieren"
wrongOpt1: "Patient sofort aufheben und ins Bett legen" | wrongOpt2: "Vitalzeichen messen" | wrongOpt3: "Angehörige anrufen"

// 33
promptDe: "Welches Assessmentinstrument wird für das Dekubitusrisiko verwendet?"
correctAnswer: "Braden-Skala"
wrongOpt1: "Barthel-Index" | wrongOpt2: "NRS 2002" | wrongOpt3: "Glasgow Coma Scale"

// 34
promptDe: "ATL steht für?"
correctAnswer: "Aktivitäten des täglichen Lebens (nach Juchli/Roper)"
wrongOpt1: "Ärztliche Therapieleistung" | wrongOpt2: "Allgemeine Therapieleistung" | wrongOpt3: "Aktive Transferleistung"

// 35
promptDe: "ABEDL steht für?"
correctAnswer: "Aktivitäten, Beziehungen und existenzielle Erfahrungen des Lebens (nach Krohwinkel)"
wrongOpt1: "Allgemeine Bedarfserfassung der Lebenssituation" | wrongOpt2: "Ärztliche Behandlungsdokumentation" | wrongOpt3: "Aktivitäten, Bewegung und Ernährung des Lebens"

// 36
promptDe: "Welcher DNQP-Expertenstandard befasst sich mit Sturzprävention?"
correctAnswer: "Expertenstandard Sturzprophylaxe in der Pflege"
wrongOpt1: "Expertenstandard Dekubitusprophylaxe" | wrongOpt2: "Expertenstandard Schmerzmanagement" | wrongOpt3: "Expertenstandard Ernährungsmanagement"

// 37
promptDe: "Was bedeutet Kinästhetik in der Pflege?"
correctAnswer: "Konzept zur Unterstützung von Bewegung und Transfer durch gezielte Wahrnehmungsschulung"
wrongOpt1: "Passive Krankengymnastik" | wrongOpt2: "Lagern zur Dekubitusprophylaxe" | wrongOpt3: "Atemtherapie nach Bobath"

// 38
promptDe: "Was braucht man rechtlich für eine Fixierung / freiheitsentziehende Maßnahme?"
correctAnswer: "Genehmigung durch das Betreuungsgericht (§1906 BGB) — ärztliche Anordnung allein reicht nicht"
wrongOpt1: "Nur ärztliche Anordnung ist ausreichend" | wrongOpt2: "Pflegefachkraft entscheidet selbst" | wrongOpt3: "Angehörige müssen schriftlich zustimmen"

// 39
promptDe: "Was ist ein Pflegebericht?"
correctAnswer: "Pflegerische Verlaufsdokumentation: Beobachtungen, Maßnahmen und Reaktionen des Patienten"
wrongOpt1: "Ärztlicher Übergabebericht" | wrongOpt2: "Medizinische Diagnosestellung" | wrongOpt3: "Abrechnungsbeleg der Pflegekasse"

// 40
promptDe: "Was bedeutet Prophylaxe in der Pflege?"
correctAnswer: "Vorbeugende Pflegemaßnahme zur Verhinderung möglicher Pflegeprobleme"
wrongOpt1: "Behandlung bestehender Erkrankungen" | wrongOpt2: "Rehabilitative Maßnahme" | wrongOpt3: "Beobachtung ohne Intervention"
```

#### Category: anatomie (10 questions)

```dart
// 41
promptDe: "Wo liegt das Herz im Körper?"
correctAnswer: "Im Mediastinum, leicht nach links versetzt (ca. 2/3 links, 1/3 rechts)"
wrongOpt1: "Vollständig in der rechten Thoraxhälfte" | wrongOpt2: "Zentral hinter dem Sternum" | wrongOpt3: "Vollständig links"

// 42
promptDe: "Welche Herzregion pumpt sauerstoffreiches Blut in den Körperkreislauf?"
correctAnswer: "Linke Herzkammer (linker Ventrikel)"
wrongOpt1: "Rechte Herzkammer" | wrongOpt2: "Linkes Vorhof" | wrongOpt3: "Rechter Vorhof"

// 43
promptDe: "Wo wird Insulin produziert?"
correctAnswer: "In den Langerhans-Inseln der Bauchspeicheldrüse (Pankreas)"
wrongOpt1: "In der Leber" | wrongOpt2: "In der Nebenniere" | wrongOpt3: "In der Hypophyse"

// 44
promptDe: "Welcher Nerv steuert das Zwerchfell (Hauptatemmuskel)?"
correctAnswer: "Nervus phrenicus"
wrongOpt1: "Nervus vagus" | wrongOpt2: "Nervus radialis" | wrongOpt3: "Nervus medianus"

// 45
promptDe: "Normaler Atemfrequenz-Bereich beim Erwachsenen?"
correctAnswer: "12 – 18 Atemzüge pro Minute"
wrongOpt1: "18 – 25 pro Minute" | wrongOpt2: "8 – 12 pro Minute" | wrongOpt3: "20 – 30 pro Minute"

// 46
promptDe: "Was ist die Hauptaufgabe der Niere?"
correctAnswer: "Blutfiltration, Urinproduktion und Regulation des Wasser-/Elektrolythaushalts"
wrongOpt1: "Blutbildung (Hämatopoese)" | wrongOpt2: "Ausschließlich Hormonproduktion" | wrongOpt3: "Fettstoffwechsel"

// 47
promptDe: "Wo findet der Gasaustausch in der Lunge statt?"
correctAnswer: "In den Alveolen (Lungenbläschen) — Sauerstoff rein, CO2 raus"
wrongOpt1: "In der Trachea" | wrongOpt2: "In den Hauptbronchien" | wrongOpt3: "Im Pleuraraum"

// 48
promptDe: "Welche Funktionen hat die Leber?"
correctAnswer: "Entgiftung, Galleproduktion, Proteinsynthese und Glykogenspeicher"
wrongOpt1: "Blutfiltration wie die Niere" | wrongOpt2: "Sauerstoffproduktion" | wrongOpt3: "Insulinproduktion"

// 49
promptDe: "Normwert Körpertemperatur rektal beim Erwachsenen?"
correctAnswer: "36,5 – 37,5 °C"
wrongOpt1: "35,0 – 36,0 °C" | wrongOpt2: "38,0 – 39,0 °C" | wrongOpt3: "37,5 – 38,5 °C"

// 50
promptDe: "Wo wird Blut mit Sauerstoff angereichert (oxygeniert)?"
correctAnswer: "In der Lunge — Gasaustausch an den Alveolen mit den Kapillaren"
wrongOpt1: "Im Herz" | wrongOpt2: "In der Leber" | wrongOpt3: "Im Knochenmark"
```

---

## Background Monitor Service

### lib/core/services/monitor_service.dart

Implement a `TaskHandler` using `flutter_foreground_task`:

- Poll every **2 seconds** using the `getForegroundApp` MethodChannel
- Load blocked apps from SQLite (only `is_active = 1`)
- If detected package is in blocked list:
  - Check if `unlocked_until` is null OR has expired (`DateTime.now().isAfter(unlockedUntil)`)
  - If locked → call `OverlayService.showOverlay(packageName)`
  - If within unlock window → do nothing
- Start with a persistent foreground notification:
  - Title: `"PflegeLock aktiv"`
  - Body: `"Dein Lernschutz ist eingeschaltet 🔒"`
  - Channel ID: `pflege_lock_service`

### android/app/src/main/kotlin/.../MainActivity.kt

Register a `MethodChannel` named `pflege_lock/usage_stats` with method `getForegroundApp`:

```kotlin
val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
val time = System.currentTimeMillis()
val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 10000, time)
val sortedStats = stats?.sortedByDescending { it.lastTimeUsed }
result.success(sortedStats?.firstOrNull()?.packageName)
```

### android/app/src/main/kotlin/.../BootReceiver.kt

On `BOOT_COMPLETED`, start `ForegroundTaskService` to re-enable monitoring after reboot.

---

## Overlay Entry Point

### lib/overlay_main.dart

```dart
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const LockoutOverlayScreen(),
      ),
    ),
  );
}
```

### lib/core/services/overlay_service.dart

```dart
// showOverlay(String blockedPackage)
FlutterOverlayWindow.showOverlay(
  width: WindowSize.matchParent,
  height: WindowSize.matchParent,
  flag: OverlayFlag.defaultFlag,
  startPosition: OverlayPosition(0, 0),
);
FlutterOverlayWindow.shareData(blockedPackage);

// hideOverlay()
FlutterOverlayWindow.closeOverlay();
```

---

## Lockout Overlay Screen

### lib/features/lockout/screens/lockout_overlay_screen.dart

**Visual design:**
- Background: `Color(0xFF1A1A2E)` (deep navy)
- Primary accent: `Color(0xFF0D7377)` (medical teal)
- Surface cards: `Color(0xFF16213E)`
- Typography: System default, clean and large for readability

**State machine (Riverpod StateNotifier in lockout_provider.dart):**

| State | Behavior |
|---|---|
| `loading` | Fetching a random question from DB |
| `questionActive` | Showing current question + 4 answer buttons |
| `correctStreak` | ✅ Green flash animation → load next question |
| `wrongAnswer` | ❌ Red flash → streak resets to 0 → load new question |
| `unlocked` | 🎉 Success animation → set `unlocked_until` in DB → call `hideOverlay()` |

**UI elements:**

1. **Streak counter** (top right): `"🔥 2 / 3"` — current streak / required streak
2. **Category badge** (top left): Chip showing `"Fachbegriff"` / `"Berechnung"` etc.
3. **App name being blocked** (subtitle): `"Instagram gesperrt"`
4. **Question card**: White/surface card, question text in large readable font, centered
5. **4 answer buttons**: Full-width `ElevatedButton` stacked vertically, shuffle order each time
   - On tap: show green highlight on correct, red on wrong — 800ms delay — then advance
6. **Emergency bypass** (bottom): Low-emphasis `TextButton` — `"Notfall-Freigabe"`

**Emergency bypass behavior:**
- Show `AlertDialog`: `"Bypass verwenden? Wird als Umgehung gezählt."`
- On confirm: increment `bypass_count` in today's `user_stats`
- Unlock for **5 minutes only** (not full duration)
- No punishment timers — just log it silently and move on

---

## App Picker Screen

### lib/features/app_picker/screens/app_picker_screen.dart

- Use `installed_apps` to fetch all user-installed (non-system) apps
- Show `ListView` with app icon + name + package name
- `Checkbox` per row → insert/update `blocked_apps` table
- Pre-select these if installed:
  - `com.instagram.android` — Instagram
  - `com.zhiliaoapp.musically` — TikTok
  - `com.google.android.youtube` — YouTube
  - `com.twitter.android` — X (Twitter)
  - `com.snapchat.android` — Snapchat
  - `com.facebook.katana` — Facebook
  - `com.netflix.mediaclient` — Netflix
- Floating action button: `"Speichern"` → save and navigate to Home

---

## Dashboard Home Screen

### lib/features/dashboard/screens/home_screen.dart

3-section layout with `BottomNavigationBar` (Home | Statistik | Einstellungen):

**Section 1 — Status card:**
- Large `Card` with toggle switch
- 🟢 `"Schutz aktiv"` or 🔴 `"Schutz deaktiviert"`
- Subtitle: `"5 Apps gesperrt"`
- Toggle calls `MonitorService.start()` / `MonitorService.stop()`

**Section 2 — Today's stats:**
- Total attempts | Correct answers | Bypass count
- Accuracy percentage: `"87% Genauigkeit heute"`

**Section 3 — Blocked apps quick view:**
- Horizontal scrollable `Row` of app icons
- `TextButton` `"Bearbeiten"` → routes to App Picker

**Debug button (remove before release):**
- `"🧪 Overlay testen"` → directly calls `OverlayService.showOverlay()` for testing

---

## Settings Screen

### lib/features/dashboard/screens/settings_screen.dart

All settings read/write from SQLite `user_settings` table (single row, id=1):

| Setting | Widget | Default |
|---|---|---|
| Streak für Freigabe | Slider 1–5 | 3 |
| Freigabedauer | DropdownButton [15, 30, 60, 120 min] | 30 min |
| Sound bei falscher Antwort | Switch | true |
| Schutz aktiv | Switch (master) | true |
| Kategorien aktivieren | Multi-select CheckboxListTile | all active |

---

## Permission Setup Screen (Onboarding)

### lib/features/onboarding/screens/permission_setup_screen.dart

3-step wizard, shown only on first launch (check `SharedPreferences` key `onboarding_done`):

**Step 1 — SYSTEM_ALERT_WINDOW:**
- Title: `"Apps überlagern"`
- Body: `"PflegeLock muss eine Überlagerung über andere Apps anzeigen können."`
- Button: `"Berechtigung erteilen"` → `AppSettings.openAppSettings()` or intent to overlay settings

**Step 2 — USAGE_STATS:**
- Title: `"App-Nutzung erkennen"`
- Body: `"PflegeLock muss erkennen, welche App gerade geöffnet ist."`
- Button: `"Nutzungsdaten erlauben"` → intent `ACTION_USAGE_ACCESS_SETTINGS`

**Step 3 — Battery Optimization:**
- Title: `"Im Hintergrund aktiv bleiben"`
- Body: `"Deaktiviere die Akku-Optimierung, damit PflegeLock immer aktiv bleibt."`
- Button: `"Akku-Optimierung deaktivieren"` → intent `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`

After all 3 steps acknowledged → set `onboarding_done = true` → navigate to App Picker → then Home.

---

## App Constants

### lib/core/constants/app_constants.dart

```dart
class AppConstants {
  static const int defaultStreakRequired = 3;
  static const int defaultUnlockDurationMinutes = 30;
  static const int emergencyBypassDurationMinutes = 5;
  static const int monitorIntervalSeconds = 2;
  static const String dbName = 'pflegelock.db';
  static const int dbVersion = 1;
  static const String seededKey = 'seeded_v1';
  static const String onboardingKey = 'onboarding_done';
  static const String notificationChannelId = 'pflege_lock_service';
  static const String notificationChannelName = 'PflegeLock Service';
  static const String notificationTitle = 'PflegeLock aktiv';
  static const String notificationBody = 'Dein Lernschutz ist eingeschaltet 🔒';
}
```

---

## Router

### lib/router/app_router.dart

Use `go_router`. On app start, check `SharedPreferences` for `onboarding_done`:
- `false` → redirect to `/onboarding`
- `true` → redirect to `/home`

```
/                          → redirect based on onboarding state
/onboarding                → WelcomeScreen
/onboarding/permissions    → PermissionSetupScreen
/onboarding/apps           → AppPickerScreen (initial setup)
/home                      → HomeScreen (ShellRoute with BottomNav)
/home/stats                → StatsScreen
/home/settings             → SettingsScreen
/home/apps                 → AppPickerScreen (edit mode)
```

---

## Build Order (Do This Sequence)

**Phase 1 — Foundation:**
1. Set up `pubspec.yaml` with all dependencies
2. Configure `AndroidManifest.xml` and `build.gradle`
3. Create `MainActivity.kt` with `getForegroundApp` MethodChannel
4. Create `BootReceiver.kt`
5. Implement `DatabaseHelper` with all 4 tables
6. Implement all 4 models with `fromMap`/`toMap`
7. Implement all 3 repositories
8. Seed 50 questions on first launch

**Phase 2 — Core blocker:**
9. Implement `MonitorService` with `flutter_foreground_task`
10. Implement `overlay_main.dart` entry point
11. Implement `OverlayService` (show/hide/shareData)
12. Implement `LockoutOverlayScreen` with full state machine
13. Test overlay with debug button on HomeScreen

**Phase 3 — App shell:**
14. Permission setup wizard (onboarding)
15. App picker screen
16. Home screen with bottom nav
17. Settings screen

**Phase 4 — Polish:**
18. Stats screen with weekly breakdown
19. Correct/wrong answer animations
20. Remove debug test button

---

## What NOT to Include in MVP

- iOS support
- Firebase / backend sync
- Push notifications (FCM)
- In-app purchases
- User-created custom questions (v2)
- Adaptive difficulty / spaced repetition (v2)
- Multi-language support beyond German

---

## Critical Implementation Notes for Cursor

1. **All user-facing strings must be in German.** This app is for German-market nursing trainees.

2. **`overlay_main.dart` is a completely separate Flutter entry point** from `main.dart`. It must use `@pragma("vm:entry-point")` and `runApp()` independently. Never try to navigate from the main app router into the overlay.

3. **The `getForegroundApp` MethodChannel is mandatory.** Do not rely on Flutter packages alone for usage stats on Android 12+ — they are unreliable. Use the native Kotlin `UsageStatsManager` via MethodChannel.

4. **The debug overlay test button on HomeScreen** (calls `OverlayService.showOverlay()` directly) is essential for development. Only remove it in the final release build.

5. **Color theme:**
   - Background: `#1A1A2E`
   - Surface/card: `#16213E`
   - Primary: `#0D7377` (medical teal)
   - On-primary: `#FFFFFF`
   - Correct answer: `#2ECC71`
   - Wrong answer: `#E74C3C`
