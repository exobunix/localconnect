// Stub for local_auth on Flutter Web.
// All call sites in login_screen.dart are already guarded with kIsWeb checks,
// so these stubs are never actually called at runtime on web.

class LocalAuthentication {
  Future<bool> get canCheckBiometrics async => false;
  Future<bool> isDeviceSupported() async => false;
  Future<bool> authenticate({
    required String localizedReason,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async => false;
}

class AuthenticationOptions {
  final bool biometricOnly;
  final bool stickyAuth;
  final bool useErrorDialogs;
  const AuthenticationOptions({
    this.biometricOnly = false,
    this.stickyAuth = false,
    this.useErrorDialogs = true,
  });
}
