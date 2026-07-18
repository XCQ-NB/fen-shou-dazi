import '../models/models.dart';
import 'api_client.dart';

class SocialApi {
  SocialApi(this.client);
  final ApiClient client;

  Future<void> sendSms(String phone) async {
    final res = await client.request(
      'POST',
      '/api/v1/auth/sms/send',
      body: {'phone': phone},
      auth: false,
    );
    await client.jsonOrThrow(res);
  }

  Future<SmsLoginResult> verifySms(String phone, String code) async {
    final res = await client.request(
      'POST',
      '/api/v1/auth/sms/verify',
      body: {
        'phone': phone,
        'code': code,
        'deviceId': client.deviceId,
      },
      auth: false,
    );
    final data = await client.jsonOrThrow(res);
    await client.saveTokens(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
    return SmsLoginResult(
      isNew: data['isNew'] as bool? ?? false,
      profileComplete: data['profileComplete'] as bool? ?? false,
      user: UserAccount.fromServer(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await client.request(
        'POST',
        '/api/v1/auth/logout',
        body: {'refreshToken': client.refreshToken},
        auth: false,
      );
    } catch (_) {}
    await client.clearTokens();
  }

  Future<UserAccount> getMe() async {
    final res = await client.request('GET', '/api/v1/me');
    final data = await client.jsonOrThrow(res);
    return UserAccount.fromServer(data['user'] as Map<String, dynamic>);
  }

  Future<UserAccount> patchMe(Map<String, dynamic> body) async {
    final res = await client.request('PATCH', '/api/v1/me', body: body);
    final data = await client.jsonOrThrow(res);
    return UserAccount.fromServer(data['user'] as Map<String, dynamic>);
  }

  Future<String> uploadAvatar(String filePath) async {
    var streamed = await client.multipartAvatar(filePath);
    if (streamed.statusCode == 401) {
      final ok = await client.tryRefresh();
      if (ok) streamed = await client.multipartAvatar(filePath);
    }
    final body = await streamed.stream.bytesToString();
    // 勿用 http.Response(body, …)：无 charset 时会按 latin1 编码，中文昵称会直接抛错
    final data = client.decodeJsonBody(body, streamed.statusCode);
    final url = data['avatarUrl']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('头像上传失败');
    }
    return url;
  }

  Future<void> deleteAccount() async {
    final res = await client.request('DELETE', '/api/v1/me');
    await client.jsonOrThrow(res);
    await client.clearTokens();
  }

  Future<List<UserAccount>> discover(String filter) async {
    final res = await client.request(
      'GET',
      '/api/v1/users/discover',
      query: {'filter': filter, 'limit': '50'},
    );
    final data = await client.jsonOrThrow(res);
    final list = data['users'] as List? ?? [];
    return list
        .map((e) => UserAccount.fromServer(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<UserAccount> userById(String id) async {
    final res = await client.request('GET', '/api/v1/users/$id');
    final data = await client.jsonOrThrow(res);
    return UserAccount.fromServer(data['user'] as Map<String, dynamic>);
  }

  Future<ChatSession> openConversation(String peerUserId) async {
    final res = await client.request(
      'POST',
      '/api/v1/conversations',
      body: {'peerUserId': peerUserId},
    );
    final data = await client.jsonOrThrow(res);
    final c = data['conversation'] as Map<String, dynamic>;
    final peer = UserAccount.fromServer(
      Map<String, dynamic>.from(c['peer'] as Map),
    );
    return ChatSession(
      id: c['id'] as String,
      title: peer.username,
      subtitle: '',
      avatarUrl: peer.avatarUrl ?? '',
      updatedAt: DateTime.tryParse(c['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      peerUserId: peer.id,
      peerGender: peer.gender,
    );
  }

  Future<List<ChatSession>> listConversations() async {
    final res = await client.request('GET', '/api/v1/conversations');
    final data = await client.jsonOrThrow(res);
    final list = data['conversations'] as List? ?? [];
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final peer = UserAccount.fromServer(
        Map<String, dynamic>.from(m['peer'] as Map),
      );
      return ChatSession(
        id: m['id'] as String,
        title: peer.username,
        subtitle: m['lastMessage'] as String? ?? '',
        avatarUrl: peer.avatarUrl ?? '',
        updatedAt:
            DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
        unread: m['unread'] as int? ?? 0,
        peerUserId: peer.id,
        peerGender: peer.gender,
      );
    }).toList();
  }

  Future<List<ChatMessage>> listMessages(String conversationId) async {
    final res = await client.request(
      'GET',
      '/api/v1/conversations/$conversationId/messages',
      query: {'limit': '100'},
    );
    final data = await client.jsonOrThrow(res);
    final list = data['messages'] as List? ?? [];
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ChatMessage(
        id: m['id'] as String? ?? '',
        role: 'pending', // filled by caller with mine check
        content: m['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        senderId: m['senderId'] as String?,
        clientMessageId: m['clientMessageId'] as String?,
      );
    }).toList();
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String body,
    required String clientMessageId,
  }) async {
    final res = await client.request(
      'POST',
      '/api/v1/conversations/$conversationId/messages',
      body: {'body': body, 'clientMessageId': clientMessageId},
    );
    final data = await client.jsonOrThrow(res);
    final m = Map<String, dynamic>.from(data['message'] as Map);
    return ChatMessage(
      id: m['id'] as String? ?? '',
      role: 'user',
      content: m['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      senderId: m['senderId'] as String?,
      clientMessageId: m['clientMessageId'] as String?,
    );
  }

  Future<void> markRead(String conversationId) async {
    final res = await client.request(
      'POST',
      '/api/v1/conversations/$conversationId/read',
    );
    await client.jsonOrThrow(res);
  }

  Future<Map<String, dynamic>> getSyncData() async {
    final res = await client.request('GET', '/api/v1/sync');
    return client.jsonOrThrow(res);
  }

  Future<void> syncNotes(
    List<NotebookEntry> notes, {
    List<String> deleteIds = const [],
  }) async {
    final res = await client.request(
      'POST',
      '/api/v1/sync/notes/batch',
      body: {
        'upsert': notes.map((n) => n.toJson()).toList(),
        'deleteIds': deleteIds,
      },
    );
    await client.jsonOrThrow(res);
  }

  Future<void> syncAbstinence(
    AbstinenceState state, {
    DateTime? updatedAt,
  }) async {
    final res = await client.request(
      'PUT',
      '/api/v1/sync/abstinence',
      body: {
        'state': state.toJson(),
        'updatedAt': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
      },
    );
    await client.jsonOrThrow(res);
  }

  Future<void> syncAiMessages(List<ChatMessage> messages) async {
    final res = await client.request(
      'POST',
      '/api/v1/sync/ai/messages/batch',
      body: {'messages': messages.map((m) => m.toJson()).toList()},
    );
    await client.jsonOrThrow(res);
  }

  Future<bool> setVipDemo(bool enabled) async {
    final res = await client.request(
      'POST',
      '/api/v1/sync/vip/demo',
      body: {'enabled': enabled},
    );
    final data = await client.jsonOrThrow(res);
    return data['isVip'] as bool? ?? enabled;
  }

  Future<void> submitFeedback(String content) async {
    final res = await client.request(
      'POST',
      '/api/v1/sync/feedback',
      body: {'content': content},
    );
    await client.jsonOrThrow(res);
  }

  Future<void> reportUser({
    required String userId,
    required String reasonCode,
    String detail = '',
  }) async {
    final res = await client.request(
      'POST',
      '/api/v1/users/$userId/reports',
      body: {'reasonCode': reasonCode, 'detail': detail.trim()},
    );
    await client.jsonOrThrow(res);
  }
}

class SmsLoginResult {
  final bool isNew;
  final bool profileComplete;
  final UserAccount user;

  const SmsLoginResult({
    required this.isNew,
    required this.profileComplete,
    required this.user,
  });
}
