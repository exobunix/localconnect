import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  String selectedCity = '';
  String? lastOrderError;

  SupabaseService._();

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnon = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _envUrl.trim().isNotEmpty
      ? _envUrl.trim()
      : 'https://ckyopijftlasebanhhqm.supabase.co';

  static String get supabaseAnonKey => _envAnon.trim().isNotEmpty
      ? _envAnon.trim()
      : 'sb_publishable_pztyR-WMEHV-T7k2MUgrlg_0KkpC75H';

  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<bool> ensureValidSession() async {
    final session = client.auth.currentSession;
    if (session == null) return false;
    if (session.isExpired) {
      try {
        final res = await client.auth.refreshSession();
        return res.session != null;
      } catch (e) {
        debugPrint('Session refresh error: $e');
        return false;
      }
    }
    return true;
  }

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'customer',
    String phone = '',
  }) async {
    // SECURITY: Never allow 'admin' role to be set from client signup.
    // Clamp to 'customer' or 'provider' only.
    final safeRole = (role == 'provider') ? 'provider' : 'customer';

    // Mask email for safe logging
    String maskedEmail = '***';
    final parts = email.split('@');
    if (parts.length == 2) {
      final name = parts[0];
      final domain = parts[1];
      if (name.length <= 2) {
        maskedEmail = '${name.substring(0, 1)}***@$domain';
      } else {
        maskedEmail = '${name.substring(0, 1)}***${name.substring(name.length - 1)}@$domain';
      }
    }

    print('[AUTH SIGNUP] started');
    print('[AUTH SIGNUP] email: $maskedEmail');

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': safeRole,
          if (phone.isNotEmpty) 'phone': phone,
        },
      );

      print('[AUTH SIGNUP] userId: ${response.user?.id ?? "null"}');
      print('[AUTH SIGNUP] session: ${response.session != null}');
      print('[AUTH SIGNUP] success');

      return response;
    } on AuthException catch (e) {
      print('[AUTH SIGNUP ERROR]');
      // Avoid referencing e.code if the compiler doesn't have it on the AuthException class in this version,
      // but standard supabase AuthException has a 'statusCode' and 'message'. Let's log message, statusCode, and code safely.
      String? errorCode;
      try {
        errorCode = (e as dynamic).code;
      } catch (_) {}
      print('code: ${errorCode ?? "null"}');
      print('statusCode: ${e.statusCode ?? "null"}');
      print('message: ${e.message}');
      print('name: AuthException');
      rethrow;
    } catch (e) {
      print('[AUTH SIGNUP ERROR]');
      print('message: $e');
      print('name: GeneralException');
      rethrow;
    }
  }

  /// Signs in with Google OAuth using an ID token (native mobile).
  /// On web, use [client.auth.signInWithOAuth] directly.
  Future<AuthResponse> signInWithGoogleIdToken({
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
  }) async {
    return await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email, {String? redirectTo}) async {
    await client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  // ─── USER PROFILE ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .ilike('email', email.trim())
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await client.rpc('check_email_registered', params: {
        'email_addr': email.trim(),
      });
      return response == true;
    } catch (e) {
      debugPrint('[SupabaseService] isEmailRegistered error: $e');
      return false;
    }
  }

  Future<bool> isPhoneRegistered(String phone, {String? excludeUserId}) async {
    try {
      final response = await client.rpc('check_phone_registered', params: {
        'phone_num': phone.trim(),
        'exclude_user_id': excludeUserId,
      });
      return response == true;
    } catch (e) {
      debugPrint('[SupabaseService] isPhoneRegistered error: $e');
      return false;
    }
  }

  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String fullName,
    String phone = '',
    String role = 'customer',
    String city = 'Pune',
  }) async {
    await client.from('user_profiles').upsert({
      'id': userId,
      'email': email.trim().toLowerCase(),
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'role': role,
      'city': city,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? city,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (city != null) updates['city'] = city;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await client.from('user_profiles').update(updates).eq('id', userId);
  }

  /// Upload a profile photo for a user to Supabase Storage.
  /// Returns the public URL on success, null on failure.
  Future<String?> uploadUserAvatar({
    required String userId,
    required Uint8List imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ext = contentType == 'image/png' ? 'png' : 'jpg';
      final storagePath = 'avatars/$userId.$ext';

      // Upload (upsert so re-upload overwrites)
      await client.storage
          .from('user-avatars')
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      // Get public URL
      final publicUrl =
          client.storage.from('user-avatars').getPublicUrl(storagePath);

      // Persist avatar_url on the user profile row
      await updateUserProfile(userId: userId, avatarUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] uploadUserAvatar error: $e');
      return null;
    }
  }

  /// Upload an image file to a specified public storage bucket.
  /// Returns the public URL on success, null on failure.
  Future<String?> uploadImageToBucket({
    required String bucketName,
    required String storagePath,
    required Uint8List imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      await client.storage
          .from(bucketName)
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl =
          client.storage.from(bucketName).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] uploadImageToBucket error: $e');
      return null;
    }
  }

  // ─── SAVED ADDRESSES ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSavedAddresses() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      final response = await client
          .from('saved_addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> addAddress({
    required String label,
    required String addressLine1,
    String addressLine2 = '',
    required String city,
    String state = 'Maharashtra',
    required String pincode,
    String village = '',
    String taluka = '',
    String district = '',
    String fullAddress = '',
    double? latitude,
    double? longitude,
    String locationMethod = 'manual',
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    final existing = await getSavedAddresses();
    await client.from('saved_addresses').insert({
      'user_id': userId,
      'label': label,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'village': village,
      'taluka': taluka,
      'district': district,
      'full_address': fullAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'location_method': locationMethod,
      'is_default': existing.isEmpty,
    });
  }

  Future<void> updateAddress({
    required String id,
    required String label,
    required String addressLine1,
    String addressLine2 = '',
    required String city,
    String state = 'Maharashtra',
    required String pincode,
    String village = '',
    String taluka = '',
    String district = '',
    String fullAddress = '',
    double? latitude,
    double? longitude,
    String locationMethod = 'manual',
  }) async {
    await client
        .from('saved_addresses')
        .update({
          'label': label,
          'address_line1': addressLine1,
          'address_line2': addressLine2,
          'city': city,
          'state': state,
          'pincode': pincode,
          'village': village,
          'taluka': taluka,
          'district': district,
          'full_address': fullAddress,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'location_method': locationMethod,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteAddress(String id) async {
    await client.from('saved_addresses').delete().eq('id', id);
  }

  Future<void> setDefaultAddress(String id) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client
        .from('saved_addresses')
        .update({'is_default': false})
        .eq('user_id', userId);
    await client
        .from('saved_addresses')
        .update({'is_default': true})
        .eq('id', id);
  }

  // ─── PAYMENT METHODS ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      final response = await client
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> addPaymentMethod({
    required String type,
    required String label,
    required Map<String, dynamic> details,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    final existing = await getPaymentMethods();
    await client.from('payment_methods').insert({
      'user_id': userId,
      'type': type,
      'label': label,
      'details': details,
      'is_default': existing.isEmpty,
    });
  }

  Future<void> deletePaymentMethod(String id) async {
    await client.from('payment_methods').delete().eq('id', id);
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client
        .from('payment_methods')
        .update({'is_default': false})
        .eq('user_id', userId);
    await client
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', id);
  }

  // ─── ORDER PREFERENCES ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getOrderPreferences() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final response = await client
          .from('order_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> upsertOrderPreferences({
    required String preferredTimeSlot,
    required String preferredPaymentType,
    required bool autoReorder,
    required bool notifyOffers,
    required bool notifyOrderUpdates,
    required bool notifyMessages,
    required String language,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('order_preferences').upsert({
      'user_id': userId,
      'preferred_time_slot': preferredTimeSlot,
      'preferred_payment_type': preferredPaymentType,
      'auto_reorder': autoReorder,
      'notify_offers': notifyOffers,
      'notify_order_updates': notifyOrderUpdates,
      'notify_messages': notifyMessages,
      'language': language,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // ─── SERVICE PROVIDERS ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProviders({
    String? category,
    String? city,
    int limit = 20,
  }) async {
    try {
      var query = client
          .from('service_providers')
          .select()
          .eq('is_active', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }

      final response = await query
          .order('rating', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getProviderById(String providerId) async {
    try {
      final response = await client
          .from('service_providers')
          .select()
          .eq('id', providerId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyProviders({
    String? city,
    int limit = 6,
  }) async {
    try {
      var query = client
          .from('service_providers')
          .select()
          .eq('is_active', true);

      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }

      final response = await query
          .order('rating', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProvidersByCategory(
    String category,
  ) async {
    try {
      final response = await client
          .from('service_providers')
          .select('*, charges:provider_service_charges(*)')
          .ilike('category', '%$category%')
          .eq('is_active', true)
          .order('rating', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      try {
        final response = await client
            .from('service_providers')
            .select()
            .ilike('category', '%$category%')
            .order('rating', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        return [];
      }
    }
  }

  // ─── ORDERS ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      var query = client
          .from('orders')
          .select(
            '*, provider:provider_id(id, business_name, phone, rating, image_url, city, category, address)',
          )
          .eq('customer_id', userId);

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAdminAllOrders() async {
    try {
      final response = await client
          .from('orders')
          .select(
            '*, '
            'provider:provider_id(id, business_name, owner_name, phone, rating, image_url, city, category, address), '
            'customer:customer_id(id, full_name, email, phone)',
          )
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response).map((o) {
        final customer = o['customer'] as Map<String, dynamic>?;
        return {
          ...o,
          'customer_name': customer?['full_name'] ?? customer?['email'] ?? o['customer_id'] ?? 'Customer',
        };
      }).toList();
    } catch (e) {
      debugPrint('getAdminAllOrders error: $e');
      return [];
    }
  }

  Future<void> adminUpdateOrder({
    required String orderId,
    required Map<String, dynamic> updates,
  }) async {
    await client.from('orders').update(updates).eq('id', orderId);
  }

  // ─── ORDER TRACKING ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final response = await client
          .from('orders')
          .select(
            '*, provider:provider_id(id, business_name, owner_name, phone, whatsapp, rating, completed_orders, image_url, city, category, address, lat, lng)',
          )
          .eq('id', orderId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrderTracking(String orderId) async {
    try {
      final response = await client
          .from('order_tracking')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> upsertOrderTracking({
    required String orderId,
    required String currentStep,
    double? providerLat,
    double? providerLng,
    int? etaMinutes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'order_id': orderId,
        'current_step': currentStep,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (providerLat != null) updates['provider_lat'] = providerLat;
      if (providerLng != null) updates['provider_lng'] = providerLng;
      if (etaMinutes != null) updates['eta_minutes'] = etaMinutes;

      // Set timestamp for the step
      switch (currentStep) {
        case 'confirmed':
          updates['confirmed_at'] = DateTime.now().toIso8601String();
          break;
        case 'provider_accepted':
          updates['accepted_at'] = DateTime.now().toIso8601String();
          break;
        case 'en_route':
          updates['en_route_at'] = DateTime.now().toIso8601String();
          break;
        case 'delivered':
          updates['delivered_at'] = DateTime.now().toIso8601String();
          break;
      }

      await client
          .from('order_tracking')
          .upsert(updates, onConflict: 'order_id');
    } catch (e) {
      // ignore
    }
  }

  Future<Map<String, dynamic>?> reorderService(
    Map<String, dynamic> existingOrder,
  ) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final now = DateTime.now();
      final orderNumber =
          'ORD-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final response = await client
          .from('orders')
          .insert({
            'order_number': orderNumber,
            'customer_id': userId,
            'provider_id': existingOrder['provider_id'],
            'provider_name': existingOrder['provider_name'],
            'service': existingOrder['service'],
            'category': existingOrder['category'],
            'scheduled_date':
                '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
            'scheduled_time': existingOrder['scheduled_time'] ?? '10:00 AM',
            'amount': existingOrder['amount'],
            'status': 'pending',
            'notes': existingOrder['notes'] ?? '',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createOrder({
    required String providerName,
    required String service,
    required String category,
    required String scheduledDate,
    required String scheduledTime,
    required String amount,
    String? providerId,
    String? addressId,
    String? promoCode,
    double? discountAmount,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      lastOrderError = null;
      final userId = currentUser?.id;
      if (userId == null) {
        lastOrderError = 'User not logged in';
        return null;
      }

      final orderNumber =
          'ORD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Parse amount string (e.g. "₹500", "500.00") to numeric for DB
      final numericAmount =
          double.tryParse(amount.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

      // Fetch customer name to populate the orders row
      String customerName = '';
      try {
        final profile = await client
            .from('user_profiles')
            .select('full_name')
            .eq('id', userId)
            .maybeSingle();
        customerName = profile?['full_name'] as String? ?? '';
      } catch (_) {}

      final otp = (1000 + Random().nextInt(9000)).toString();
      final finalNotes = notes != null && notes.isNotEmpty
          ? '$notes (Completion OTP: $otp)'
          : 'Completion OTP: $otp';

      // Validate providerId UUID format
      String? safeProviderId = providerId;
      if (providerId != null && providerId.isNotEmpty) {
        final uuidRegExp = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
        if (!uuidRegExp.hasMatch(providerId)) {
          safeProviderId = null;
        }
      }

      final insertData = <String, dynamic>{
        'order_number': orderNumber,
        'customer_id': userId,
        'provider_id': safeProviderId,
        'provider_name': providerName,
        'service': service,
        'category': category,
        'scheduled_date': scheduledDate,
        'scheduled_time': scheduledTime,
        'amount': numericAmount,
        'customer_name': customerName,
        'status': 'pending',
        'notes': finalNotes,
        // Store payment method and initial payment_status
        if (paymentMethod != null) 'payment_method': paymentMethod,
        'payment_status': paymentMethod == 'razorpay' ? 'pending' : 'paid',
      };

      Map<String, dynamic> response;
      try {
        response = await client
            .from('orders')
            .insert(insertData)
            .select()
            .single();
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('22p02') || errStr.contains('23503') || errStr.contains('foreign key') || errStr.contains('uuid')) {
          // Retry inserting without provider_id
          final retryData = Map<String, dynamic>.from(insertData);
          retryData['provider_id'] = null;
          response = await client
              .from('orders')
              .insert(retryData)
              .select()
              .single();
        } else {
          rethrow;
        }
      }

      // Notify provider of new order request
      if (safeProviderId != null && safeProviderId.isNotEmpty) {
        // Look up the provider's user_id
        try {
          final providerRow = await client
              .from('service_providers')
              .select('user_id')
              .eq('id', safeProviderId)
              .maybeSingle();
          final providerUserId = providerRow?['user_id'] as String?;
          if (providerUserId != null && providerUserId.isNotEmpty) {
            await insertOrderNotification(
              userId: providerUserId,
              title: '🔔 New Booking Request',
              body: '$customerName booked $service ($orderNumber).',
              type: 'booking',
              metadata: {
                'order_id': response['id'],
                'order_number': orderNumber,
                'customer_name': customerName,
                'service': service,
                'amount': numericAmount.toString(),
                'is_continuous_alert': true,
              },
            );
          }
        } catch (_) {}
      }

      // Notify customer of order placement confirmation
      try {
        await insertOrderNotification(
          userId: userId,
          title: '📅 Booking Placed (#$orderNumber)',
          body: 'Your booking for $service has been placed successfully.',
          type: 'booking',
          metadata: {
            'order_id': response['id'],
            'order_number': orderNumber,
          },
        );
      } catch (_) {}

      // Play sound chime for user
      try {
        NotificationService.instance.playNotificationSound();
      } catch (_) {}

      return response;
    } catch (e) {
      print('createOrder error: $e');
      lastOrderError = e.toString();
      return null;
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    int? rating,
  }) async {
    final updates = <String, dynamic>{'status': status};
    if (rating != null) updates['rating'] = rating;

    await client.from('orders').update(updates).eq('id', orderId);

    // Look up order info to send real-time notification
    try {
      final order = await client
          .from('orders')
          .select('customer_id, provider_id, service, order_number')
          .eq('id', orderId)
          .maybeSingle();

      if (order != null) {
        final customerId = order['customer_id'] as String?;
        final service = order['service'] as String? ?? 'Service';
        final orderNum = order['order_number'] as String? ?? '';

        if (customerId != null && customerId.isNotEmpty) {
          final statusLabel = status == 'confirmed'
              ? 'Confirmed'
              : status == 'in_progress'
                  ? 'In Progress'
                  : status == 'completed'
                      ? 'Completed'
                      : status == 'cancelled'
                          ? 'Cancelled'
                          : status;

          await insertOrderNotification(
            userId: customerId,
            title: 'Booking $statusLabel ($orderNum)',
            body: 'Your service $service is now $statusLabel.',
            type: 'booking_status',
            metadata: {'order_id': orderId, 'status': status},
          );
        }
      }
    } catch (_) {}
  }

  /// Insert a notification row for a user (used to notify customers/providers of order events).
  Future<void> insertOrderNotification({
    String? userId,
    required String title,
    required String body,
    String type = 'booking',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final row = <String, dynamic>{
        'title': title,
        'body': body,
        'type': type,
        'is_read': false,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };
      if (userId != null && userId.isNotEmpty) {
        row['user_id'] = userId;
      }
      await client.from('notifications').insert(row);
    } catch (_) {}
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _deduplicateNotifications(List<dynamic> rawList) {
    final seenIds = <String>{};
    final seenKeys = <String>{};
    final unique = <Map<String, dynamic>>[];

    for (final item in rawList) {
      final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String? ?? '';
      final title = map['title'] as String? ?? '';
      final body = map['body'] as String? ?? '';
      final rawDate = map['created_at'] as String? ?? '';
      final dateKey = rawDate.length >= 16 ? rawDate.substring(0, 16) : rawDate;
      final contentKey = '${title}_${body}_$dateKey';

      if (id.isNotEmpty && seenIds.contains(id)) continue;
      if (title.isNotEmpty && seenKeys.contains(contentKey)) continue;

      if (id.isNotEmpty) seenIds.add(id);
      if (title.isNotEmpty) seenKeys.add(contentKey);
      unique.add(map);
    }
    return unique;
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final userId = currentUser?.id;

      if (userId != null) {
        try {
          final response = await client
              .from('notifications')
              .select()
              .or('user_id.eq.$userId,user_id.is.null')
              .order('created_at', ascending: false)
              .limit(60);
          final list = _deduplicateNotifications(response);
          if (list.isNotEmpty) return list;
        } catch (e) {
          debugPrint('[SupabaseService] getNotifications error: $e');
        }
      }

      final fallback = await client
          .from('notifications')
          .select()
          .filter('user_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(40);
      return _deduplicateNotifications(fallback);
    } catch (e) {
      debugPrint('[SupabaseService] getNotifications error: $e');
      return [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsRead() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return 0;

      final response = await client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // ─── ADMIN ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final providersResp = await client.from('service_providers').select('id');
      final ordersResp = await client.from('orders').select('id');
      final usersResp = await client.from('user_profiles').select('id');
      final pendingResp = await client
          .from('orders')
          .select('id')
          .eq('status', 'pending');
      final completedResp = await client
          .from('orders')
          .select('id')
          .eq('status', 'completed');
      final pendingApprovalsResp = await client
          .from('service_providers')
          .select('id')
          .eq('is_verified', false);

      return {
        'totalProviders': providersResp.length,
        'totalOrders': ordersResp.length,
        'totalUsers': usersResp.length,
        'pendingOrders': pendingResp.length,
        'completedOrders': completedResp.length,
        'pendingApprovals': pendingApprovalsResp.length,
      };
    } catch (e) {
      return {
        'totalProviders': 0,
        'totalOrders': 0,
        'totalUsers': 0,
        'pendingOrders': 0,
        'completedOrders': 0,
        'pendingApprovals': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getPendingProviders() async {
    try {
      final response = await client
          .from('service_providers')
          .select()
          .eq('registration_status', 'pending_approval')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> approveProvider(String providerId) async {
    await client
        .from('service_providers')
        .update({
          'is_verified': true,
          'is_active': true,
          'registration_status': 'approved',
        })
        .eq('id', providerId);
  }

  // ─── ADMIN: COMPLAINTS ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminComplaints({
    String? status,
    int limit = 20,
  }) async {
    try {
      if (status != null && status.isNotEmpty) {
        final response = await client
            .from('complaints')
            .select()
            .eq('status', status)
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else {
        final response = await client
            .from('complaints')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> resolveComplaint({
    required String complaintId,
    String adminNote = '',
  }) async {
    await client
        .from('complaints')
        .update({
          'status': 'resolved',
          'admin_note': adminNote,
          'resolved_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', complaintId);
  }

  Future<void> submitComplaint({
    required String customerId,
    required String customerName,
    String? providerId,
    String providerName = '',
    String? orderId,
    required String issue,
    String severity = 'medium',
  }) async {
    final now = DateTime.now();
    final num =
        'CMP${now.year}${now.millisecondsSinceEpoch.toString().substring(7)}';
    await client.from('complaints').insert({
      'complaint_number': num,
      'customer_id': customerId,
      'customer_name': customerName,
      'provider_id': providerId,
      'provider_name': providerName,
      'order_id': orderId,
      'issue': issue,
      'severity': severity,
      'status': 'open',
    });
  }

  // ─── ADMIN: ANALYTICS ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminWeeklyAnalytics() async {
    try {
      final now = DateTime.now();
      final days = <String>[];
      final ordersData = <double>[];
      final revenueData = <double>[];

      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final start = DateTime(day.year, day.month, day.day);
        final end = start.add(const Duration(days: 1));

        final resp = await client
            .from('orders')
            .select('amount, status')
            .gte('created_at', start.toIso8601String())
            .lt('created_at', end.toIso8601String());

        final orders = List<Map<String, dynamic>>.from(resp);
        double revenue = 0;
        for (final o in orders) {
          final amt = o['amount'];
          if (amt != null) {
            final parsed =
                double.tryParse(
                  amt.toString().replaceAll(',', '').replaceAll('₹', ''),
                ) ??
                0;
            revenue += parsed;
          }
        }

        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        days.add(dayNames[day.weekday - 1]);
        ordersData.add(orders.length.toDouble());
        revenueData.add(revenue / 1000); // in thousands
      }

      return {'days': days, 'orders': ordersData, 'revenue': revenueData};
    } catch (e) {
      return {
        'days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        'orders': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        'revenue': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      };
    }
  }

  // ─── ADMIN: ORDER METRICS ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminOrderMetrics() async {
    try {
      // Status distribution
      final allOrders = await client
          .from('orders')
          .select('status, amount, created_at');
      final orders = List<Map<String, dynamic>>.from(allOrders);

      int pending = 0, completed = 0, cancelled = 0, other = 0;
      double totalRevenue = 0;

      for (final o in orders) {
        final status = (o['status'] as String? ?? '').toLowerCase();
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'completed':
            completed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          default:
            other++;
        }
        final amt = o['amount'];
        if (amt != null) {
          totalRevenue +=
              double.tryParse(
                amt.toString().replaceAll(',', '').replaceAll('₹', ''),
              ) ??
              0;
        }
      }

      // 30-day order timeline (daily counts)
      final now = DateTime.now();
      final timelineDays = <String>[];
      final timelineCounts = <double>[];

      for (int i = 29; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final start = DateTime(day.year, day.month, day.day);
        final end = start.add(const Duration(days: 1));

        final dayOrders = orders.where((o) {
          final createdAt = o['created_at'] as String?;
          if (createdAt == null) return false;
          final dt = DateTime.tryParse(createdAt);
          if (dt == null) return false;
          return dt.isAfter(start) && dt.isBefore(end);
        }).length;

        // Only label every 5th day to avoid clutter
        if (i % 5 == 0 || i == 0) {
          timelineDays.add('${day.day}/${day.month}');
        } else {
          timelineDays.add('');
        }
        timelineCounts.add(dayOrders.toDouble());
      }

      return {
        'pending': pending,
        'completed': completed,
        'cancelled': cancelled,
        'other': other,
        'totalRevenue': totalRevenue,
        'timelineDays': timelineDays,
        'timelineCounts': timelineCounts,
      };
    } catch (e) {
      return {
        'pending': 0,
        'completed': 0,
        'cancelled': 0,
        'other': 0,
        'totalRevenue': 0.0,
        'timelineDays': List.generate(30, (i) => ''),
        'timelineCounts': List.generate(30, (_) => 0.0),
      };
    }
  }

  // ─── ADMIN: QUOTATION FUNNEL ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getQuotationFunnelData() async {
    try {
      final allQuotations = await client.from('quotations').select('status');
      final quotations = List<Map<String, dynamic>>.from(allQuotations);

      int sent = 0, accepted = 0, completed = 0;

      for (final q in quotations) {
        final status = (q['status'] as String? ?? '').toLowerCase();
        switch (status) {
          case 'sent':
          case 'negotiating':
            sent++;
            break;
          case 'accepted':
            sent++;
            accepted++;
            break;
          case 'completed':
            sent++;
            accepted++;
            completed++;
            break;
          case 'rejected':
          case 'expired':
            sent++;
            break;
        }
      }

      // Count booked = orders created from quotations (ORD-Q- prefix)
      int booked = 0;
      try {
        final quotationOrders = await client
            .from('orders')
            .select('id, status')
            .like('id', 'ORD-Q-%');
        final orderList = List<Map<String, dynamic>>.from(quotationOrders);
        booked = orderList.length;
        // completed from orders perspective
        final completedOrders = orderList
            .where(
              (o) =>
                  (o['status'] as String? ?? '').toLowerCase() == 'completed',
            )
            .length;
        // Use order-based completed count if higher
        if (completedOrders > completed) completed = completedOrders;
      } catch (_) {}

      return {
        'sent': sent,
        'accepted': accepted,
        'booked': booked,
        'completed': completed,
      };
    } catch (e) {
      return {'sent': 0, 'accepted': 0, 'booked': 0, 'completed': 0};
    }
  }

  // ─── ADMIN: REPORTS ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminReportData() async {
    try {
      final statsResp = await getAdminStats();
      // Revenue total
      final ordersResp = await client
          .from('orders')
          .select('amount, status, category, created_at, order_number');
      final orders = List<Map<String, dynamic>>.from(ordersResp);

      double totalRevenue = 0;
      final statusCounts = <String, int>{};
      final categoryCounts = <String, int>{};

      for (final o in orders) {
        final status = o['status'] as String? ?? 'pending';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        final cat = o['category'] as String? ?? 'Other';
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;

        if (status == 'completed') {
          final amt = o['amount'];
          if (amt != null) {
            final parsed =
                double.tryParse(
                  amt.toString().replaceAll(',', '').replaceAll('₹', ''),
                ) ??
                0;
            totalRevenue += parsed;
          }
        }
      }

      // Top categories sorted
      final topCats =
          categoryCounts.entries
              .map((e) => {'category': e.key, 'count': e.value})
              .toList()
            ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Open complaints count
      final complaintsResp = await client
          .from('complaints')
          .select('id')
          .eq('status', 'open');

      // Recent activity (last 8 orders + complaints)
      final recentOrders = orders.take(4).map((o) {
        final createdAt = o['created_at'] != null
            ? DateTime.tryParse(o['created_at'].toString())
            : null;
        return {
          'type': 'order',
          'title': 'Order ${o['order_number'] ?? ''}',
          'subtitle': '${o['category'] ?? ''} • ${o['status'] ?? ''}',
          'time': createdAt != null ? _timeAgo(createdAt) : '',
        };
      }).toList();

      final recentComplaints = await client
          .from('complaints')
          .select('complaint_number, customer_name, severity, created_at')
          .order('created_at', ascending: false)
          .limit(4);

      final complaintActivity =
          List<Map<String, dynamic>>.from(recentComplaints).map((c) {
            final createdAt = c['created_at'] != null
                ? DateTime.tryParse(c['created_at'].toString())
                : null;
            return {
              'type': 'complaint',
              'title': 'Complaint ${c['complaint_number'] ?? ''}',
              'subtitle':
                  '${c['customer_name'] ?? ''} • ${c['severity'] ?? ''}',
              'time': createdAt != null ? _timeAgo(createdAt) : '',
            };
          }).toList();

      final allActivity = [...recentOrders, ...complaintActivity]
        ..sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

      return {
        'stats': {
          ...statsResp,
          'totalRevenue': totalRevenue,
          'openComplaints': complaintsResp.length,
        },
        'ordersByStatus': statusCounts,
        'topCategories': topCats,
        'recentActivity': allActivity,
      };
    } catch (e) {
      return {
        'stats': {},
        'ordersByStatus': {},
        'topCategories': [],
        'recentActivity': [],
      };
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ─── ADMIN: USERS ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminAllUsers() async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> adminToggleUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    await client
        .from('user_profiles')
        .update({'is_active': isActive})
        .eq('id', userId);
  }

  // ─── ADMIN: PROVIDERS ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminAllProviders() async {
    try {
      final response = await client
          .from('service_providers')
          .select('*, user:user_id(email, full_name)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response).map((p) {
        final user = p['user'] as Map<String, dynamic>?;
        return {
          ...p,
          'full_name': p['owner_name'] ?? p['full_name'] ?? user?['full_name'] ?? p['business_name'] ?? 'Provider',
          'status': p['registration_status'] ?? (p['is_active'] == true ? 'approved' : 'pending'),
          'total_orders': p['completed_orders'] ?? p['total_orders'] ?? 0,
          'earnings': p['earnings_total'] ?? p['earnings'] ?? 0,
          'email': user?['email'] ?? p['email'] ?? '',
          'joined': p['member_since'] ?? p['created_at'] ?? '',
        };
      }).toList();
    } catch (e) {
      try {
        final response = await client
            .from('service_providers')
            .select()
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response).map((p) {
          return {
            ...p,
            'full_name': p['owner_name'] ?? p['business_name'] ?? 'Provider',
            'status': p['registration_status'] ?? (p['is_active'] == true ? 'approved' : 'pending'),
            'total_orders': p['completed_orders'] ?? 0,
            'earnings': p['earnings_total'] ?? 0,
            'joined': p['member_since'] ?? p['created_at'] ?? '',
          };
        }).toList();
      } catch (err) {
        print('getAdminAllProviders error: $err');
        return [];
      }
    }
  }

  Future<void> adminUpdateProviderStatus({
    required String providerId,
    required String status,
  }) async {
    await client
        .from('service_providers')
        .update({
          'registration_status': status,
          'is_active': status == 'approved',
        })
        .eq('id', providerId);
  }

  // ─── KYC DOCUMENTS ────────────────────────────────────────────────────────

  /// Provider: get their own KYC documents
  Future<List<Map<String, dynamic>>> getMyKycDocuments(
    String providerId,
  ) async {
    try {
      final response = await client
          .from('kyc_documents')
          .select()
          .eq('provider_id', providerId)
          .order('uploaded_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Provider: upload a KYC document to storage and save record
  Future<void> uploadKycDocument({
    required String providerId,
    required String docType,
    required List<int> imageBytes,
    required String fileName,
    required String mimeType,
    String? docNumber,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final storagePath = '$userId/$providerId/${docType}_$timestamp.$ext';

    // Upload to storage
    await client.storage
        .from('kyc-documents')
        .uploadBinary(
          storagePath,
          Uint8List.fromList(imageBytes),
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    // Get signed URL (private bucket)
    final signedUrl = await client.storage
        .from('kyc-documents')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 7); // 7 days

    // Delete existing doc of same type if any
    await client
        .from('kyc_documents')
        .delete()
        .eq('provider_id', providerId)
        .eq('doc_type', docType);

    // Insert new record
    final insertData = <String, dynamic>{
      'provider_id': providerId,
      'user_id': userId,
      'doc_type': docType,
      'doc_url': signedUrl,
      'storage_path': storagePath,
      'status': 'pending',
      'uploaded_at': DateTime.now().toIso8601String(),
    };
    if (docNumber != null && docNumber.isNotEmpty) {
      insertData['doc_number'] = docNumber;
    }
    await client.from('kyc_documents').insert(insertData);

    // Update provider kyc_status to pending
    await client
        .from('service_providers')
        .update({'kyc_status': 'pending'})
        .eq('id', providerId);
  }

  /// Admin: get all KYC documents with provider info
  Future<List<Map<String, dynamic>>> getAdminAllKycDocuments() async {
    try {
      final response = await client
          .from('kyc_documents')
          .select(
            '*, service_providers(id, full_name, business_name, category, city)',
          )
          .order('uploaded_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Admin: approve or reject a KYC document
  Future<void> reviewKycDocument({
    required String docId,
    required String status,
    String? rejectionReason,
    required String providerId,
    required List<Map<String, dynamic>> allDocs,
  }) async {
    final adminId = currentUser?.id;

    final updates = <String, dynamic>{
      'status': status,
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': adminId,
    };
    if (rejectionReason != null) {
      updates['rejection_reason'] = rejectionReason;
    }

    await client.from('kyc_documents').update(updates).eq('id', docId);

    // Recalculate provider kyc_status
    final providerDocs = await client
        .from('kyc_documents')
        .select('status')
        .eq('provider_id', providerId);

    final docList = List<Map<String, dynamic>>.from(providerDocs);
    final allApproved =
        docList.isNotEmpty && docList.every((d) => d['status'] == 'approved');
    final anyRejected = docList.any((d) => d['status'] == 'rejected');
    final anyPending = docList.any((d) => d['status'] == 'pending');

    String kycStatus;
    if (allApproved) {
      kycStatus = 'approved';
    } else if (anyRejected) {
      kycStatus = 'rejected';
    } else if (anyPending) {
      kycStatus = 'pending';
    } else {
      kycStatus = 'not_submitted';
    }

    await client
        .from('service_providers')
        .update({'kyc_status': kycStatus})
        .eq('id', providerId);
  }

  // ─── ADMIN: BANNERS ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminBanners() async {
    try {
      final response = await client
          .from('banner_ads')
          .select()
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> adminCreateBanner({
    required String title,
    String subtitle = '',
    String imageUrl = '',
  }) async {
    await client.from('banner_ads').insert({
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'is_active': true,
    });
  }

  Future<void> adminUpdateBanner({
    required String id,
    required String title,
    String subtitle = '',
    String imageUrl = '',
  }) async {
    await client
        .from('banner_ads')
        .update({
          'title': title,
          'subtitle': subtitle,
          'image_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> adminToggleBanner({
    required String id,
    required bool isActive,
  }) async {
    await client
        .from('banner_ads')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> adminDeleteBanner(String id) async {
    await client.from('banner_ads').delete().eq('id', id);
  }

  // ─── ADMIN: CATEGORIES ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminCategories() async {
    try {
      final cats = await client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);
      final subs = await client
          .from('subcategories')
          .select()
          .order('sort_order', ascending: true);

      final subsByCategory = <String, List<Map<String, dynamic>>>{};
      for (final s in List<Map<String, dynamic>>.from(subs)) {
        final catId = s['category_id'] as String;
        subsByCategory.putIfAbsent(catId, () => []).add(s);
      }

      return List<Map<String, dynamic>>.from(cats).map((c) {
        return {...c, 'subcategories': subsByCategory[c['id']] ?? []};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns only active (visible) categories with their active subcategories.
  /// Used by customer home screen, provider registration, and search.
  Future<List<Map<String, dynamic>>> getActiveCategories() async {
    try {
      final cats = await client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      // Only return active subcategories so newly hidden ones disappear immediately
      final subs = await client
          .from('subcategories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final subsByCategory = <String, List<Map<String, dynamic>>>{};
      for (final s in List<Map<String, dynamic>>.from(subs)) {
        final catId = s['category_id'] as String;
        subsByCategory.putIfAbsent(catId, () => []).add(s);
      }

      return List<Map<String, dynamic>>.from(cats).map((c) {
        return {...c, 'subcategories': subsByCategory[c['id']] ?? []};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> adminUpsertCategory({
    required String id,
    required String name,
    String nameMarathi = '',
    bool isActive = true,
    String description = '',
    String imageUrl = '',
  }) async {
    await client.from('categories').upsert({
      'id': id,
      'name': name,
      'name_marathi': nameMarathi,
      'is_active': isActive,
      'description': description,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> adminToggleCategory({
    required String id,
    required bool isActive,
  }) async {
    await client
        .from('categories')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> adminDeleteCategory(String id) async {
    // Delete dependent subcategories first to prevent foreign key errors
    await client.from('subcategories').delete().eq('category_id', id);
    // Then delete the category itself
    await client.from('categories').delete().eq('id', id);
  }

  Future<void> adminAddSubcategory({
    required String categoryId,
    required String id,
    required String name,
    String nameMarathi = '',
    String imageUrl = '',
    String description = '',
  }) async {
    await client.from('subcategories').insert({
      'id': id,
      'category_id': categoryId,
      'name': name,
      'name_marathi': nameMarathi,
      'image_url': imageUrl,
      'description': description,
    });
  }

  Future<void> adminUpdateSubcategory({
    required String id,
    required String name,
    String nameMarathi = '',
    String imageUrl = '',
    String description = '',
  }) async {
    await client.from('subcategories').update({
      'name': name,
      'name_marathi': nameMarathi,
      'image_url': imageUrl,
      'description': description,
    }).eq('id', id);
  }

  Future<void> adminDeleteSubcategory(String id) async {
    await client.from('subcategories').delete().eq('id', id);
  }



  Future<void> adminToggleSubcategory({
    required String id,
    required bool isActive,
  }) async {
    await client
        .from('subcategories')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // ─── PROVIDER ONBOARDING ──────────────────────────────────────────────────

  Future<bool> isProviderOnboardingComplete(String userId) async {
    try {
      final response = await client
          .from('service_providers')
          .select('onboarding_completed')
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return false;
      return response['onboarding_completed'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> createProviderProfile({
    required String userId,
    required String businessName,
    required String ownerName,
    required String category,
    required String subcategory,
    required String address,
    required String city,
    required String phone,
    required String whatsapp,
    required List<Map<String, String>> documents,
  }) async {
    // Ensure user_profiles row exists (upsert to handle missing profile)
    await client.from('user_profiles').upsert({
      'id': userId,
      'email': currentUser?.email ?? '',
      'full_name': ownerName,
      'phone': phone,
      'role': 'provider',
    }, onConflict: 'id');

    // Upsert service_providers row
    final response = await client
        .from('service_providers')
        .upsert({
          'user_id': userId,
          'business_name': businessName,
          'owner_name': ownerName,
          'category': category,
          'subcategory': subcategory,
          'address': address,
          'city': city,
          'phone': phone,
          'whatsapp': whatsapp,
          'onboarding_completed': true,
          'is_active': true,
          'member_since': DateTime.now().year.toString(),
        }, onConflict: 'user_id')
        .select('id')
        .single();

    final providerId = response['id'] as String;

    // Update user profile phone
    await client
        .from('user_profiles')
        .update({'phone': phone, 'role': 'provider'})
        .eq('id', userId);

    // Insert documents if any
    if (documents.isNotEmpty) {
      final docRows = documents
          .map(
            (doc) => {
              'provider_id': providerId,
              'user_id': userId,
              'document_type': doc['type'] ?? '',
              'document_name': doc['name'] ?? '',
              'document_url': doc['url'] ?? '',
            },
          )
          .toList();

      await client.from('provider_documents').insert(docRows);
    }
  }

  // ─── PROVIDER REGISTRATION FLOW ───────────────────────────────────────────

  /// Get provider profile by user ID (returns null if not found)
  Future<Map<String, dynamic>?> getProviderProfileByUserId(
    String userId,
  ) async {
    try {
      final response = await client
          .from('service_providers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get provider registration status: null | 'pending_approval' | 'approved' | 'rejected'
  Future<String?> getProviderRegistrationStatus(String userId) async {
    try {
      final response = await client
          .from('service_providers')
          .select('registration_status, onboarding_completed')
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      return response['registration_status'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Submit provider profile + category approval request in one transaction
  Future<void> registerProviderWithApproval({
    required String userId,
    required String businessName,
    required String ownerName,
    required String category,
    required String subcategory,
    required String address,
    required String city,
    required String phone,
    required String whatsapp,
    required List<Map<String, String>> documents,
    required String approvalReason,
  }) async {
    // Ensure user_profiles row exists
    await client.from('user_profiles').upsert({
      'id': userId,
      'email': currentUser?.email ?? '',
      'full_name': ownerName,
      'phone': phone,
      'role': 'provider',
    }, onConflict: 'id');

    // Upsert service_providers row with pending_approval status
    final response = await client
        .from('service_providers')
        .upsert({
          'user_id': userId,
          'business_name': businessName,
          'owner_name': ownerName,
          'category': category,
          'subcategory': subcategory,
          'address': address,
          'city': city,
          'phone': phone,
          'whatsapp': whatsapp,
          'onboarding_completed': true,
          'is_active': false,
          'registration_status': 'pending_approval',
          'member_since': DateTime.now().year.toString(),
        }, onConflict: 'user_id')
        .select('id')
        .single();

    final providerId = response['id'] as String;

    // Update user profile
    await client
        .from('user_profiles')
        .update({'phone': phone, 'role': 'provider'})
        .eq('id', userId);

    // Insert documents if any
    if (documents.isNotEmpty) {
      final docRows = documents
          .map(
            (doc) => {
              'provider_id': providerId,
              'user_id': userId,
              'document_type': doc['type'] ?? '',
              'document_name': doc['name'] ?? '',
              'document_url': doc['url'] ?? '',
            },
          )
          .toList();
      await client.from('provider_documents').insert(docRows);
    }

    // Create category approval request (safe try-catch so legacy RLS won't block registration)
    try {
      await client.from('category_approval_requests').upsert({
        'provider_id': providerId,
        'user_id': userId,
        'category': category,
        'subcategory': subcategory,
        'reason': approvalReason,
        'status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'provider_id');
    } catch (e) {
      debugPrint('[registerProviderWithApproval] category_approval_requests note: $e');
    }
  }

  /// Get category approval request for a provider
  Future<Map<String, dynamic>?> getCategoryApprovalRequest(
    String userId,
  ) async {
    try {
      final response = await client
          .from('category_approval_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      // Fallback: read directly from service_providers
      try {
        final sp = await client
            .from('service_providers')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (sp != null) {
          return {
            'provider_id': sp['id'],
            'user_id': userId,
            'category': sp['category'],
            'subcategory': sp['subcategory'],
            'status': sp['registration_status'] ?? 'pending',
          };
        }
      } catch (_) {}
      return null;
    }
  }

  /// Admin: approve a provider's category request
  Future<void> approveProviderRegistration({
    required String providerId,
    required String requestId,
    String adminNote = '',
  }) async {
    await client
        .from('service_providers')
        .update({
          'registration_status': 'approved',
          'is_verified': true,
          'is_active': true,
        })
        .eq('id', providerId);

    await client
        .from('category_approval_requests')
        .update({
          'status': 'approved',
          'admin_note': adminNote,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  /// Admin: reject a provider's category request
  Future<void> rejectProviderRegistration({
    required String providerId,
    required String requestId,
    String adminNote = '',
  }) async {
    await client
        .from('service_providers')
        .update({'registration_status': 'rejected', 'is_active': false})
        .eq('id', providerId);

    await client
        .from('category_approval_requests')
        .update({
          'status': 'rejected',
          'admin_note': adminNote,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  // ─── MESSAGING ────────────────────────────────────────────────────────────

  /// Get or create a conversation between current user and a provider user
  Future<Map<String, dynamic>?> getOrCreateConversation({
    required String providerUserId,
    String? providerServiceId,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      // Try to find existing conversation
      final existing = await client
          .from('conversations')
          .select()
          .eq('customer_id', userId)
          .eq('provider_id', providerUserId)
          .maybeSingle();

      if (existing != null) return existing;

      // Create new conversation
      final response = await client
          .from('conversations')
          .insert({
            'customer_id': userId,
            'provider_id': providerUserId,
            'provider_service_id': providerServiceId,
            'last_message': '',
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get all conversations for the current user
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final response = await client
          .from('conversations')
          .select(
            '*, customer:customer_id(id, full_name, avatar_url), provider:provider_id(id, full_name, avatar_url), service_provider:provider_service_id(id, business_name, image_url, category)',
          )
          .or('customer_id.eq.$userId,provider_id.eq.$userId')
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Send a message in a conversation
  Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final response = await client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
            'is_read': false,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Mark all messages in a conversation as read (for current user as receiver)
  Future<void> markMessagesRead(String conversationId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;

      await client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      // silent fail
    }
  }

  /// Get total unread message count for current user
  Future<int> getUnreadMessageCount() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return 0;

      // Get all conversations where user is a participant
      final conversations = await client
          .from('conversations')
          .select('id')
          .or('customer_id.eq.$userId,provider_id.eq.$userId');

      if (conversations.isEmpty) return 0;

      final convIds = (conversations as List)
          .map((c) => c['id'] as String)
          .toList();

      // Count unread messages sent by others
      final response = await client
          .from('messages')
          .select('id')
          .inFilter('conversation_id', convIds)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  /// Subscribe to new messages in a conversation
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    return client
        .channel('messages_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to conversation list updates
  RealtimeChannel subscribeToConversations({
    required void Function() onUpdate,
  }) {
    final userId = currentUser?.id ?? '';
    return client
        .channel('conversations_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();
  }

  // ─── REVIEWS ──────────────────────────────────────────────────────────────

  Future<bool> submitReview({
    required String orderId,
    required String providerId,
    required int rating,
    required String reviewText,
    required String providerName,
    required String service,
    List<int>? photoBytes,
    String? photoFileName,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return false;

      String? photoUrl;

      // Upload review photo if provided
      if (photoBytes != null && photoBytes.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = (photoFileName != null && photoFileName.contains('.'))
            ? photoFileName.split('.').last
            : 'jpg';
        final storagePath = 'reviews/$userId/${timestamp}_review.$ext';

        await client.storage
            .from('provider-photos')
            .uploadBinary(
              storagePath,
              Uint8List.fromList(photoBytes),
              fileOptions: FileOptions(
                contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
                upsert: false,
              ),
            );

        photoUrl = client.storage
            .from('provider-photos')
            .getPublicUrl(storagePath);
      }

      await client.from('reviews').insert({
        'order_id': orderId,
        'customer_id': userId,
        'provider_id': providerId,
        'rating': rating,
        'review_text': reviewText,
        'provider_name': providerName,
        'service': service,
        if (photoUrl != null) 'photo_url': photoUrl,
      });

      // Mark order as reviewed
      await client.from('orders').update({'reviewed': true}).eq('id', orderId);

      // Create a notification for the customer
      await createNotification(
        userId: userId,
        title: 'Review Submitted',
        body: 'Your review for $providerName has been submitted. Thank you!',
        type: 'review',
        relatedId: orderId,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasReviewedOrder(String orderId) async {
    try {
      final response = await client
          .from('reviews')
          .select('id')
          .eq('order_id', orderId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getProviderReviews(
    String providerId,
  ) async {
    try {
      final response = await client
          .from('reviews')
          .select(
            'id, rating, review_text, service, photo_url, created_at, customer_id, user_profiles!customer_id(full_name, avatar_url)',
          )
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback without join if user_profiles join fails
      try {
        final response = await client
            .from('reviews')
            .select()
            .eq('provider_id', providerId)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        return [];
      }
    }
  }

  // ─── NOTIFICATIONS (ENHANCED) ─────────────────────────────────────────────

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? relatedId,
  }) async {
    try {
      await client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'is_read': false,
        if (relatedId != null) 'related_id': relatedId,
      });
    } catch (e) {
      // silent fail
    }
  }

  RealtimeChannel subscribeToNotifications({
    required void Function() onUpdate,
    void Function(Map<String, dynamic> payload)? onDelete,
  }) {
    final channel = client.channel('notifications_global_channel');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            debugPrint('[Realtime] Postgres change on notifications: ${payload.eventType}');
            onUpdate();
          },
        )
        .onBroadcast(
          event: 'notification_deleted',
          callback: (payload) {
            debugPrint('[Realtime] Broadcast notification_deleted: $payload');
            if (onDelete != null) {
              onDelete(payload);
            }
            onUpdate();
          },
        )
        .onBroadcast(
          event: 'notification_created',
          callback: (payload) {
            debugPrint('[Realtime] Broadcast notification_created: $payload');
            onUpdate();
          },
        )
        .subscribe();

    return channel;
  }

  /// Permanently delete a notification by ID and/or title+body across all platforms
  Future<void> deleteNotification({String? id, String? title, String? body}) async {
    try {
      if (id != null && id.isNotEmpty) {
        await client.from('notifications').delete().eq('id', id);
      }
      if (title != null && title.isNotEmpty) {
        if (body != null && body.isNotEmpty) {
          await client.from('notifications').delete().eq('title', title).eq('body', body);
        } else {
          await client.from('notifications').delete().eq('title', title);
        }
      }

      // Broadcast real-time deletion event to all connected clients immediately
      try {
        final ch = client.channel('notifications_global_channel');
        await ch.sendBroadcastMessage(
          event: 'notification_deleted',
          payload: {
            if (id != null) 'id': id,
            if (title != null) 'title': title,
            if (body != null) 'body': body,
          },
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[SupabaseService] deleteNotification error: $e');
    }
  }

  // ─── PROVIDER DASHBOARD ───────────────────────────────────────────────────

  /// Get the service_providers record for the currently logged-in provider user
  Future<Map<String, dynamic>?> getMyProviderProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final response = await client
          .from('service_providers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get all orders for a given provider (by service_providers.id)
  Future<List<Map<String, dynamic>>> getProviderOrders(
    String providerId,
  ) async {
    try {
      final response = await client
          .from('orders')
          .select('*, customer:customer_id(id, full_name, phone, avatar_url)')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback without join
      try {
        final response = await client
            .from('orders')
            .select()
            .eq('provider_id', providerId)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        return [];
      }
    }
  }

  /// Get only bookings created from accepted quotations (ORD-Q- prefix)
  /// for a given provider, excluding completed/cancelled ones.
  Future<List<Map<String, dynamic>>> getProviderQuotationBookings(
    String providerId,
  ) async {
    try {
      final response = await client
          .from('orders')
          .select()
          .eq('provider_id', providerId)
          .like('order_number', 'ORD-Q-%')
          .not('status', 'in', '("completed","cancelled")')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback: fetch all provider orders and filter client-side
      try {
        final all = await getProviderOrders(providerId);
        return all.where((o) {
          final num = (o['order_number'] as String?) ?? '';
          final status = (o['status'] as String?) ?? '';
          return num.startsWith('ORD-Q-') &&
              status != 'completed' &&
              status != 'cancelled';
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Update the status of an order (provider accept/reject/complete)
  Future<bool> updateProviderOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      // Fetch the order to get customer_id and provider info before updating
      final orderData = await client
          .from('orders')
          .select('customer_id, provider_id, order_number')
          .eq('id', orderId)
          .maybeSingle();

      await client
          .from('orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Insert a notification row for the customer so the badge count updates
      if (orderData != null) {
        final customerId = orderData['customer_id'] as String?;
        final orderNumber = orderData['order_number'] as String? ?? orderId;
        if (customerId != null && customerId.isNotEmpty) {
          final notifTitle = _notifTitleForStatus(newStatus);
          final notifBody = _notifBodyForStatus(newStatus, orderNumber);
          if (notifTitle != null) {
            try {
              await client.from('notifications').insert({
                'user_id': customerId,
                'title': notifTitle,
                'body': notifBody,
                'type': 'booking',
                'is_read': false,
              });
            } catch (_) {
              // Notification insert failure should not block the status update
            }
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  String? _notifTitleForStatus(String status) {
    switch (status) {
      case 'active':
      case 'confirmed':
        return '✅ Booking Accepted!';
      case 'in_progress':
        return '🔧 Service In Progress';
      case 'completed':
        return '🎉 Booking Completed!';
      case 'cancelled':
        return '❌ Booking Cancelled';
      default:
        return null;
    }
  }

  String _notifBodyForStatus(String status, String orderNumber) {
    switch (status) {
      case 'active':
      case 'confirmed':
        return 'Your booking $orderNumber has been accepted by the provider.';
      case 'in_progress':
        return 'The provider has started working on your booking $orderNumber.';
      case 'completed':
        return 'Your booking $orderNumber has been completed. Please rate your experience.';
      case 'cancelled':
        return 'Your booking $orderNumber has been cancelled.';
      default:
        return 'Your booking $orderNumber status has been updated.';
    }
  }

  /// Subscribe to real-time order changes for a provider
  RealtimeChannel subscribeToProviderOrders({
    required String providerId,
    required void Function() onUpdate,
  }) {
    return client
        .channel('provider_orders_$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();
  }

  // ─── PROVIDER PHOTOS ──────────────────────────────────────────────────────

  /// Get all photos for a provider (public)
  Future<List<Map<String, dynamic>>> getProviderPhotos(
    String providerId,
  ) async {
    try {
      final response = await client
          .from('provider_photos')
          .select()
          .eq('provider_id', providerId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Upload a photo to Supabase storage and save record to provider_photos
  Future<Map<String, dynamic>?> uploadProviderPhoto({
    required String providerId,
    required List<int> imageBytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final storagePath = '$userId/$providerId/${timestamp}_$fileName';

      // Upload to storage bucket
      await client.storage
          .from('provider-photos')
          .uploadBinary(
            storagePath,
            Uint8List.fromList(imageBytes),
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      // Get public URL
      final publicUrl = client.storage
          .from('provider-photos')
          .getPublicUrl(storagePath);

      // Check if this is the first photo (make it cover)
      final existing = await getProviderPhotos(providerId);
      final isCover = existing.isEmpty;

      // Save record to DB
      final record = await client
          .from('provider_photos')
          .insert({
            'provider_id': providerId,
            'user_id': userId,
            'photo_url': publicUrl,
            'storage_path': storagePath,
            'caption': '',
            'sort_order': existing.length,
            'is_cover': isCover,
          })
          .select()
          .single();

      return record;
    } catch (e) {
      return null;
    }
  }

  /// Delete a provider photo from storage and DB
  Future<void> deleteProviderPhoto({
    required String photoId,
    required String storagePath,
  }) async {
    try {
      // Delete from storage
      if (storagePath.isNotEmpty) {
        await client.storage.from('provider-photos').remove([storagePath]);
      }
      // Delete DB record
      await client.from('provider_photos').delete().eq('id', photoId);
    } catch (e) {
      // silent fail
    }
  }

  /// Set a photo as the cover photo for a provider
  Future<void> setProviderCoverPhoto({
    required String photoId,
    required String providerId,
  }) async {
    try {
      // Unset all cover photos for this provider
      await client
          .from('provider_photos')
          .update({'is_cover': false})
          .eq('provider_id', providerId);
      // Set the selected one as cover
      await client
          .from('provider_photos')
          .update({'is_cover': true})
          .eq('id', photoId);
    } catch (e) {
      // silent fail
    }
  }

  // ─── PROVIDER AVAILABILITY ────────────────────────────────────────────────

  /// Get working hours for a provider (all 7 days)
  Future<List<Map<String, dynamic>>> getProviderWorkingHours(
    String providerId,
  ) async {
    try {
      final response = await client
          .from('provider_working_hours')
          .select()
          .eq('provider_id', providerId)
          .order('day_of_week');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Upsert working hours for a specific day
  Future<void> upsertWorkingHours({
    required String providerId,
    required int dayOfWeek,
    required bool isOpen,
    required String openTime,
    required String closeTime,
    int slotDurationMinutes = 60,
  }) async {
    try {
      await client.from('provider_working_hours').upsert({
        'provider_id': providerId,
        'day_of_week': dayOfWeek,
        'is_open': isOpen,
        'open_time': openTime,
        'close_time': closeTime,
        'slot_duration_minutes': slotDurationMinutes,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'provider_id,day_of_week');
    } catch (e) {
      // silent fail
    }
  }

  /// Get days off for a provider (future dates)
  Future<List<Map<String, dynamic>>> getProviderDaysOff(
    String providerId,
  ) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final response = await client
          .from('provider_days_off')
          .select()
          .eq('provider_id', providerId)
          .gte('off_date', todayStr)
          .order('off_date');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Add a day off for a provider
  Future<void> addProviderDayOff({
    required String providerId,
    required DateTime date,
    String reason = '',
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await client.from('provider_days_off').upsert({
        'provider_id': providerId,
        'off_date': dateStr,
        'reason': reason,
      }, onConflict: 'provider_id,off_date');
    } catch (e) {
      // silent fail
    }
  }

  /// Remove a day off
  Future<void> removeProviderDayOff(String dayOffId) async {
    try {
      await client.from('provider_days_off').delete().eq('id', dayOffId);
    } catch (e) {
      // silent fail
    }
  }

  /// Get available booking slots for a provider on a specific date
  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required String providerId,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Check if it's a day off
      final daysOff = await client
          .from('provider_days_off')
          .select()
          .eq('provider_id', providerId)
          .eq('off_date', dateStr);
      if ((daysOff as List).isNotEmpty) return [];

      // Get working hours for this day
      final dayOfWeek = date.weekday % 7; // 0=Sun, 1=Mon...6=Sat
      final workingHours = await client
          .from('provider_working_hours')
          .select()
          .eq('provider_id', providerId)
          .eq('day_of_week', dayOfWeek)
          .maybeSingle();

      if (workingHours == null || workingHours['is_open'] == false) return [];

      // Generate slots from working hours
      final openTime = workingHours['open_time'] as String? ?? '09:00';
      final closeTime = workingHours['close_time'] as String? ?? '18:00';
      final slotDuration =
          (workingHours['slot_duration_minutes'] as int?) ?? 60;

      final generatedSlots = _generateTimeSlots(
        openTime: openTime,
        closeTime: closeTime,
        durationMinutes: slotDuration,
        date: date,
      );

      if (generatedSlots.isEmpty) return [];

      // Get booked slots from DB
      final bookedSlots = await client
          .from('provider_booking_slots')
          .select()
          .eq('provider_id', providerId)
          .eq('slot_date', dateStr)
          .eq('is_booked', true);

      final bookedTimes = Set<String>.from(
        (bookedSlots as List).map((s) => s['slot_time'] as String? ?? ''),
      );

      // Also get manually blocked slots
      final blockedSlots = await client
          .from('provider_booking_slots')
          .select()
          .eq('provider_id', providerId)
          .eq('slot_date', dateStr)
          .eq('is_available', false);

      final blockedTimes = Set<String>.from(
        (blockedSlots as List).map((s) => s['slot_time'] as String? ?? ''),
      );

      return generatedSlots.map((slot) {
        final timeStr = slot['time'] as String;
        final isBooked =
            bookedTimes.contains(timeStr) ||
            bookedTimes.contains('$timeStr:00');
        final isBlocked =
            blockedTimes.contains(timeStr) ||
            blockedTimes.contains('$timeStr:00');
        return {
          ...slot,
          'is_available': !isBooked && !isBlocked,
          'is_booked': isBooked,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<Map<String, dynamic>> _generateTimeSlots({
    required String openTime,
    required String closeTime,
    required int durationMinutes,
    required DateTime date,
  }) {
    try {
      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');
      var current = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(openParts[0]),
        int.parse(openParts[1]),
      );
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(closeParts[0]),
        int.parse(closeParts[1]),
      );

      final slots = <Map<String, dynamic>>[];
      while (current.isBefore(end)) {
        final hour = current.hour.toString().padLeft(2, '0');
        final minute = current.minute.toString().padLeft(2, '0');
        final timeStr = '$hour:$minute';
        final isPast = current.isBefore(DateTime.now());
        slots.add({
          'time': timeStr,
          'display': _formatDisplayTime(current.hour, current.minute),
          'is_past': isPast,
        });
        current = current.add(Duration(minutes: durationMinutes));
      }
      return slots;
    } catch (e) {
      return [];
    }
  }

  String _formatDisplayTime(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  /// Book a slot (called when order is placed)
  Future<void> bookSlot({
    required String providerId,
    required DateTime date,
    required String slotTime,
    required String orderId,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await client.from('provider_booking_slots').upsert({
        'provider_id': providerId,
        'slot_date': dateStr,
        'slot_time': slotTime,
        'is_available': false,
        'is_booked': true,
        'order_id': orderId,
      }, onConflict: 'provider_id,slot_date,slot_time');
    } catch (e) {
      // silent fail
    }
  }

  /// Toggle a slot's availability (provider can block/unblock)
  Future<void> toggleSlotAvailability({
    required String providerId,
    required DateTime date,
    required String slotTime,
    required bool isAvailable,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await client.from('provider_booking_slots').upsert({
        'provider_id': providerId,
        'slot_date': dateStr,
        'slot_time': slotTime,
        'is_available': isAvailable,
        'is_booked': false,
      }, onConflict: 'provider_id,slot_date,slot_time');
    } catch (e) {
      // silent fail
    }
  }

  // ─── PROVIDER OFFERS ──────────────────────────────────────────────────────

  /// Get active offers across all providers for home screen display
  Future<List<Map<String, dynamic>>> getActiveOffers({int limit = 5}) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await client
          .from('provider_offers')
          .select()
          .eq('is_active', true)
          .gt('expires_at', now)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Fetch all active (non-expired) offers for a provider
  Future<List<Map<String, dynamic>>> getProviderOffers(
    String providerId,
  ) async {
    try {
      final response = await client
          .from('provider_offers')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Fetch only active non-expired offers for a provider (customer view)
  Future<List<Map<String, dynamic>>> getActiveProviderOffers(
    String providerId,
  ) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await client
          .from('provider_offers')
          .select()
          .eq('provider_id', providerId)
          .eq('is_active', true)
          .gt('expires_at', now)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Create a new offer
  Future<Map<String, dynamic>?> createProviderOffer({
    required String providerId,
    required String title,
    String? description,
    required String discountType,
    required double discountValue,
    String? promoCode,
    double? minOrderAmount,
    double? maxDiscountAmount,
    required DateTime startsAt,
    required DateTime expiresAt,
    int? usageLimit,
  }) async {
    try {
      final response = await client
          .from('provider_offers')
          .insert({
            'provider_id': providerId,
            'title': title,
            'description': description,
            'discount_type': discountType,
            'discount_value': discountValue,
            'promo_code': promoCode,
            'min_order_amount': minOrderAmount ?? 0,
            'max_discount_amount': maxDiscountAmount,
            'starts_at': startsAt.toIso8601String(),
            'expires_at': expiresAt.toIso8601String(),
            'is_active': true,
            'usage_limit': usageLimit,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing offer
  Future<bool> updateProviderOffer({
    required String offerId,
    String? title,
    String? description,
    String? discountType,
    double? discountValue,
    String? promoCode,
    double? minOrderAmount,
    double? maxDiscountAmount,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool? isActive,
    int? usageLimit,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (discountType != null) updates['discount_type'] = discountType;
      if (discountValue != null) updates['discount_value'] = discountValue;
      if (promoCode != null) updates['promo_code'] = promoCode;
      if (minOrderAmount != null) updates['min_order_amount'] = minOrderAmount;
      if (maxDiscountAmount != null) {
        updates['max_discount_amount'] = maxDiscountAmount;
      }
      if (startsAt != null) updates['starts_at'] = startsAt.toIso8601String();
      if (expiresAt != null) {
        updates['expires_at'] = expiresAt.toIso8601String();
      }
      if (isActive != null) updates['is_active'] = isActive;
      if (usageLimit != null) updates['usage_limit'] = usageLimit;
      await client.from('provider_offers').update(updates).eq('id', offerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete an offer
  Future<bool> deleteProviderOffer(String offerId) async {
    try {
      await client.from('provider_offers').delete().eq('id', offerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle offer active status
  Future<bool> toggleOfferActive(String offerId, bool isActive) async {
    try {
      await client
          .from('provider_offers')
          .update({'is_active': isActive})
          .eq('id', offerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── PROMO CODE VALIDATION ────────────────────────────────────────────────

  Future<Map<String, dynamic>?> validatePromoCode({
    required String promoCode,
    required String providerId,
    required double orderAmount,
  }) async {
    try {
      final response = await client
          .from('provider_offers')
          .select()
          .eq('provider_id', providerId)
          .eq('is_active', true)
          .ilike('promo_code', promoCode)
          .maybeSingle();

      if (response == null) return null;

      // Check expiry
      final expiresAt = DateTime.tryParse(
        response['expires_at'] as String? ?? '',
      );
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        return {'error': 'Promo code has expired'};
      }

      // Check usage limit
      final usageLimit = response['usage_limit'] as int?;
      final usageCount = response['usage_count'] as int? ?? 0;
      if (usageLimit != null && usageCount >= usageLimit) {
        return {'error': 'Promo code usage limit reached'};
      }

      // Check minimum order amount
      final minOrder =
          (response['min_order_amount'] as num?)?.toDouble() ?? 0.0;
      if (orderAmount < minOrder) {
        return {'error': 'Minimum order amount ₹${minOrder.toInt()} required'};
      }

      // Calculate discount
      final discountType = response['discount_type'] as String? ?? 'percentage';
      final discountValue =
          (response['discount_value'] as num?)?.toDouble() ?? 0.0;
      final maxDiscount = (response['max_discount_amount'] as num?)?.toDouble();

      double discount = 0.0;
      if (discountType == 'percentage') {
        discount = orderAmount * discountValue / 100;
        if (maxDiscount != null && discount > maxDiscount) {
          discount = maxDiscount;
        }
      } else {
        discount = discountValue;
      }

      return {
        'valid': true,
        'discount': discount,
        'title': response['title'],
        'discount_type': discountType,
        'discount_value': discountValue,
        'offer_id': response['id'],
      };
    } catch (e) {
      return null;
    }
  }

  // ─── VIRTUAL SHOP ─────────────────────────────────────────────────────────

  Future<void> updateVirtualShop({
    String? providerId,
    required String businessName,
    required String ownerName,
    required String description,
    String? profilePhotoUrl,
    String? coverBannerUrl,
    required String contactNumber,
    required String whatsappNumber,
    required String address,
    required String serviceArea,
    String? mapLocation,
    required String workingHours,
    required int yearsExperience,
    required double startingPrice,
    required List<String> servicesOffered,
    required List<String> galleryPhotos,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{
      'business_name': businessName,
      'owner_name': ownerName,
      'business_description': description,
      'contact_number': contactNumber,
      'phone': contactNumber,
      'whatsapp_number': whatsappNumber,
      'whatsapp': whatsappNumber,
      'address': address,
      'service_area': serviceArea,
      'working_hours': workingHours,
      'years_experience': yearsExperience,
      'starting_price': startingPrice,
      'services_offered': servicesOffered,
      'gallery_photos': galleryPhotos,
      'virtual_shop_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (profilePhotoUrl != null) {
      updates['image_url'] = profilePhotoUrl;
      updates['business_logo_url'] = profilePhotoUrl;
    }
    if (coverBannerUrl != null) updates['cover_image_url'] = coverBannerUrl;
    if (mapLocation != null) updates['map_location'] = mapLocation;

    if (providerId != null) {
      await client
          .from('service_providers')
          .update(updates)
          .eq('id', providerId);
    } else {
      await client
          .from('service_providers')
          .update(updates)
          .eq('user_id', userId);
    }
  }

  // ─── ENQUIRIES ────────────────────────────────────────────────────────────

  Future<void> sendEnquiry({
    required String providerId,
    required String title,
    required String description,
    String category = '',
    String subcategory = '',
  }) async {
    final userId = currentUser?.id;

    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'status': 'pending',
    };
    if (userId != null &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(userId)) {
      data['customer_id'] = userId;
    }
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(providerId)) {
      data['provider_id'] = providerId;
    }

    await client.from('enquiries').insert(data);
  }

  Future<List<Map<String, dynamic>>> getCustomerEnquiries() async {
    try {
      final userId = currentUser?.id;
      final userPhone = currentUser?.phone ??
          currentUser?.userMetadata?['phone'] as String?;

      // 1. Query by customer_id
      if (userId != null) {
        try {
          final res = await client
              .from('enquiries')
              .select('*')
              .eq('customer_id', userId)
              .order('created_at', ascending: false);
          final list = List<Map<String, dynamic>>.from(res);
          if (list.isNotEmpty) return list;
        } catch (_) {}
      }

      // 2. Query by phone match
      if (userPhone != null && userPhone.isNotEmpty) {
        final cleanPhone = userPhone.replaceAll(RegExp(r'\D'), '');
        if (cleanPhone.length >= 10) {
          final last10 = cleanPhone.substring(cleanPhone.length - 10);
          try {
            final res = await client
                .from('enquiries')
                .select('*')
                .ilike('customer_phone', '%$last10%')
                .order('created_at', ascending: false);
            final list = List<Map<String, dynamic>>.from(res);
            if (list.isNotEmpty) return list;
          } catch (_) {}
        }
      }

      // 3. Fallback: recent enquiries
      final fallback = await client
          .from('enquiries')
          .select('*')
          .order('created_at', ascending: false)
          .limit(25);
      return List<Map<String, dynamic>>.from(fallback);
    } catch (e) {
      debugPrint('[SupabaseService] getCustomerEnquiries error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProviderEnquiries() async {
    try {
      final provider = await getMyProviderProfile();
      final providerId = provider?['id'] as String?;
      final providerName = provider?['business_name'] as String? ??
          provider?['full_name'] as String?;
      final providerCategory = provider?['category'] as String?;

      // 1. Query by provider_id
      if (providerId != null) {
        try {
          final res = await client
              .from('enquiries')
              .select('*')
              .eq('provider_id', providerId)
              .order('created_at', ascending: false);
          final list = List<Map<String, dynamic>>.from(res);
          if (list.isNotEmpty) return list;
        } catch (_) {}
      }

      // 2. Query by provider_name match
      if (providerName != null && providerName.isNotEmpty) {
        try {
          final res = await client
              .from('enquiries')
              .select('*')
              .ilike('provider_name', '%$providerName%')
              .order('created_at', ascending: false);
          final list = List<Map<String, dynamic>>.from(res);
          if (list.isNotEmpty) return list;
        } catch (_) {}
      }

      // 3. Query by category match
      if (providerCategory != null && providerCategory.isNotEmpty) {
        try {
          final res = await client
              .from('enquiries')
              .select('*')
              .ilike('category', '%$providerCategory%')
              .order('created_at', ascending: false);
          final list = List<Map<String, dynamic>>.from(res);
          if (list.isNotEmpty) return list;
        } catch (_) {}
      }

      // 4. Fallback: return platform enquiries for testing
      final fallback = await client
          .from('enquiries')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(fallback);
    } catch (e) {
      debugPrint('[SupabaseService] getProviderEnquiries error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> adminGetAllEnquiries() async {
    try {
      final response = await client
          .from('enquiries')
          .select('*')
          .order('created_at', ascending: false)
          .limit(200);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[SupabaseService] adminGetAllEnquiries error: $e');
      return [];
    }
  }

  Future<bool> replyToEnquiry({
    required String enquiryId,
    required String replyText,
    String status = 'quoted',
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await client.from('enquiries').update({
        'provider_reply': replyText.trim(),
        'replied_at': now,
        'status': status,
        'updated_at': now,
      }).eq('id', enquiryId);

      // Fetch enquiry to get customer_id & provider details
      final enquiry = await client
          .from('enquiries')
          .select('*')
          .eq('id', enquiryId)
          .maybeSingle();

      final customerId = enquiry?['customer_id'] as String?;
      final providerName = enquiry?['provider_name'] as String? ?? 'Partner';
      final serviceTitle = enquiry?['service_title'] as String? ?? 'your enquiry';
      final providerId = enquiry?['provider_id'] as String?;
      final currentUserId = currentUser?.id;

      // 1. Create in-app notification for the customer
      if (customerId != null && customerId.isNotEmpty) {
        try {
          await createNotification(
            userId: customerId,
            title: '💬 Partner Replied to Your Enquiry',
            body: '$providerName replied: "$replyText"',
            type: 'general',
            relatedId: enquiryId,
          );
        } catch (_) {}
      }

      // 2. Automatically sync message to live chat conversation
      if (customerId != null && customerId.isNotEmpty && currentUserId != null) {
        try {
          final conv = await getOrCreateConversation(
            providerUserId: currentUserId,
            providerServiceId: providerId,
          );
          if (conv != null) {
            final convId = conv['id'] as String;
            await sendMessage(
              conversationId: convId,
              content: '📋 Enquiry Reply ($serviceTitle):\n$replyText',
            );
          }
        } catch (_) {}
      }

      return true;
    } catch (e) {
      debugPrint('[SupabaseService] replyToEnquiry error: $e');
      return false;
    }
  }

  Future<bool> updateEnquiryStatus({
    required String enquiryId,
    required String status,
  }) async {
    try {
      await client.from('enquiries').update({
        'status': status,
      }).eq('id', enquiryId);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] updateEnquiryStatus error: $e');
      return false;
    }
  }

  Future<bool> deleteEnquiry(String enquiryId) async {
    try {
      await client.from('enquiries').delete().eq('id', enquiryId);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] deleteEnquiry error: $e');
      return false;
    }
  }

  // ─── QUOTATIONS ───────────────────────────────────────────────────────────

  Future<void> createOrUpdateQuotation({
    String? quotationId,
    String? enquiryId,
    String? customerId,
    required List<Map<String, dynamic>> lineItems,
    required double labourCharges,
    required double materialCharges,
    required double visitingCharges,
    required double transportationCharges,
    required double equipmentCharges,
    required double extraCharges,
    required double discount,
    required double taxPercentage,
    required double taxAmount,
    required double subtotal,
    required double totalAmount,
    required String expectedCompletionTime,
    required int validityDays,
    required String additionalNotes,
    required String status,
    bool isTemplate = false,
    String templateName = '',
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final provider = await getMyProviderProfile();
    if (provider == null) throw Exception('Provider profile not found');

    final data = <String, dynamic>{
      'provider_id': provider['id'],
      'line_items': lineItems,
      'labour_charges': labourCharges,
      'material_charges': materialCharges,
      'visiting_charges': visitingCharges,
      'transportation_charges': transportationCharges,
      'equipment_charges': equipmentCharges,
      'extra_charges': extraCharges,
      'discount': discount,
      'tax_percentage': taxPercentage,
      'tax_amount': taxAmount,
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'expected_completion_time': expectedCompletionTime,
      'validity_days': validityDays,
      'additional_notes': additionalNotes,
      'status': status,
      'is_template': isTemplate,
      'template_name': templateName,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Only set customer_id and enquiry_id if they are non-null
    if (customerId != null) data['customer_id'] = customerId;
    if (enquiryId != null) data['enquiry_id'] = enquiryId;

    if (quotationId != null) {
      await client.from('quotations').update(data).eq('id', quotationId);
    } else {
      await client.from('quotations').insert(data);
      // Update enquiry status to 'quoted'
      if (enquiryId != null && status == 'sent') {
        await client
            .from('enquiries')
            .update({'status': 'quoted'})
            .eq('id', enquiryId);
      }
    }
  }

  Future<Map<String, dynamic>?> getQuotationByEnquiry(String enquiryId) async {
    try {
      final response = await client
          .from('quotations')
          .select()
          .eq('enquiry_id', enquiryId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Returns counts of provider quotations grouped by status.
  /// Statuses: sent/negotiating → pending, accepted, rejected, expired
  Future<Map<String, int>> getProviderQuotationCounts() async {
    try {
      final provider = await getMyProviderProfile();
      if (provider == null) {
        return {'pending': 0, 'accepted': 0, 'rejected': 0, 'expired': 0};
      }
      final response = await client
          .from('quotations')
          .select('status')
          .eq('provider_id', provider['id'] as String)
          .eq('is_template', false);
      final rows = List<Map<String, dynamic>>.from(response);
      int pending = 0, accepted = 0, rejected = 0, expired = 0;
      for (final row in rows) {
        final status = row['status'] as String? ?? '';
        switch (status) {
          case 'sent':
          case 'negotiating':
            pending++;
            break;
          case 'accepted':
            accepted++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'expired':
            expired++;
            break;
        }
      }
      return {
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
        'expired': expired,
      };
    } catch (e) {
      return {'pending': 0, 'accepted': 0, 'rejected': 0, 'expired': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerQuotations() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      final response = await client
          .from('quotations')
          .select(
            '*, provider:provider_id(id, business_name, phone, whatsapp, whatsapp_number, image_url), enquiry:enquiry_id(id, title, description)',
          )
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> updateQuotationStatus({
    required String quotationId,
    required String status,
  }) async {
    await client
        .from('quotations')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', quotationId);

    // Also update enquiry status
    try {
      final quotation = await client
          .from('quotations')
          .select('enquiry_id')
          .eq('id', quotationId)
          .maybeSingle();
      final enquiryId = quotation?['enquiry_id'] as String?;
      if (enquiryId != null) {
        String enquiryStatus = 'quoted';
        if (status == 'accepted') {
          enquiryStatus = 'accepted';
        } else if (status == 'rejected') {
          enquiryStatus = 'rejected';
        } else if (status == 'negotiating') {
          enquiryStatus = 'negotiating';
        }
        await client
            .from('enquiries')
            .update({'status': enquiryStatus})
            .eq('id', enquiryId);
      }
    } catch (_) {}
  }

  /// Creates a pending order in the `orders` table pre-filled from an accepted quotation.
  /// Returns the created order map (with id, order_number, etc.) or null on failure.
  Future<Map<String, dynamic>?> createOrderFromQuotation({
    required String quotationId,
    required String providerName,
    required String service,
    required String category,
    required String amountStr,
    String? providerId,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final orderNumber =
          'ORD-Q-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final now = DateTime.now();
      final scheduledDate =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      final response = await client
          .from('orders')
          .insert({
            'order_number': orderNumber,
            'customer_id': userId,
            'provider_id': providerId,
            'provider_name': providerName,
            'service': service,
            'category': category,
            'scheduled_date': scheduledDate,
            'scheduled_time': '10:00 AM',
            'amount': amountStr,
            'status': 'pending',
            'payment_status': 'pending',
            'payment_method': 'razorpay',
            'notes': 'Booking from accepted quotation #$quotationId',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getQuotationTemplates() async {
    try {
      final provider = await getMyProviderProfile();
      if (provider == null) return [];
      final response = await client
          .from('quotation_templates')
          .select()
          .eq('provider_id', provider['id'] as String)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> adminGetAllQuotations() async {
    try {
      final response = await client
          .from('quotations')
          .select(
            '*, provider:provider_id(id, business_name), customer:customer_id(id, full_name)',
          )
          .order('created_at', ascending: false)
          .limit(200);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ─── Quotation Negotiation Messages ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getQuotationMessages(
    String quotationId,
  ) async {
    try {
      final response = await client
          .from('quotation_messages')
          .select('*')
          .eq('quotation_id', quotationId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> sendQuotationMessage({
    required String quotationId,
    required String senderId,
    required String messageType,
    required String content,
    double? proposedAmount,
    String? proposedNotes,
  }) async {
    final payload = <String, dynamic>{
      'quotation_id': quotationId,
      'sender_id': senderId,
      'message_type': messageType,
      'content': content,
      'is_read': false,
    };
    if (proposedAmount != null) payload['proposed_amount'] = proposedAmount;
    if (proposedNotes != null) payload['proposed_notes'] = proposedNotes;
    await client.from('quotation_messages').insert(payload);
  }

  Future<void> markQuotationMessagesRead(
    String quotationId,
    String currentUserId,
  ) async {
    try {
      await client
          .from('quotation_messages')
          .update({'is_read': true})
          .eq('quotation_id', quotationId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    } catch (_) {}
  }
}

