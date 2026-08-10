/// Security Service — centralized security utilities for the LocalConnect app.
/// Handles: credential storage security, session management, security event logging.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './supabase_service.dart';
import '../core/role_guard.dart';

class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  SecurityService._();

  // ── Credential Storage ────────────────────────────────────────────────────
  // SECURITY NOTE: Passwords stored in SharedPreferences for biometric
  // auto-login are encrypted at rest by the OS on both Android (Keystore)
  // and iOS (Keychain) when using flutter_secure_storage.
  // For the current implementation using SharedPreferences, passwords are
  // stored only when the user explicitly enables "Remember Me" and are
  // cleared on logout.

  /// Clears all stored credentials from SharedPreferences.
  /// Called on logout, account deletion, and session expiry.
  static Future<void> clearStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('remember_me');
      await prefs.remove('biometric_enabled');
    } catch (e) {
      debugPrint('SecurityService: Failed to clear credentials: $e');
    }
  }

  /// Full logout: clears session, cached role, and stored credentials.
  static Future<void> secureLogout() async {
    try {
      // 1. Clear cached role (prevents stale role access)
      clearCachedRole();

      // 2. Clear stored credentials
      await clearStoredCredentials();

      // 3. Sign out from Supabase (invalidates JWT)
      await SupabaseService.instance.signOut();
    } catch (e) {
      debugPrint('SecurityService: Logout error: $e');
      // Even if Supabase signOut fails, local state is cleared
    }
  }

  // ── Login Rate Limiting (client-side) ─────────────────────────────────────
  // Server-side rate limiting is enforced by Supabase Auth.
  // Client-side tracking provides UX feedback before server rejection.

  static final Map<String, List<DateTime>> _loginAttempts = {};
  static const int _maxAttemptsPerWindow = 5;
  static const Duration _windowDuration = Duration(minutes: 15);

  /// Records a failed login attempt for the given identifier.
  static void recordFailedAttempt(String identifier) {
    final key = identifier.toLowerCase().trim();
    _loginAttempts[key] ??= [];
    _loginAttempts[key]!.add(DateTime.now());
    // Prune old attempts outside the window
    _loginAttempts[key] = _loginAttempts[key]!
        .where((t) => DateTime.now().difference(t) < _windowDuration)
        .toList();
  }

  /// Returns true if the identifier is currently rate-limited.
  static bool isRateLimited(String identifier) {
    final key = identifier.toLowerCase().trim();
    final attempts = _loginAttempts[key] ?? [];
    final recent = attempts
        .where((t) => DateTime.now().difference(t) < _windowDuration)
        .length;
    return recent >= _maxAttemptsPerWindow;
  }

  /// Returns the number of remaining attempts before lockout.
  static int remainingAttempts(String identifier) {
    final key = identifier.toLowerCase().trim();
    final attempts = _loginAttempts[key] ?? [];
    final recent = attempts
        .where((t) => DateTime.now().difference(t) < _windowDuration)
        .length;
    return (_maxAttemptsPerWindow - recent).clamp(0, _maxAttemptsPerWindow);
  }

  /// Clears rate limit state for an identifier (called on successful login).
  static void clearRateLimit(String identifier) {
    _loginAttempts.remove(identifier.toLowerCase().trim());
  }

  // ── Session Validation ────────────────────────────────────────────────────

  /// Returns true if the current session is valid and not expired.
  static bool isSessionValid() {
    final session = SupabaseService.instance.client.auth.currentSession;
    if (session == null) return false;
    // Check token expiry (Supabase auto-refreshes, but verify here)
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true;
    return DateTime.fromMillisecondsSinceEpoch(
      expiresAt * 1000,
    ).isAfter(DateTime.now());
  }

  // ── Input Sanitization ────────────────────────────────────────────────────

  /// Sanitizes a string for safe display (strips HTML tags).
  static String sanitizeForDisplay(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'[<>]'), '')
        .trim();
  }

  // ── Error Message Sanitization ────────────────────────────────────────────

  /// Converts technical Supabase/auth errors to user-friendly messages.
  /// Prevents internal implementation details from being exposed.
  static String sanitizeErrorMessage(dynamic error) {
    final message = error?.toString() ?? '';

    // Auth errors
    if (message.contains('Invalid login credentials') ||
        message.contains('invalid_credentials') ||
        message.contains('Email not confirmed')) {
      return 'Invalid email or password. Please try again.';
    }
    if (message.contains('Email rate limit exceeded') ||
        message.contains('over_email_send_rate_limit') ||
        message.contains('Too many requests')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }
    if (message.contains('User already registered') ||
        message.contains('already been registered')) {
      return 'An account with this email already exists. Please sign in.';
    }
    if (message.contains('Password should be at least')) {
      return 'Password must be at least 8 characters with uppercase, lowercase, and a number.';
    }
    if (message.contains('network') ||
        message.contains('SocketException') ||
        message.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (message.contains('JWT') ||
        message.contains('token') ||
        message.contains('session')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (message.contains('permission') ||
        message.contains('not authorized') ||
        message.contains('RLS')) {
      return 'You do not have permission to perform this action.';
    }

    // Generic fallback — never expose stack traces or DB details
    if (message.length > 100 ||
        message.contains('postgres') ||
        message.contains('supabase') ||
        message.contains('Exception') ||
        message.contains('Error:')) {
      return 'Something went wrong. Please try again.';
    }

    return message.isNotEmpty
        ? message
        : 'Something went wrong. Please try again.';
  }
}
