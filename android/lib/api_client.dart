import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class BinerApi {
  BinerApi({http.Client? client, SharedPreferences? preferences})
      : _client = client ?? http.Client(),
        _preferences = preferences;

  static const baseUrl = 'https://binercraft.ir/mention-api-pub';
  static const _tokenKey = 'binerm_token';
  final http.Client _client;
  SharedPreferences? _preferences;
  String? _token;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<void> restoreSession() async {
    _token = (await _prefs).getString(_tokenKey);
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/$path').replace(queryParameters: query);

  Map<String, String> _headers({bool json = true, bool authenticated = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    if (authenticated && isAuthenticated) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    http.Response response;
    try {
      final uri = _uri(path, query);
      final headers = _headers(authenticated: authenticated);
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          response = await _client.post(uri, headers: headers, body: jsonEncode(body ?? const {})).timeout(const Duration(seconds: 20));
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: headers, body: jsonEncode(body ?? const {})).timeout(const Duration(seconds: 20));
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        default:
          throw const ApiException('Unsupported request method.');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('اتصال به سرور برقرار نشد. اینترنت و وضعیت API را بررسی کن.');
    }

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      data = decoded;
    } catch (_) {
      throw ApiException(
        response.statusCode >= 500
            ? 'سرور موقتاً در دسترس نیست.'
            : 'پاسخ سرور معتبر نیست (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300 || data['ok'] == false) {
      if (response.statusCode == 401) {
        _token = null;
        (await _prefs).remove(_tokenKey);
      }
      throw ApiException(
        (data['message'] as String?) ?? 'درخواست انجام نشد.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String identity, String password) async {
    final result = await _request('POST', 'v1/auth/login', authenticated: false,
        body: {'identity': identity.trim(), 'password': password});
    await _saveToken(result);
    return Map<String, dynamic>.from(result['user'] as Map);
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await _request('POST', 'v1/auth/register', authenticated: false,
        body: {'username': username.trim(), 'email': email.trim(), 'password': password, 'display_name': displayName.trim()});
    await _saveToken(result);
    return Map<String, dynamic>.from(result['user'] as Map);
  }

  Future<void> _saveToken(Map<String, dynamic> result) async {
    final value = result['token'];
    if (value is! String || value.isEmpty) throw const ApiException('سرور توکن ورود را برنگرداند.');
    _token = value;
    await (await _prefs).setString(_tokenKey, value);
  }

  Future<Map<String, dynamic>> me() async =>
      Map<String, dynamic>.from((await _request('GET', 'v1/me'))['user'] as Map);

  Future<void> logout() async {
    try {
      if (isAuthenticated) await _request('POST', 'v1/auth/logout');
    } catch (_) {
      // Local sign-out must still work when the server is unreachable.
    } finally {
      _token = null;
      await (await _prefs).remove(_tokenKey);
    }
  }

  Future<List<Map<String, dynamic>>> posts({int limit = 20, int? beforeId}) async {
    final query = <String, String>{'limit': '$limit'};
    if (beforeId != null) query['before_id'] = '$beforeId';
    final result = await _request('GET', 'v1/posts', query: query);
    return (result['posts'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createPost(String text) async =>
      Map<String, dynamic>.from((await _request('POST', 'v1/posts', body: {'body': text}))['post'] as Map);

  Future<void> togglePostAction(int postId, String action, bool active) async {
    if (action != 'like' && action != 'repost') throw const ApiException('Unsupported post action.');
    await _request(active ? 'POST' : 'DELETE', 'v1/posts/$postId/$action');
  }

  Future<List<Map<String, dynamic>>> notifications() async {
    final result = await _request('GET', 'v1/notifications');
    return (result['notifications'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> conversations() async {
    final result = await _request('GET', 'v1/conversations');
    return (result['conversations'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void dispose() => _client.close();
}
