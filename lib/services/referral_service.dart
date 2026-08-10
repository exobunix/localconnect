import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class ReferralService {
  static final ReferralService instance = ReferralService._();
  ReferralService._();

  static const String _appName = 'LocalConnect';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.localconnect.app';

  String get playStoreUrl => _playStoreUrl;

  String get shareMessageEnglish =>
      'Looking for trusted local services? I use $_appName to find electricians, plumbers, transport, event services, and many more. Download the app here: $_playStoreUrl';

  String get shareMessageMarathi =>
      'विश्वासार्ह स्थानिक सेवा शोधण्यासाठी $_appName वापरा. इलेक्ट्रिशियन, प्लंबर, वाहतूक, इव्हेंट सेवा आणि अनेक स्थानिक सेवा एका अॅपमध्ये. डाउनलोड करा: $_playStoreUrl';

  String get shareMessage => shareMessageEnglish;

  String getReferralShareMessage(String referralCode) {
    return 'Join me on $_appName – the best app for trusted local services! '
        'Use my referral code $referralCode to get started. '
        'Download: $_playStoreUrl?ref=$referralCode';
  }

  String getReferralLink(String referralCode) =>
      '$_playStoreUrl?ref=$referralCode';

  String getProviderShareMessage({
    required String providerName,
    required String businessName,
    required String category,
    required String providerId,
  }) {
    return '🌟 Check out $businessName on $_appName!\n'
        '$providerName provides excellent $category services in your area.\n'
        'Book now: https://localconne6282.builtwithrocket.new/provider/$providerId\n\n'
        'Powered by $_appName';
  }

  String getProviderProfileLink(String providerId) =>
      'https://localconne6282.builtwithrocket.new/provider/$providerId';

  // ── Referral Code Management ──────────────────────────────────────────────

  Future<String?> getOrCreateReferralCode() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      // Try to get existing code
      final existing = await SupabaseService.instance.client
          .from('user_referral_codes')
          .select('referral_code')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        return existing['referral_code'] as String?;
      }

      // Generate new code via RPC
      final result = await SupabaseService.instance.client.rpc(
        'generate_referral_code',
        params: {'p_user_id': userId},
      );
      return result as String?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getReferralStats() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await SupabaseService.instance.client
          .from('user_referral_codes')
          .select(
            'referral_code, total_clicks, total_registrations, total_rewards_earned',
          )
          .eq('user_id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getReferralRegistrations() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await SupabaseService.instance.client
          .from('referral_registrations')
          .select('*')
          .eq('referrer_user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ── Config ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getReferralConfig() async {
    try {
      final data = await SupabaseService.instance.client
          .from('referral_config')
          .select('*')
          .limit(1)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateReferralConfig(Map<String, dynamic> config) async {
    try {
      await SupabaseService.instance.client
          .from('referral_config')
          .update({...config, 'updated_at': DateTime.now().toIso8601String()})
          .not('id', 'is', null);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  Future<void> logShare({
    required String shareType,
    String? platform,
    String? providerId,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    try {
      await SupabaseService.instance.client.from('share_analytics').insert({
        'user_id': userId,
        'share_type': shareType,
        'platform': platform,
        'provider_id': providerId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getAdminShareAnalytics() async {
    try {
      final totalShares = await SupabaseService.instance.client
          .from('share_analytics')
          .select('id')
          .count(CountOption.exact);

      final appShares = await SupabaseService.instance.client
          .from('share_analytics')
          .select('id')
          .eq('share_type', 'app')
          .count(CountOption.exact);

      final referralShares = await SupabaseService.instance.client
          .from('share_analytics')
          .select('id')
          .eq('share_type', 'referral')
          .count(CountOption.exact);

      final totalReferrals = await SupabaseService.instance.client
          .from('referral_registrations')
          .select('id')
          .count(CountOption.exact);

      final topReferrers = await SupabaseService.instance.client
          .from('user_referral_codes')
          .select(
            'referral_code, total_registrations, total_clicks, user_id, user_profiles!inner(full_name, phone)',
          )
          .order('total_registrations', ascending: false)
          .limit(10);

      return {
        'total_shares': totalShares.count,
        'app_shares': appShares.count,
        'referral_shares': referralShares.count,
        'total_referral_registrations': totalReferrals.count,
        'top_referrers': List<Map<String, dynamic>>.from(topReferrers),
      };
    } catch (e) {
      return {
        'total_shares': 0,
        'app_shares': 0,
        'referral_shares': 0,
        'total_referral_registrations': 0,
        'top_referrers': [],
      };
    }
  }
}
