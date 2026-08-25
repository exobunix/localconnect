import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:url_launcher/url_launcher.dart' show LaunchMode;
export 'package:url_launcher/url_launcher.dart' show LaunchMode;

// Re-export standard enums if needed
enum OAuthProvider { google, apple, github }
enum OtpType { signup, recovery, invite, magiclink, email, sms, phoneChange, emailChange }
enum RealtimeSubscribeStatus { subscribed, channelError, timedOut, closed }

class AuthState {
  final Session? session;
  final AuthChangeEvent event;
  AuthState(this.event, this.session);
}

enum AuthChangeEvent { signedIn, signedOut, tokenRefreshed, userUpdated, passwordRecovery, initialSession }
typedef AuthEvent = AuthChangeEvent;

class AuthException implements Exception {
  final String message;
  final String? statusCode;
  AuthException(this.message, {this.statusCode});
  @override
  String toString() => 'AuthException: $message';
}

class UserAttributes {
  final Map<String, dynamic>? data;
  final String? password;
  const UserAttributes({this.data, this.password});
}

class User {
  final String id;
  final String email;
  final Map<String, dynamic> userMetadata;
  final List<dynamic> identities;
  final String? emailConfirmedAt;

  User({
    required this.id,
    required this.email,
    required this.userMetadata,
    this.identities = const [],
    this.emailConfirmedAt = '2026-08-10T00:00:00Z',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      userMetadata: json['user_metadata'] ?? {},
      identities: json['identities'] ?? const [],
      emailConfirmedAt: json['email_confirmed_at'] ?? '2026-08-10T00:00:00Z',
    );
  }
}

class Session {
  final String accessToken;
  final User user;
  final int? expiresAt;

  Session({required this.accessToken, required this.user, this.expiresAt});

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      accessToken: json['access_token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      expiresAt: json['expires_at'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600),
    );
  }
}

class AuthResponse {
  final Session? session;
  final User? user;

  AuthResponse({this.session, this.user});
}

class Supabase {
  static Supabase? _instance;
  static Supabase get instance => _instance ??= Supabase._();

  static String _url = 'http://localhost:3000';
  static String _anonKey = '';

  Supabase._();

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && url.contains('localhost')) {
      _url = url.replaceAll('localhost', '10.0.2.2');
    } else {
      _url = url;
    }
    _anonKey = anonKey;
    await instance.client.auth._loadSession();
  }

  late final SupabaseClient client = SupabaseClient(_url);
}

class SupabaseClient {
  final String url;
  late final GoTrueClient auth;

  SupabaseClient(this.url) {
    auth = GoTrueClient(url);
  }

  SupabaseQueryBuilder from(String table) {
    return SupabaseQueryBuilder(url, table, auth.token);
  }

  RealtimeChannel channel(String channelId) {
    return RealtimeChannel(url, channelId);
  }

  MockStorage get storage => MockStorage(url);

  MockFunctions get functions => MockFunctions(url);

  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) async {
    return null;
  }
}

class MockFunctions {
  final String url;
  MockFunctions(this.url);

  Future<FunctionResponse> invoke(String functionName, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final response = await http.post(
      Uri.parse('$url/functions/$functionName'),
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body != null ? json.encode(body) : null,
    );
    return FunctionResponse(response.body, response.statusCode);
  }
}

class FunctionResponse {
  final dynamic data;
  final int status;
  FunctionResponse(this.data, this.status);
}

class FileOptions {
  final String? contentType;
  final bool? cacheControl;
  final bool? upsert;
  const FileOptions({this.contentType, this.cacheControl, this.upsert});
}

class MockStorage {
  final String url;
  MockStorage(this.url);
  
  MockStorageBucket from(String bucket) => MockStorageBucket(url, bucket);
}

class MockStorageBucket {
  final String url;
  final String bucket;
  MockStorageBucket(this.url, this.bucket);
  
  Future<String> upload(String path, dynamic file, {FileOptions? fileOptions}) async {
    return '$url/storage/v1/object/public/$bucket/$path';
  }

  Future<String> uploadBinary(String path, dynamic data, {FileOptions? fileOptions}) async {
    return '$url/storage/v1/object/public/$bucket/$path';
  }
  
  Future<List<dynamic>> remove(List<String> paths) async {
    return [];
  }

