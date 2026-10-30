import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  Future<List<Map<String, dynamic>>> posts({int limit = 20, int? beforeId, bool following = false, int? replyToId}) async {
    final query = <String, String>{'limit': '$limit'};
    if (following) query['feed'] = 'following';
    if (beforeId != null) query['before_id'] = '$beforeId';
    if (replyToId != null) query['reply_to_id'] = '$replyToId';
    final result = await _request('GET', 'v1/posts', query: query);
    return (result['posts'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createPost(String text, {int? mediaId, int? replyToId}) async {
    final body = <String, dynamic>{'body': text};
    if (mediaId != null) body['media_id'] = mediaId;
    if (replyToId != null) body['reply_to_id'] = replyToId;
    return Map<String, dynamic>.from((await _request('POST', 'v1/posts', body: body))['post'] as Map);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String displayName,
    required String bio,
    required String website,
    int? avatarMediaId,
  }) async {
    final body = <String, dynamic>{'display_name': displayName, 'bio': bio, 'website': website};
    if (avatarMediaId != null) body['avatar_media_id'] = avatarMediaId;
    return Map<String, dynamic>.from((await _request('PATCH', 'v1/me', body: body))['user'] as Map);
  }

  Future<void> followUser(int userId, bool follow) async {
    await _request(follow ? 'POST' : 'DELETE', 'v1/users/$userId/follow');
  }

  Future<Map<String, dynamic>> uploadMedia(XFile file) async {
    if (!isAuthenticated) throw const ApiException('برای بارگذاری فایل وارد حساب شو.');
    try {
      final request = http.MultipartRequest('POST', _uri('v1/media'));
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ));
      final streamed = await _client.send(request).timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode < 200 || response.statusCode >= 300 || decoded['ok'] == false) {
        throw ApiException(decoded['message']?.toString() ?? 'بارگذاری فایل انجام نشد.', statusCode: response.statusCode);
      }
      return Map<String, dynamic>.from(decoded['media'] as Map);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('بارگذاری فایل ناموفق بود؛ اتصال و محدودیت آپلود سرور را بررسی کن.');
    }
  }

  Future<Map<String, dynamic>> updatePost(int postId, String text) async =>
      Map<String, dynamic>.from((await _request('PATCH', 'v1/posts/$postId', body: {'body': text}))['post'] as Map);

  Future<void> deletePost(int postId) async {
    await _request('DELETE', 'v1/posts/$postId');
  }

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

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final result = await _request('GET', 'v1/search/users', query: {'q': query.trim()});
    return (result['users'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> userByUsername(String username) async =>
      Map<String, dynamic>.from((await _request('GET', 'v1/users/${Uri.encodeComponent(username)}'))['user'] as Map);

  Future<List<Map<String, dynamic>>> postsByUser(int userId, {int limit = 50}) async {
    final result = await _request('GET', 'v1/users/$userId/posts', query: {'limit': '$limit'});
    return (result['posts'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchPosts(String query, {int limit = 30}) async {
    final result = await _request('GET', 'v1/search/posts', query: {'q': query.trim(), 'limit': '$limit'});
    return (result['posts'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> userConnections(int userId, {required bool followers}) async {
    final endpoint = followers ? 'followers' : 'following';
    final result = await _request('GET', 'v1/users/$userId/$endpoint');
    return (result['users'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<int> createConversation(int userId) async {
    final result = await _request('POST', 'v1/conversations', body: {'user_id': userId});
    final id = int.tryParse(result['conversation_id'].toString());
    if (id == null) throw const ApiException('سرور شناسه گفت‌وگو را برنگرداند.');
    return id;
  }

  Future<List<Map<String, dynamic>>> messages(int conversationId) async {
    final result = await _request('GET', 'v1/conversations/$conversationId/messages');
    return (result['messages'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage(int conversationId, String text, {int? mediaId}) async {
    final body = <String, dynamic>{'body': text};
    if (mediaId != null) body['media_id'] = mediaId;
    return Map<String, dynamic>.from((await _request('POST', 'v1/conversations/$conversationId/messages', body: body))['message'] as Map);
  }

  Future<List<Map<String, dynamic>>> stories() async {
    final result = await _request('GET', 'v1/stories');
    return (result['stories'] as List? ?? const []).whereType<Map>().map((x) => Map<String,dynamic>.from(x)).toList();
  }

  Future<Map<String, dynamic>> createStory(int mediaId, {String caption = ''}) async =>
      Map<String,dynamic>.from((await _request('POST','v1/stories',body:{'media_id':mediaId,'caption':caption}))['story'] as Map);


  Future<Map<String,dynamic>> toggleStoryLike(int storyId, bool active) async =>
      Map<String,dynamic>.from(await _request(active ? 'POST' : 'DELETE', 'v1/stories/$storyId/like'));

  Future<List<Map<String,dynamic>>> storyComments(int storyId) async {
    final result = await _request('GET', 'v1/stories/$storyId/comments');
    return (result['comments'] as List? ?? const []).whereType<Map>().map((x) => Map<String,dynamic>.from(x)).toList();
  }

  Future<Map<String,dynamic>> addStoryComment(int storyId, String body) async =>
      Map<String,dynamic>.from((await _request('POST', 'v1/stories/$storyId/comments', body: {'body': body}))['comment'] as Map);

  Future<void> markConversationRead(int conversationId) async {
    await _request('POST', 'v1/conversations/$conversationId/read');
  }

  Future<void> blockConversationUser(int conversationId) async {
    await _request('POST', 'v1/conversations/$conversationId/block');
  }

  Future<void> unblockConversationUser(int conversationId) async {
    await _request('DELETE', 'v1/conversations/$conversationId/block');
  }

  Future<void> reportConversation(int conversationId, String reason) async {
    await _request('POST', 'v1/conversations/$conversationId/report', body: {'reason': reason});
  }

  void dispose() => _client.close();
}
