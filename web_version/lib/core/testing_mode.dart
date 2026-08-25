/// Testing Mode Configuration
///
/// TESTING_MODE is controlled by the TESTING_MODE environment variable.
/// Set TESTING_MODE=true in env.json for QA/development testing.
/// Set TESTING_MODE=false (or leave unset) for production builds.
///
/// When enabled, the demo provider account bypasses admin approval
/// and is automatically routed to the Provider Dashboard.
library;

class TestingMode {
  // ── Environment flags ──────────────────────────────────────────────────────

  /// True only when TESTING_MODE=true is set in env.json / dart-define.
  /// Automatically false in production builds where the flag is absent.
  static const bool isEnabled = bool.fromEnvironment(
    'TESTING_MODE',
    defaultValue: false,
  );

  // ── Demo provider credentials ──────────────────────────────────────────────
  // Credentials are injected via dart-define only when TESTING_MODE=true.
  // No default values are provided to prevent accidental exposure in production.

  static const String demoProviderEmail = String.fromEnvironment(
    'DEMO_PROVIDER_EMAIL',
    defaultValue: '',
  );

  static const String demoProviderPassword = String.fromEnvironment(
    'DEMO_PROVIDER_PASSWORD',
    defaultValue: '',
  );

  // ── QA Developer Panel access ──────────────────────────────────────────────
  // QA panel is only accessible when TESTING_MODE=true.
  // This prevents the QA panel from being accessible in production builds.
  static bool get isQaPanelEnabled => isEnabled;

  // ── Helper ─────────────────────────────────────────────────────────────────

  /// Returns true if [email] belongs to the demo provider account
  /// AND testing mode is currently enabled.
  static bool isDemoProvider(String email) {
    if (!isEnabled || demoProviderEmail.isEmpty) return false;
    return email.trim().toLowerCase() == demoProviderEmail.trim().toLowerCase();
  }
}
