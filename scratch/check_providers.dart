import 'dart:convert';
import 'dart:io';

const supabaseUrl = 'https://ckyopijftlasebanhhqm.supabase.co';
const supabaseKey = 'sb_publishable_pztyR-WMEHV-T7k2MUgrlg_0KkpC75H';

Future<void> main() async {
  final client = HttpClient();

  // 1. Sign in to get JWT
  String? token;
  try {
    final loginReq = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
    );
    loginReq.headers.set('apikey', supabaseKey);
    loginReq.headers.set('Content-Type', 'application/json');
    loginReq.write(jsonEncode({
      'email': 'ramesh_plumber@localconnect.com',
      'password': 'Password@1234',
    }));
    final loginResp = await loginReq.close();
    final loginBody = await loginResp.transform(utf8.decoder).join();
    if (loginResp.statusCode == 200) {
      final json = jsonDecode(loginBody);
      token = json['access_token'];
      print('✓ Authenticated successfully with Provider JWT!');
    } else {
      print('Login error: $loginBody');
    }
  } catch (e) {
    print('Auth error: $e');
  }

  if (token == null) {
    print('No token, exiting');
    client.close();
    return;
  }

  // 2. Query service_providers across all categories
  final categories = [
    'Home Maintenance',
    'Transport',
    'Event Management',
    'Rent',
    'Shop',
    'Delivery',
  ];

  print('\n=== LIVE PROVIDERS IN DATABASE (GROUPED BY CATEGORY) ===');
  for (final cat in categories) {
    try {
      final req = await client.getUrl(
        Uri.parse('$supabaseUrl/rest/v1/service_providers?category=ilike.*$cat*&select=id,business_name,owner_name,category,subcategory,rating,phone,city,registration_status&order=rating.desc'),
      );
      req.headers.set('apikey', supabaseKey);
      req.headers.set('Authorization', 'Bearer $token');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode == 200) {
        final list = jsonDecode(body) as List;
        print('\n📂 Category: [$cat] -> ${list.length} Providers:');
        for (final p in list) {
          print('   ✓ [${p['subcategory']}] ${p['business_name']} (${p['owner_name']}) | Rating: ${p['rating']}★ | 📞 ${p['phone']} | ${p['city']} | ID: ${p['id']}');
        }
      } else {
        print('Error for $cat: $body');
      }
    } catch (e) {
      print('Query error for $cat: $e');
    }
  }

  client.close();
}
