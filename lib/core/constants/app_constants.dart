// Application-wide constants

// Hive box names
const String kJournalEntriesBox = 'journalEntries';
const String kSettingsBox = 'settings';

// Secure storage keys
// Note: legacy name 'nook_pin', do not rename to preserve backwards compatibility
const String kPinStorageKey = 'nook_pin';

// Settings keys
const String kIsFirstLaunchKey = 'is_first_launch';

// PIN security parameters
const int kPinLength = 4;
const int kMaxPinAttemptsBeforeLockout = 5;
const int kLockoutDurationSeconds = 30;

// Animation & Route Durations
const Duration kRouteTransitionDuration = Duration(milliseconds: 350);
const Duration kReverseRouteTransitionDuration = Duration(milliseconds: 300);
const Duration kOnboardingTransitionDuration = Duration(milliseconds: 400);
const Duration kCrossfadeDuration = Duration(milliseconds: 260);
const Duration kTypewriterDurationPerChar = Duration(milliseconds: 18);
const Duration kToastDuration = Duration(milliseconds: 2200);
const Duration kToastUndoDuration = Duration(milliseconds: 3000);
const Duration kToastOverlayDuration = Duration(milliseconds: 2500);
const Duration kToastAnimationDuration = Duration(milliseconds: 220);
const Duration kToastFadeDuration = Duration(milliseconds: 200);

// Spacing & Radius Tokens
const double kHorizontalPadding = 24.0;
const double kRadiusCard = 20.0;
const double kRadiusSectionCard = 16.0;
const double kRadiusDialog = 20.0;
const double kRadiusBottomSheet = 24.0;
const double kRadiusPill = 28.0;
const double kSettingsTileMinHeight = 56.0;

// Data Transfer / Import-Export
const int kMaxImportBytes = 10 * 1024 * 1024; // 10 MB
const int kExportSchemaVersion = 1;
const int kMaxImportEntries = 50000;