  String getPublicUrl(String path) {
    return '$url/storage/v1/object/public/$bucket/$path';
  }

  Future<String> createSignedUrl(String path, int expiresIn) async {
    return '$url/storage/v1/object/public/$bucket/$path';
  }
}

class MockGoTrueAdminApi {
  Future<void> deleteUser(String id) async {}
}

class GoTrueClient {
  final String url;
  User? _currentUser;
  Session? _session;
  final _authController = StreamController<AuthState>.broadcast();

  GoTrueClient(this.url);

  User? get currentUser => _currentUser;
  Session? get currentSession => _session;
  String? get token => _session?.accessToken;

  Stream<AuthState> get onAuthStateChange => _authController.stream;

  MockGoTrueAdminApi get admin => MockGoTrueAdminApi();

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionStr = prefs.getString('supabase_mock_session');
      if (sessionStr != null) {
        final data = json.decode(sessionStr);
        _session = Session.fromJson(data);
        _currentUser = _session?.user;
        _authController.add(AuthState(AuthEvent.signedIn, _session));
      }
    } catch (_) {}
  }

  Future<void> _saveSession(Session session) async {
    _session = session;
    _currentUser = session.user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_mock_session', json.encode({
      'access_token': session.accessToken,
      'user': {
        'id': session.user.id,
        'email': session.user.email,
        'user_metadata': session.user.userMetadata,
      }
    }));
    _authController.add(AuthState(AuthEvent.signedIn, session));
  }

  Future<void> _clearSession() async {
    _session = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('supabase_mock_session');
    _authController.add(AuthState(AuthEvent.signedOut, null));
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final response = await http.post(
      Uri.parse('$url/auth/v1/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'data': data}),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? 'Sign up failed');
    }

    final body = json.decode(response.body);
    final session = Session.fromJson(body['session']);
    await _saveSession(session);
    return AuthResponse(session: session, user: session.user);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$url/auth/v1/token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? 'Sign in failed');
    }

    final body = json.decode(response.body);
    final session = Session.fromJson(body['session']);
    await _saveSession(session);
    return AuthResponse(session: session, user: session.user);
  }

  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
  }) async {
    final response = await http.post(
      Uri.parse('$url/auth/v1/token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email ?? 'google-user@localconnect.com',
        'password': idToken,
        'provider': provider.name,
        'name': name ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? 'Google sign in failed');
    }

    final body = json.decode(response.body);
    final session = Session.fromJson(body['session']);
    await _saveSession(session);
    return AuthResponse(session: session, user: session.user);
  }

  Future<void> signOut() async {
    await http.post(
      Uri.parse('$url/auth/v1/logout'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
    await _clearSession();
  }

  Future<void> resetPasswordForEmail(String email) async {
    // Simply return success
  }

  Future<User> updateUser(UserAttributes attributes) async {
    if (_currentUser == null) throw Exception('No user logged in');
    final updatedMetadata = {
      ..._currentUser!.userMetadata,
      ...?attributes.data
    };
    _currentUser = User(
      id: _currentUser!.id,
      email: _currentUser!.email,
      userMetadata: updatedMetadata,
      identities: _currentUser!.identities
    );
    if (_session != null) {
      _session = Session(accessToken: _session!.accessToken, user: _currentUser!, expiresAt: _session!.expiresAt);
      await _saveSession(_session!);
    }
    return _currentUser!;
  }

  Future<bool> signInWithOAuth(OAuthProvider provider, {String? redirectTo, LaunchMode? authScreenLaunchMode}) async {
    return true;
  }

  Future<AuthResponse> verifyOTP({
    required String token,
    required OtpType type,
    String? email,
    String? phone,
  }) async {
    final mockUser = User(id: 'mock-user-id', email: email ?? 'user@localconnect.com', userMetadata: {});
    final mockSession = Session(accessToken: 'mock-token', user: mockUser);
    await _saveSession(mockSession);
    return AuthResponse(session: mockSession, user: mockUser);
  }
}

class SupabaseQueryBuilder {
  final String url;
  final String table;
  final String? token;

  SupabaseQueryBuilder(this.url, this.table, this.token);

  PostgrestFilterBuilder select([String columns = '*']) {
    return PostgrestFilterBuilder(url, table, token, 'GET').select(columns);
  }

  PostgrestFilterBuilder insert(dynamic values, {bool upsert = false}) {
    return PostgrestFilterBuilder(url, table, token, 'POST').insert(values, upsert: upsert);
  }

  PostgrestFilterBuilder update(Map<String, dynamic> values) {
    return PostgrestFilterBuilder(url, table, token, 'PATCH').update(values);
  }

  PostgrestFilterBuilder delete() {
    return PostgrestFilterBuilder(url, table, token, 'DELETE');
  }

  PostgrestFilterBuilder upsert(dynamic values, {String? onConflict}) {
    return PostgrestFilterBuilder(url, table, token, 'POST').upsert(values);
  }
}

enum CountOption { exact, planned, estimated }

class PostgrestFilterBuilder implements Future<dynamic> {
  final String url;
  final String table;
  final String? token;
  final String method;
  
  final Map<String, String> _filters = {};
  dynamic _body;
  bool _maybeSingle = false;
  bool _isUpsert = false;

  PostgrestFilterBuilder(this.url, this.table, this.token, this.method);

  PostgrestFilterBuilder select([String columns = '*']) {
    _filters['select'] = columns;
    return this;
  }

  PostgrestFilterBuilder insert(dynamic values, {bool upsert = false}) {
    _body = values;
    _isUpsert = upsert;
    return this;
  }

  PostgrestFilterBuilder update(Map<String, dynamic> values) {
    _body = values;
    return this;
  }

  PostgrestFilterBuilder upsert(dynamic values) {
    _body = values;
    _isUpsert = true;
    return this;
  }

  PostgrestFilterBuilder eq(String column, dynamic value) {
    _filters[column] = 'eq.$value';
    return this;
  }

  PostgrestFilterBuilder neq(String column, dynamic value) {
    _filters[column] = 'neq.$value';
    return this;
  }

  PostgrestFilterBuilder gt(String column, dynamic value) {
    _filters[column] = 'gt.$value';
    return this;
  }

  PostgrestFilterBuilder gte(String column, dynamic value) {
    _filters[column] = 'gte.$value';
    return this;
  }

  PostgrestFilterBuilder lt(String column, dynamic value) {
    _filters[column] = 'lt.$value';
    return this;
  }

  PostgrestFilterBuilder lte(String column, dynamic value) {
    _filters[column] = 'lte.$value';
    return this;
  }

  PostgrestFilterBuilder like(String column, String pattern) {
    _filters[column] = 'like.$pattern';
    return this;
  }

  PostgrestFilterBuilder ilike(String column, String pattern) {
    _filters[column] = 'ilike.$pattern';
    return this;
  }

  PostgrestFilterBuilder is_(String column, dynamic value) {
    _filters[column] = 'is.$value';
    return this;
  }

  PostgrestFilterBuilder in_(String column, List<dynamic> values) {
    _filters[column] = 'in.(${values.join(",")})';
    return this;
  }

  PostgrestFilterBuilder inFilter(String column, List<dynamic> values) {
    _filters[column] = 'in.(${values.join(",")})';
    return this;
  }

  PostgrestFilterBuilder not(String column, String operator, dynamic value) {
    _filters['$column.not'] = '$operator.$value';
    return this;
  }

  PostgrestFilterBuilder or(String filters) {
    _filters['or'] = filters;
    return this;
  }

  PostgrestFilterBuilder count(CountOption option) {
    return this;
  }

  PostgrestFilterBuilder order(String column, {bool ascending = true}) {
    _filters['order'] = '$column.${ascending ? "asc" : "desc"}';
    return this;
  }

  PostgrestFilterBuilder limit(int count) {
    _filters['limit'] = '$count';
    return this;
  }

  PostgrestFilterBuilder maybeSingle() {
    _maybeSingle = true;
    _filters['limit'] = '1';
    return this;
  }

  PostgrestFilterBuilder single() {
    _maybeSingle = true;
    _filters['limit'] = '1';
    return this;
  }

  Future<dynamic> _execute() async {
    final queryParams = _filters.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final uri = Uri.parse('$url/rest/v1/$table${queryParams.isNotEmpty ? "?$queryParams" : ""}');
    
    final preferList = <String>[];
    if (method == 'POST' || method == 'PATCH') {
      preferList.add('return=representation');
    }
    if (_maybeSingle) {
      preferList.add('handling=strict');
    }
    if (_isUpsert) {
      preferList.add('resolution=merge-duplicates');
    }

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (preferList.isNotEmpty) 'Prefer': preferList.join(', '),
    };

    http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: json.encode(_body));
    } else if (method == 'PATCH') {
      response = await http.patch(uri, headers: headers, body: json.encode(_body));
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers);
    } else {
      throw Exception('Unsupported HTTP method $method');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('DB error: ${response.body}');
    }

    final decoded = json.decode(response.body);
    if (_maybeSingle) {
      if (decoded is List) {
        return decoded.isNotEmpty ? decoded[0] : null;
      }
      return decoded;
    }
    
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    }
    return decoded;
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic value) onValue, {Function? onError}) {
    return _execute().then(onValue, onError: onError);
  }

  @override
  Future<dynamic> catchError(Function onError, {bool Function(Object error)? test}) {
    return _execute().catchError(onError, test: test);
  }

  @override
  Future<dynamic> timeout(Duration timeLimit, {FutureOr<dynamic> Function()? onTimeout}) {
    return _execute().timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) {
    return _execute().whenComplete(action);
  }

  @override
  Stream<dynamic> asStream() {
    return _execute().asStream();
  }
}

