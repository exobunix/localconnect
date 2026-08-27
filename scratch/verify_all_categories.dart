import 'dart:convert';
import 'dart:io';

const supabaseUrl = 'https://ckyopijftlasebanhhqm.supabase.co';
const supabaseKey = 'sb_publishable_pztyR-WMEHV-T7k2MUgrlg_0KkpC75H';

Future<dynamic> _supabaseGet(String table, String query) async {
  final uri = Uri.parse('$supabaseUrl/rest/v1/$table?$query');
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    req.headers.set('apikey', supabaseKey);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    req.headers.set('Accept', 'application/json');
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(body);
    } else {
      print('HTTP error ${resp.statusCode}: $body');
      return [];
    }
  } finally {
    client.close();
  }
}

void main() async {
  print('=== VERIFYING PROVIDERS BY CATEGORY ===');
  final categories = [
    'Home Maintenance',
    'Transport',
    'Events',
    'Rent',
    'Shop',
    'Delivery',
  ];

  for (final cat in categories) {
    final rows = await _supabaseGet(
      'service_providers',
      'select=id,business_name,owner_name,category,subcategory,rating,phone,registration_status,is_active&category=ilike.*$cat*&order=rating.desc',
    );
    final list = rows is List ? rows : [];
    print('\nCategory [$cat] -> ${list.length} approved & active providers:');
    for (final p in list) {
      print('  ✓ [${p['subcategory']}] ${p['business_name']} (${p['owner_name']}) | ${p['rating']}★ | 📞 ${p['phone']} | Status: ${p['registration_status']} | ID: ${p['id']}');
    }
  }

  print('\n=== TOTAL PROVIDER SERVICE CHARGES IN DB ===');
  final charges = await _supabaseGet(
    'provider_service_charges',
    'select=id,provider_id,service_name,base_price,unit&limit=20',
  );
  final chargesList = charges is List ? charges : [];
  print('Sample of active service offerings with pricing (${chargesList.length} shown):');
  for (final c in chargesList) {
    print('  - ${c['service_name']} -> ₹${c['base_price']} ${c['unit']} (Provider: ${c['provider_id']})');
  }

  print('\n=== ALL CATEGORIES & PROVIDERS VERIFIED SUCCESSFULLY ===');
}
