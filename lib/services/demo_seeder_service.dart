import '../core/testing_mode.dart';
import './supabase_service.dart';

/// Handles seeding and clearing of demo data in Supabase.
/// All operations are guarded by [TestingMode.isEnabled].
/// In production builds (TESTING_MODE absent/false) every method
/// returns immediately without touching the database.
class DemoSeederService {
  DemoSeederService._();
  static final DemoSeederService instance = DemoSeederService._();

  /// Calls the `seed_demo_data()` Supabase RPC function.
  /// Returns one of: 'seeded', 'already_seeded', 'error: ...'
  /// Returns 'disabled' when testing mode is off.
  Future<String> seedDemoData() async {
    if (!TestingMode.isEnabled) return 'disabled';
    try {
      final result = await SupabaseService.instance.client.rpc(
        'seed_demo_data',
      );
      return result?.toString() ?? 'seeded';
    } catch (e) {
      return 'error: $e';
    }
  }

  /// Calls the `clear_demo_data()` Supabase RPC function.
  /// Returns one of: 'cleared', 'no_demo_data', 'error: ...'
  /// Returns 'disabled' when testing mode is off.
  Future<String> clearDemoData() async {
    if (!TestingMode.isEnabled) return 'disabled';
    try {
      final result = await SupabaseService.instance.client.rpc(
        'clear_demo_data',
      );
      return result?.toString() ?? 'cleared';
    } catch (e) {
      return 'error: $e';
    }
  }

  /// Returns true if demo data is already present in the database.
  Future<bool> isDemoDataSeeded() async {
    if (!TestingMode.isEnabled) return false;
    try {
      final result = await SupabaseService.instance.client.rpc(
        'is_demo_data_seeded',
      );
      return result == true;
    } catch (e) {
      return false;
    }
  }
}