class RealtimeChannel {
  final String url;
  final String channelId;
  WebSocketChannel? _wsChannel;
  final List<PostgresChangeFilter> _filters = [];

  RealtimeChannel(this.url, this.channelId);

  RealtimeChannel onPostgresChanges({
    required dynamic event,
    required String schema,
    required String table,
    PostgresChangeFilter? filter,
    required void Function(PostgresChangePayload payload) callback,
  }) {
    _filters.add(PostgresChangeFilter(
      table: table,
      column: filter?.column,
      value: filter?.value,
      callback: callback,
    ));
    return this;
  }

  RealtimeChannel subscribe([void Function(String status, [dynamic error])? callback]) {
    final wsUri = Uri.parse(url.replaceAll('http', 'ws'));
    _wsChannel = WebSocketChannel.connect(wsUri);
    
    _wsChannel?.sink.add(json.encode({
      'event': 'phx_join',
      'topic': 'realtime:public',
      'payload': {},
      'ref': channelId
    }));

    _wsChannel?.stream.listen((message) {
      try {
        final data = json.decode(message);
        if (data['event'] == 'postgres_changes') {
          final payload = PostgresChangePayload(data['payload']);
          for (var filter in _filters) {
            if (payload.table == filter.table) {
              if (filter.column != null && filter.value != null) {
                final recordVal = payload.newRecord[filter.column] ?? payload.oldRecord[filter.column];
                if (recordVal.toString() != filter.value.toString()) continue;
              }
              filter.callback!(payload);
            }
          }
        }
      } catch (_) {}
    });

    if (callback != null) {
      callback('SUBSCRIBED');
    }
    return this;
  }

