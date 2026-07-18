import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import '../utils/debug_log.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiException implements Exception {
  final String message;
  final String? code;
  final int statusCode;
  final DateTime? mutedUntil;

  const ApiException(
    this.message, {
    this.code,
    required this.statusCode,
    this.mutedUntil,
  });

  @override
  String toString() => message;
}

class ApiClient {
  static const baseUrl = 'https://social.ctm.cloudpasture.site';
  static const _scope = 'api';

  final _secure = const FlutterSecureStorage();
  final _uuid = const Uuid();

  String? accessToken;
  String? refreshToken;
  String? deviceId;
  UnauthorizedHandler? onUnauthorized;

  bool get _underTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  Future<void> loadTokens() async {
    if (_underTest) {
      deviceId ??= 'test-device';
      return;
    }
    try {
      accessToken = await _secure.read(key: 'accessToken');
      refreshToken = await _secure.read(key: 'refreshToken');
      deviceId = await _secure.read(key: 'deviceId');
    } catch (e) {
      AppLog.w('secure storage read failed', scope: _scope, data: e);
    }
    if (deviceId == null || deviceId!.isEmpty) {
      deviceId = _uuid.v4();
      try {
        await _secure.write(key: 'deviceId', value: deviceId);
      } catch (_) {}
    }
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    accessToken = access;
    refreshToken = refresh;
    if (_underTest) return;
    try {
      await _secure.write(key: 'accessToken', value: access);
      await _secure.write(key: 'refreshToken', value: refresh);
    } catch (e) {
      AppLog.w('secure storage write failed', scope: _scope, data: e);
    }
  }

  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    if (_underTest) return;
    try {
      await _secure.delete(key: 'accessToken');
      await _secure.delete(key: 'refreshToken');
    } catch (_) {}
  }

  Uri uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
    bool retry = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Client': 'runner2',
    };
    if (auth && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final url = uri(path, query);
    AppLog.d('$method $url', scope: _scope);

    late http.Response response;
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 20));
        break;
      case 'POST':
        response = await http
            .post(url, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 20));
        break;
      case 'PATCH':
        response = await http
            .patch(url, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 20));
        break;
      case 'DELETE':
        response = await http
            .delete(url, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 20));
        break;
      default:
        throw Exception('unsupported method $method');
    }

    if (response.statusCode == 401 && auth && retry) {
      final refreshed = await tryRefresh();
      if (refreshed) {
        return request(
          method,
          path,
          body: body,
          query: query,
          auth: auth,
          retry: false,
        );
      }
      await clearTokens();
      if (onUnauthorized != null) await onUnauthorized!();
    }
    return response;
  }

  Future<bool> tryRefresh() async {
    if (refreshToken == null) return false;
    try {
      final response = await http
          .post(
            uri('/api/v1/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'refreshToken': refreshToken,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await saveTokens(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );
      return true;
    } catch (e, st) {
      AppLog.e('refresh failed', scope: _scope, error: e, stackTrace: st);
      return false;
    }
  }

  Future<Map<String, dynamic>> jsonOrThrow(http.Response response) async {
    return decodeJsonBody(response.body, response.statusCode);
  }

  /// 直接解析 JSON，避免 `http.Response(String)` 默认用 latin1 编码中文时报错。
  Map<String, dynamic> decodeJsonBody(String body, int statusCode) {
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(body) as Map);
    } catch (_) {
      throw Exception('服务器响应异常 ($statusCode)');
    }
    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }
    throw ApiException(
      data['error']?.toString() ?? '请求失败 ($statusCode)',
      code: data['code']?.toString(),
      statusCode: statusCode,
      mutedUntil: data['mutedUntil'] == null
          ? null
          : DateTime.tryParse(data['mutedUntil'].toString()),
    );
  }

  Future<http.StreamedResponse> multipartAvatar(String filePath) async {
    final req = http.MultipartRequest('POST', uri('/api/v1/me/avatar'));
    if (accessToken != null) {
      req.headers['Authorization'] = 'Bearer $accessToken';
    }
    final lower = filePath.toLowerCase();
    final contentType = lower.endsWith('.png')
        ? MediaType('image', 'png')
        : lower.endsWith('.gif')
            ? MediaType('image', 'gif')
            : lower.endsWith('.webp')
                ? MediaType('image', 'webp')
                : lower.endsWith('.heic') || lower.endsWith('.heif')
                    ? MediaType('image', 'heic')
                    : MediaType('image', 'jpeg');
    final name = filePath.split('/').last;
    req.files.add(
      await http.MultipartFile.fromPath(
        'avatar',
        filePath,
        filename: name.isEmpty ? 'avatar.jpg' : name,
        contentType: contentType,
      ),
    );
    return req.send().timeout(const Duration(seconds: 30));
  }
}
