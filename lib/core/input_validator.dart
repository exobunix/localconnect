/// InputValidator — centralized, production-grade input validation
/// Protects against: SQL injection patterns, XSS, oversized inputs,
/// invalid formats, and malicious content.
library;

class InputValidator {
  // ── Length limits ──────────────────────────────────────────────────────────
  static const int maxNameLength = 100;
  static const int maxEmailLength = 254;
  static const int maxPasswordLength = 128;
  static const int maxPhoneLength = 15;
  static const int maxAddressLength = 300;
  static const int maxMessageLength = 2000;
  static const int maxDescriptionLength = 1000;
  static const int maxSearchLength = 100;
  static const int maxPincodeLength = 10;

  // ── Regex patterns ─────────────────────────────────────────────────────────
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );
  static final _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
  static final _pincodeRegex = RegExp(r'^[0-9]{4,10}$');
  static final _nameRegex = RegExp(r"^[a-zA-Z0-9\s\-'.]+$");

  // Patterns that indicate potential injection attempts
  // These are blocked in all user-facing text inputs
  static final _sqlInjectionPatterns = RegExp(
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)|"
    r"(--|;--|/\*|\*/|xp_)|"
    r"(\bOR\b\s+\d+\s*=\s*\d+)|"
    r"(\bAND\b\s+\d+\s*=\s*\d+)",
    caseSensitive: false,
  );

  static final _xssPatterns = RegExp(
    r'<[^>]*>|javascript:|vbscript:|on\w+\s*=',
    caseSensitive: false,
  );

  // ── Sanitization ───────────────────────────────────────────────────────────

  /// Strips leading/trailing whitespace and collapses internal whitespace.
  static String sanitize(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Strips HTML tags and dangerous characters from input.
  static String stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r"""[<>"'`]"""), '');
  }

  /// Returns true if the input contains potential SQL injection patterns.
  static bool hasSqlInjection(String input) {
    return _sqlInjectionPatterns.hasMatch(input);
  }

  /// Returns true if the input contains potential XSS patterns.
  static bool hasXss(String input) {
    return _xssPatterns.hasMatch(input);
  }

  /// Returns true if the input contains any injection attempt.
  static bool isMalicious(String input) {
    return hasSqlInjection(input) || hasXss(input);
  }

  // ── Field validators (return null = valid, String = error message) ─────────

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required.';
    }
    final v = value.trim();
    if (v.length < 2) return 'Name must be at least 2 characters.';
    if (v.length > maxNameLength) return 'Name is too long (max $maxNameLength characters).';
    if (isMalicious(v)) return 'Name contains invalid characters.';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final v = value.trim().toLowerCase();
    if (v.length > maxEmailLength) return 'Email address is too long.';
    if (!_emailRegex.hasMatch(v)) return 'Please enter a valid email address.';
    if (isMalicious(v)) return 'Email contains invalid characters.';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (value.length > maxPasswordLength) {
      return 'Password is too long (max $maxPasswordLength characters).';
    }
    // Strong password: at least one uppercase, one lowercase, one digit
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final v = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!_phoneRegex.hasMatch(v)) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required.';
    }
    final v = value.trim();
    if (!_pincodeRegex.hasMatch(v)) {
      return 'Please enter a valid pincode (4–10 digits).';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required.';
    }
    final v = value.trim();
    if (v.length < 5) return 'Please enter a complete address.';
    if (v.length > maxAddressLength) {
      return 'Address is too long (max $maxAddressLength characters).';
    }
    if (isMalicious(v)) return 'Address contains invalid characters.';
    return null;
  }

  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty.';
    }
    final v = value.trim();
    if (v.length > maxMessageLength) {
      return 'Message is too long (max $maxMessageLength characters).';
    }
    if (hasXss(v)) return 'Message contains invalid content.';
    return null;
  }

  static String? validateDescription(String? value, {bool required = false}) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'Description is required.';
    }
    if (value != null && value.trim().length > maxDescriptionLength) {
      return 'Description is too long (max $maxDescriptionLength characters).';
    }
    if (value != null && hasXss(value)) {
      return 'Description contains invalid content.';
    }
    return null;
  }

  static String? validateAmount(String? value, {double min = 1, double max = 500000}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required.';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) return 'Please enter a valid amount.';
    if (amount < min) return 'Minimum amount is ₹${min.toStringAsFixed(0)}.';
    if (amount > max) return 'Maximum amount is ₹${max.toStringAsFixed(0)}.';
    return null;
  }

  static String? validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Search can be empty
    final v = value.trim();
    if (v.length > maxSearchLength) {
      return 'Search query is too long.';
    }
    if (isMalicious(v)) return 'Search contains invalid characters.';
    return null;
  }

  static String? validateOtp(String? value, {int expectedLength = 6}) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required.';
    }
    final v = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'OTP must contain digits only.';
    if (v.length != expectedLength) return 'OTP must be $expectedLength digits.';
    return null;
  }

  // ── Booking-specific validators ────────────────────────────────────────────

  static String? validateBookingNotes(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final v = value.trim();
    if (v.length > 500) return 'Notes are too long (max 500 characters).';
    if (hasXss(v)) return 'Notes contain invalid content.';
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) return 'City is required.';
    final v = value.trim();
    if (v.length < 2) return 'Please enter a valid city name.';
    if (v.length > 100) return 'City name is too long.';
    if (isMalicious(v)) return 'City name contains invalid characters.';
    return null;
  }

  // ── Password strength indicator ────────────────────────────────────────────

  /// Returns a score 0–4 indicating password strength.
  /// 0 = very weak, 4 = strong
  static int passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  static String passwordStrengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }
}