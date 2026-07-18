import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../utils/debug_log.dart';

class AiApi {
  static const baseUrl = 'https://social.ctm.cloudpasture.site';
  static const _scope = 'ai_api';

  Future<String> chat(
    List<ChatMessage> messages, {
    String sessionId = 'ai',
  }) async {
    final uri = Uri.parse('$baseUrl/api/dazi/chat');
    final payload = {
      'sessionId': sessionId,
      'client': 'runner2',
      'messages': messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
    };
    final body = jsonEncode(payload);
    final started = DateTime.now();

    AppLog.i(
      'POST $uri',
      scope: _scope,
      data: {
        'sessionId': sessionId,
        'messageCount': messages.length,
        'bodyBytes': body.length,
        'lastRole': messages.isEmpty ? null : messages.last.role,
        'lastContentPreview': messages.isEmpty
            ? null
            : _preview(messages.last.content),
      },
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Client': 'runner2',
              'X-Session-Id': sessionId,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 35));

      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      AppLog.i(
        'response ${response.statusCode} in ${elapsedMs}ms',
        scope: _scope,
        data: {
          'bodyBytes': response.bodyBytes.length,
          'bodyPreview': _preview(response.body, max: 240),
        },
      );

      if (response.statusCode != 200) {
        AppLog.e(
          'AI 服务异常 status=${response.statusCode}',
          scope: _scope,
          error: response.body,
        );
        throw Exception('AI 服务异常 (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reply = data['reply'] as String?;
      if (reply == null || reply.isEmpty) {
        AppLog.e('AI 返回为空', scope: _scope, error: data);
        throw Exception('AI 返回为空');
      }
      AppLog.i(
        'reply ok',
        scope: _scope,
        data: {'replyChars': reply.length, 'preview': _preview(reply)},
      );
      return reply;
    } catch (e, st) {
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      AppLog.e(
        'chat failed after ${elapsedMs}ms',
        scope: _scope,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<bool> healthCheck() async {
    final uri = Uri.parse('$baseUrl/api/dazi/health');
    AppLog.d('GET $uri', scope: _scope);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      AppLog.i(
        'health ${response.statusCode}',
        scope: _scope,
        data: response.body,
      );
      return response.statusCode == 200;
    } catch (e, st) {
      AppLog.e('health failed', scope: _scope, error: e, stackTrace: st);
      return false;
    }
  }

  static String _preview(String text, {int max = 80}) {
    final compact = text.replaceAll('\n', '\\n');
    if (compact.length <= max) return compact;
    return '${compact.substring(0, max)}…';
  }
}