  Future<void> unsubscribe() async {
    await _wsChannel?.sink.close();
  }
}

enum PostgresChangeEvent { insert, update, delete, all }
enum PostgresChangeFilterType { eq }

class PostgresChangeFilter {
  final String? table;
  final String? column;
  final String? value;
  final PostgresChangeFilterType? type;
  final void Function(PostgresChangePayload payload)? callback;

  PostgresChangeFilter({
    this.table,
    this.column,
    this.value,
    this.type,
    this.callback,
  });
}

class PostgresChangePayload {
  final String table;
  final Map<String, dynamic> newRecord;
  final Map<String, dynamic> oldRecord;
  final PostgresChangeEvent eventType;

  PostgresChangePayload(Map<String, dynamic> payload)
      : table = payload['table'] ?? '',
        eventType = _parseEvent(payload['event']),
        newRecord = Map<String, dynamic>.from(payload['data'] ?? {}),
        oldRecord = Map<String, dynamic>.from(payload['data'] ?? {});

  static PostgresChangeEvent _parseEvent(String? event) {
    switch (event?.toUpperCase()) {
      case 'INSERT': return PostgresChangeEvent.insert;
      case 'UPDATE': return PostgresChangeEvent.update;
      case 'DELETE': return PostgresChangeEvent.delete;
      default: return PostgresChangeEvent.all;
    }
  }
}
