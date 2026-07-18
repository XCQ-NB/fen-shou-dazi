import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/ai_api.dart';
import '../services/api_client.dart';
import '../services/realtime.dart';
import '../services/social_api.dart';
import '../utils/debug_log.dart';

class AppState extends ChangeNotifier {
  static const freeNotebookLimit = 2;
  static const maxStoryLength = 50000;
  static const maxBioLength = 50;
  final _uuid = const Uuid();
  final _ai = AiApi();
  final api = ApiClient();
  late final SocialApi social = SocialApi(api);
  late final RealtimeService realtime = RealtimeService(api);

  /// 应用文档目录，用于把头像等本地文件按相对文件名解析成绝对路径。
  String? _docDirPath;

  bool loading = true;
  bool loggedIn = false;
  bool isVip = false;
  bool needsProfile = false;
  UserAccount? account;
  List<UserAccount> discoverUsers = [];
  String? socialError;

  List<NotebookEntry> notes = [];
  AbstinenceState abstinence = const AbstinenceState();
  List<ChatSession> sessions = [];
  final Map<String, List<ChatMessage>> chatHistories = {};
  bool aiSending = false;
  String? aiError;

  Gender get myGender => account?.gender ?? Gender.male;

  Gender get preferredPartnerGender => myGender.opposite;

  String get notebookWeatherMood => abstinence.weatherMood;

  int get totalUnread =>
      sessions.fold<int>(0, (sum, s) => sum + (s.isAi ? 0 : s.unread));

  /// 把存储值解析为图片 provider：
  /// - 网络地址走 [NetworkImage]
  /// - 绝对路径（历史数据）或相对文件名统一解析成本地文件
  ImageProvider? imageProviderFor(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (stored.startsWith('http')) return NetworkImage(stored);
    final path = stored.startsWith('/')
        ? stored
        : '${_docDirPath ?? ''}/$stored';
    return FileImage(File(path));
  }

  String get _uid => account?.id ?? 'anon';

  String _k(String key) => '${_uid}_$key';

  Future<void> init() async {
    AppLog.i('AppState.init begin', scope: 'state');
    final underTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    if (!underTest) {
      try {
        _docDirPath = await getApplicationDocumentsDirectory()
            .timeout(const Duration(seconds: 2))
            .then((d) => d.path);
      } catch (e) {
        AppLog.w('docDir unavailable', scope: 'state', data: e);
      }
    }

    api.onUnauthorized = () async {
      loggedIn = false;
      needsProfile = false;
      notifyListeners();
    };
    await api.loadTokens();

    final prefs = await SharedPreferences.getInstance();
    isVip = prefs.getBool('isVip') ?? false;

    if (api.accessToken != null || api.refreshToken != null) {
      try {
        if (api.accessToken == null) {
          await api.tryRefresh();
        }
        account = await social.getMe();
        loggedIn = account!.profileComplete;
        needsProfile = !account!.profileComplete;
        await _loadLocalForUser();
        await _syncCloudForUser();
        _ensureAiSession();
        if (!underTest) {
          realtime.onEvent = _onRealtimeEvent;
          realtime.connect();
          // ignore: unawaited_futures
          refreshDiscover();
          // ignore: unawaited_futures
          refreshConversations();
        }
      } catch (e, st) {
        AppLog.e('session restore failed', scope: 'auth', error: e, stackTrace: st);
        await api.clearTokens();
        loggedIn = false;
        needsProfile = false;
        account = null;
      }
    }

    loading = false;
    AppLog.i(
      'AppState.init done',
      scope: 'state',
      data: {
        'loggedIn': loggedIn,
        'needsProfile': needsProfile,
        'hasAccount': account != null,
        'notes': notes.length,
        'sessions': sessions.length,
      },
    );
    if (!underTest && !const bool.fromEnvironment('FLUTTER_TEST')) {
      // ignore: unawaited_futures
      _ai.healthCheck();
    }
    notifyListeners();
  }

  Future<void> _loadLocalForUser() async {
    final prefs = await SharedPreferences.getInstance();
    notes = [];
    abstinence = const AbstinenceState();
    sessions = [];
    chatHistories.clear();

    final notesJson = prefs.getString(_k('notes'));
    if (notesJson != null) {
      final list = jsonDecode(notesJson) as List;
      notes = list
          .map(
            (e) =>
                NotebookEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    final absJson = prefs.getString(_k('abstinence'));
    if (absJson != null) {
      abstinence = AbstinenceState.fromJson(
        Map<String, dynamic>.from(jsonDecode(absJson) as Map),
      );
    }
    final historiesJson = prefs.getString(_k('aiHistory'));
    if (historiesJson != null) {
      final list = jsonDecode(historiesJson) as List;
      chatHistories['ai'] = list
          .map(
            (e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }
  }

  void _ensureAiSession() {
    if (!sessions.any((s) => s.isAi)) {
      sessions = [
        ChatSession(
          id: 'ai',
          title: 'AI 情绪陪伴',
          subtitle: chatHistories['ai']?.isNotEmpty == true
              ? chatHistories['ai']!.last.content
              : '随时聊聊你的感受',
          avatarUrl: '',
          updatedAt: DateTime.now(),
          isAi: true,
        ),
        ...sessions,
      ];
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isVip', isVip);
    if (account == null) return;
    await prefs.setString(
      _k('notes'),
      jsonEncode(notes.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_k('abstinence'), jsonEncode(abstinence.toJson()));
    await prefs.setString(
      _k('aiHistory'),
      jsonEncode((chatHistories['ai'] ?? []).map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _persistNotes() async {
    final prefs = await SharedPreferences.getInstance();
    if (account == null) return;
    await prefs.setString(
      _k('notes'),
      jsonEncode(notes.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _syncCloudForUser() async {
    if (_underTest || account == null) return;
    try {
      final data = await social.getSyncData();
      final remoteNotes = (data['notes'] as List? ?? [])
          .map(
            (e) => NotebookEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      if (remoteNotes.isEmpty && notes.isNotEmpty) {
        await social.syncNotes(notes);
      } else if (remoteNotes.isNotEmpty) {
        final merged = <String, NotebookEntry>{
          for (final n in notes) n.id: n,
        };
        for (final remote in remoteNotes) {
          final local = merged[remote.id];
          final remoteTime = remote.updatedAt ?? remote.date;
          final localTime = local?.updatedAt ?? local?.date;
          if (local == null || localTime == null || remoteTime.isAfter(localTime)) {
            merged[remote.id] = remote;
          }
        }
        notes = merged.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        await social.syncNotes(notes);
      }

      final remoteAbstinence = data['abstinence'];
      if (remoteAbstinence is Map && remoteAbstinence['state'] is Map) {
        abstinence = AbstinenceState.fromJson(
          Map<String, dynamic>.from(remoteAbstinence['state'] as Map),
        );
      } else if (abstinence.started || abstinence.breaks.isNotEmpty) {
        await social.syncAbstinence(abstinence);
      }

      final remoteAi = (data['aiMessages'] as List? ?? [])
          .map(
            (e) => ChatMessage.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      if (remoteAi.isNotEmpty) {
        chatHistories['ai'] = remoteAi;
      } else if (chatHistories['ai']?.isNotEmpty == true) {
        await social.syncAiMessages(chatHistories['ai']!);
      }

      isVip = data['isVip'] as bool? ?? account!.isVip;
      account = account!.copyWith(isVip: isVip);
      await _persist();
    } catch (e, st) {
      AppLog.e('cloud sync failed', scope: 'sync', error: e, stackTrace: st);
    }
  }

  Future<void> _pushNotes({List<String> deleteIds = const []}) async {
    if (_underTest || !loggedIn) return;
    try {
      await social.syncNotes(notes, deleteIds: deleteIds);
    } catch (e) {
      AppLog.w('notes cloud sync deferred', scope: 'sync', data: e);
    }
  }

  Future<void> _pushAbstinence() async {
    if (_underTest || !loggedIn) return;
    try {
      await social.syncAbstinence(abstinence);
    } catch (e) {
      AppLog.w('abstinence cloud sync deferred', scope: 'sync', data: e);
    }
  }

  Future<void> _pushAiHistory() async {
    if (_underTest || !loggedIn) return;
    try {
      await social.syncAiMessages(chatHistories['ai'] ?? []);
    } catch (e) {
      AppLog.w('AI history cloud sync deferred', scope: 'sync', data: e);
    }
  }

  Future<void> sendSmsCode(String phone) => social.sendSms(phone);

  /// 短信登录/注册。返回是否需要完善资料。
  Future<bool> loginWithSms({
    required String phone,
    required String code,
  }) async {
    AppLog.i('loginWithSms', scope: 'auth', data: {'phone': phone});
    final result = await social.verifySms(phone, code);
    account = result.user;
    needsProfile = !result.profileComplete;
    loggedIn = result.profileComplete;
    await _loadLocalForUser();
    await _syncCloudForUser();
    _ensureAiSession();
    realtime.onEvent = _onRealtimeEvent;
    realtime.connect();
    if (loggedIn) {
      await refreshDiscover();
      await refreshConversations();
    }
    await _persist();
    notifyListeners();
    return needsProfile;
  }

  Future<void> completeProfile({
    required String username,
    required int age,
    required int height,
    required Gender gender,
    required String avatarUrl,
    String bio = '',
    String story = '',
    List<String> storyImageUrls = const [],
    String? city,
  }) async {
    if (story.length > maxStoryLength) {
      throw ArgumentError('我的故事最多 $maxStoryLength 字');
    }
    if (bio.length > maxBioLength) {
      throw ArgumentError('个性签名最多 $maxBioLength 字');
    }
    AppLog.i(
      'completeProfile',
      scope: 'auth',
      data: {
        'username': username,
        'age': age,
        'gender': gender.name,
        'city': city,
      },
    );

    var remoteAvatar = avatarUrl;
    if (!avatarUrl.startsWith('http')) {
      // 本地文件先上传
      final underTest = WidgetsBinding.instance.runtimeType
          .toString()
          .contains('Test');
      if (!underTest) {
        final abs = avatarUrl.startsWith('/')
            ? avatarUrl
            : '${_docDirPath ?? ''}/$avatarUrl';
        remoteAvatar = await social.uploadAvatar(abs);
      }
    }

    account = await social.patchMe({
      'nickname': username,
      'age': age,
      'height': height,
      'gender': gender == Gender.male ? 'male' : 'female',
      'avatarUrl': remoteAvatar,
      'bio': bio.trim(),
      'story': story.trim(),
      'city': city ?? account?.city ?? '娄底市',
      'discoverable': true,
    });
    loggedIn = true;
    needsProfile = false;
    _ensureAiSession();
    await refreshDiscover();
    await refreshConversations();
    await _persist();
    notifyListeners();
  }

  Future<void> updateStory(
    String story, {
    List<String>? imageUrls,
  }) async {
    if (account == null) return;
    if (story.length > maxStoryLength) {
      throw ArgumentError('我的故事最多 $maxStoryLength 字');
    }
    account = await social.patchMe({'story': story.trim()});
    await _persist();
    notifyListeners();
  }

  Future<void> setVip(bool value) async {
    AppLog.i('setVip=$value', scope: 'auth');
    isVip = _underTest ? value : await social.setVipDemo(value);
    account = account?.copyWith(isVip: isVip);
    await _persist();
    notifyListeners();
  }

  Future<void> submitFeedback(String content) async {
    final text = content.trim();
    if (text.isEmpty || text.length > 2000) {
      throw ArgumentError('反馈内容需在 1–2000 字之间');
    }
    if (_underTest) return;
    await social.submitFeedback(text);
  }

  Future<void> reportUser({
    required String userId,
    required String reasonCode,
    String detail = '',
  }) async {
    if (_underTest) return;
    await social.reportUser(
      userId: userId,
      reasonCode: reasonCode,
      detail: detail,
    );
  }

  bool get _underTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  Future<void> logout() async {
    AppLog.i('logout', scope: 'auth');
    realtime.disconnect();
    if (!_underTest) {
      await social.logout();
    } else {
      await api.clearTokens();
    }
    loggedIn = false;
    needsProfile = false;
    account = null;
    discoverUsers = [];
    sessions = [];
    chatHistories.clear();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    AppLog.i('deleteAccount', scope: 'auth');
    final uid = account?.id;
    realtime.disconnect();
    if (!_underTest) {
      try {
        await social.deleteAccount();
      } catch (_) {}
    } else {
      await api.clearTokens();
    }
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      for (final key in ['notes', 'abstinence', 'aiHistory']) {
        await prefs.remove('${uid}_$key');
      }
    }
    loggedIn = false;
    needsProfile = false;
    account = null;
    notes = [];
    abstinence = const AbstinenceState();
    sessions = [];
    chatHistories.clear();
    discoverUsers = [];
    notifyListeners();
  }

  Future<void> refreshDiscover({int filterIndex = 2}) async {
    if (!loggedIn) return;
    final filter = switch (filterIndex) {
      0 => 'online',
      1 => 'city',
      _ => 'recommend',
    };
    try {
      discoverUsers = await social.discover(filter);
      socialError = null;
    } catch (e) {
      socialError = e.toString();
      AppLog.e('discover failed', scope: 'social', error: e);
    }
    notifyListeners();
  }

  List<UserAccount> oppositeGenderUsers() => discoverUsers;

  List<UserAccount> usersForFilter(int filterIndex) {
    // 服务端已按 filter 拉取；本地再兜底一次
    if (filterIndex == 0) {
      return discoverUsers.where((u) => u.isOnline).toList();
    }
    if (filterIndex == 1) {
      final city = account?.city ?? '';
      return discoverUsers
          .where((u) => city.isEmpty || u.city == city)
          .toList();
    }
    return discoverUsers;
  }

  UserAccount? userById(String id) {
    if (account?.id == id) return account;
    for (final u in discoverUsers) {
      if (u.id == id) return u;
    }
    for (final s in sessions) {
      if (s.peerUserId == id) {
        return UserAccount(
          id: id,
          username: s.title,
          age: 0,
          gender: s.peerGender ?? Gender.female,
          avatarUrl: s.avatarUrl,
        );
      }
    }
    return null;
  }

  Future<void> refreshConversations() async {
    if (!loggedIn) return;
    try {
      final remote = await social.listConversations();
      final ai = sessions.where((s) => s.isAi).toList();
      sessions = [...ai, ...remote];
      _ensureAiSession();
    } catch (e) {
      AppLog.e('refreshConversations failed', scope: 'social', error: e);
    }
    notifyListeners();
  }

  void _onRealtimeEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'account.muted') {
      account = account?.copyWith(
        accountStatus: 'muted',
        mutedUntil: DateTime.tryParse(event['mutedUntil']?.toString() ?? ''),
      );
      notifyListeners();
      return;
    }
    if (type == 'account.banned') {
      loggedIn = false;
      account = account?.copyWith(accountStatus: 'banned');
      api.clearTokens();
      notifyListeners();
      return;
    }
    if (type == 'account.restored') {
      account = account?.copyWith(accountStatus: 'active');
      notifyListeners();
      return;
    }
    if (type == 'message.new') {
      final m = event['message'];
      if (m is! Map) return;
      final map = Map<String, dynamic>.from(m);
      final convId = map['conversationId'] as String?;
      final senderId = map['senderId'] as String?;
      if (convId == null) return;
      final mine = senderId == account?.id;
      final msg = ChatMessage(
        id: map['id'] as String? ?? _uuid.v4(),
        role: mine ? 'user' : 'peer',
        content: map['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        senderId: senderId,
        clientMessageId: map['clientMessageId'] as String?,
      );
      final history = List<ChatMessage>.from(chatHistories[convId] ?? []);
      if (history.any((e) => e.id == msg.id ||
          (msg.clientMessageId != null &&
              e.clientMessageId == msg.clientMessageId))) {
        return;
      }
      history.add(msg);
      chatHistories[convId] = history;
      sessions = [
        for (final s in sessions)
          if (s.id == convId)
            s.copyWith(
              subtitle: msg.content,
              updatedAt: msg.createdAt,
              unread: mine ? 0 : s.unread + 1,
            )
          else
            s,
      ];
      notifyListeners();
    }
  }

  bool get canCreateNote => isVip || notes.length < freeNotebookLimit;

  NotebookEntry? noteById(String id) {
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  Future<NotebookEntry?> createNote(String content) async {
    if (!canCreateNote) return null;
    final now = DateTime.now();
    final abstinenceDay = dayIndexFor(now);
    final entry = NotebookEntry(
      id: _uuid.v4(),
      dayIndex: abstinenceDay ?? 0,
      date: now,
      content: content,
      mood: weatherMoodForDate(now) ?? 'sun',
      updatedAt: now,
    );
    notes = [entry, ...notes];
    await _persistNotes();
    await _pushNotes();
    notifyListeners();
    return notes.firstWhere((e) => e.id == entry.id);
  }

  Future<NotebookEntry?> upsertNoteContent({
    String? id,
    required String content,
  }) async {
    if (id == null) {
      if (content.trim().isEmpty) return null;
      if (!canCreateNote) return null;
      return createNote(content);
    }
    final existing = noteById(id);
    if (existing == null) return null;
    notes = [
      for (final note in notes)
        if (note.id == id)
          note.copyWith(content: content, updatedAt: DateTime.now())
        else
          note,
    ];
    await _persistNotes();
    await _pushNotes();
    notifyListeners();
    return noteById(id);
  }

  Future<void> deleteNote(String id) async {
    notes = notes.where((e) => e.id != id).toList();
    await _persistNotes();
    await _pushNotes(deleteIds: [id]);
    notifyListeners();
  }

  Future<void> startAbstinence({
    required int hours,
    required int minutes,
  }) async {
    final startedAt = DateTime.now().subtract(
      Duration(hours: hours, minutes: minutes),
    );
    AppLog.i(
      'startAbstinence',
      scope: 'abstinence',
      data: {
        'hours': hours,
        'minutes': minutes,
        'startedAt': startedAt.toIso8601String(),
      },
    );
    final breaks = [...abstinence.breaks];
    if (breaks.isNotEmpty && breaks.last.restartedAt == null) {
      final last = breaks.removeLast();
      breaks.add(
        ContactBreakEvent(
          at: last.at,
          segmentStartedAt: last.segmentStartedAt,
          restartedAt: startedAt,
          daysBefore: last.daysBefore,
        ),
      );
    }
    abstinence = AbstinenceState(
      started: true,
      startedAt: startedAt,
      initialHours: 0,
      initialMinutes: 0,
      breaks: breaks,
    );
    await _persist();
    await _pushAbstinence();
    notifyListeners();
  }

  Future<void> markContacted() async {
    if (!abstinence.started || abstinence.startedAt == null) {
      AppLog.w('markContacted ignored: not started', scope: 'abstinence');
      return;
    }
    final days = abstinence.dayCount;
    AppLog.i('markContacted', scope: 'abstinence', data: {'daysBefore': days});
    final event = ContactBreakEvent(
      at: DateTime.now(),
      segmentStartedAt: _currentSegmentStart,
      daysBefore: days,
    );
    abstinence = abstinence.copyWith(
      started: false,
      clearStartedAt: true,
      initialHours: 0,
      initialMinutes: 0,
      breaks: [...abstinence.breaks, event],
    );
    await _persist();
    await _pushAbstinence();
    notifyListeners();
  }

  Future<void> restartAfterContact() async {
    final breaks = [...abstinence.breaks];
    if (breaks.isNotEmpty) {
      final last = breaks.removeLast();
      breaks.add(
        ContactBreakEvent(
          at: last.at,
          segmentStartedAt: last.segmentStartedAt,
          restartedAt: DateTime.now(),
          daysBefore: last.daysBefore,
        ),
      );
    }
    abstinence = AbstinenceState(
      started: true,
      startedAt: DateTime.now(),
      initialHours: 0,
      initialMinutes: 0,
      breaks: breaks,
    );
    await _persist();
    await _pushAbstinence();
    notifyListeners();
  }

  DayStatus statusForDate(DateTime day) {
    return isContactedDay(day) ? DayStatus.contacted : DayStatus.noContact;
  }

  bool isNoContactDay(DateTime day) {
    final d = _dateOnly(day);
    final today = _dateOnly(DateTime.now());
    if (d.isAfter(today)) return false;

    for (final event in abstinence.breaks) {
      final start = _dateOnly(_segmentStartFor(event));
      final contacted = _dateOnly(event.at);
      // 联系当天仍是本轮最后一个断联日，并计入第 X 天。
      if (!d.isBefore(start) && !d.isAfter(contacted)) return true;
    }

    final currentStart = _currentSegmentStart;
    if (!abstinence.started || currentStart == null) return false;
    final start = _dateOnly(currentStart);
    return !d.isBefore(start) && !d.isAfter(today);
  }

  bool isContactedDay(DateTime day) {
    final d = _dateOnly(day);
    return abstinence.breaks.any((b) {
      final bd = _dateOnly(b.at);
      return bd == d;
    });
  }

  int? dayIndexFor(DateTime day) {
    final d = _dateOnly(day);
    if (!isNoContactDay(d)) return null;

    for (final event in abstinence.breaks) {
      final start = _dateOnly(_segmentStartFor(event));
      final contacted = _dateOnly(event.at);
      if (!d.isBefore(start) && !d.isAfter(contacted)) {
        return d.difference(start).inDays + 1;
      }
    }

    final currentStart = _currentSegmentStart;
    if (abstinence.started && currentStart != null) {
      return d.difference(_dateOnly(currentStart)).inDays + 1;
    }
    return null;
  }

  String? weatherMoodForDate(DateTime day) {
    final index = dayIndexFor(day);
    if (index == null) return null;
    if (index <= 4) return 'rain';
    if (index <= 7) return 'cloud';
    return 'sun';
  }

  DateTime? segmentStartedAtFor(DateTime day) {
    final d = _dateOnly(day);
    if (!isNoContactDay(d)) return null;
    for (final event in abstinence.breaks) {
      final start = _segmentStartFor(event);
      if (!d.isBefore(_dateOnly(start)) &&
          !d.isAfter(_dateOnly(event.at))) {
        return start;
      }
    }
    return _currentSegmentStart;
  }

  ContactBreakEvent? breakForDate(DateTime day) {
    final d = _dateOnly(day);
    for (final b in abstinence.breaks) {
      final bd = _dateOnly(b.at);
      if (bd == d) return b;
    }
    return null;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime? get _currentSegmentStart {
    final startedAt = abstinence.startedAt;
    if (startedAt == null) return null;
    return startedAt.subtract(
      Duration(
        hours: abstinence.initialHours,
        minutes: abstinence.initialMinutes,
      ),
    );
  }

  DateTime _segmentStartFor(ContactBreakEvent event) {
    if (event.segmentStartedAt != null) return event.segmentStartedAt!;
    // 兼容升级前的数据：根据当时记录的天数近似恢复历史起点。
    return _dateOnly(
      event.at,
    ).subtract(Duration(days: (event.daysBefore - 1).clamp(0, 100000)));
  }

  List<ChatMessage> messagesFor(String sessionId) {
    return chatHistories[sessionId] ?? [];
  }

  List<ChatSession> visibleSessions() {
    final preferred = preferredPartnerGender;
    return sessions.where((s) {
      if (s.isAi) return true;
      return s.peerGender == preferred;
    }).toList()
      ..sort((a, b) {
        if (a.isAi && !b.isAi) return -1;
        if (!a.isAi && b.isAi) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  Future<ChatSession> ensureDirectSession(UserAccount user) async {
    final existing = sessions.where((s) => s.peerUserId == user.id).toList();
    if (existing.isNotEmpty) {
      await loadMessages(existing.first.id);
      return existing.first;
    }
    final session = await social.openConversation(user.id);
    sessions = [session, ...sessions.where((s) => s.id != session.id)];
    _ensureAiSession();
    await loadMessages(session.id);
    notifyListeners();
    return session;
  }

  Future<void> loadMessages(String sessionId) async {
    if (sessionId == 'ai') return;
    try {
      final list = await social.listMessages(sessionId);
      chatHistories[sessionId] = list
          .map(
            (m) => ChatMessage(
              id: m.id,
              role: m.senderId == account?.id ? 'user' : 'peer',
              content: m.content,
              createdAt: m.createdAt,
              senderId: m.senderId,
              clientMessageId: m.clientMessageId,
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      AppLog.e('loadMessages failed', scope: 'social', error: e);
    }
  }

  Future<void> markSessionRead(String sessionId) async {
    sessions = [
      for (final s in sessions)
        if (s.id == sessionId) s.copyWith(unread: 0) else s,
    ];
    notifyListeners();
    if (sessionId != 'ai') {
      try {
        await social.markRead(sessionId);
      } catch (_) {}
    }
  }

  Future<void> sendDirectMessage(String sessionId, String text) async {
    final content = text.trim();
    if (content.isEmpty) return;
    final clientId = _uuid.v4();
    final optimistic = ChatMessage(
      id: clientId,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
      senderId: account?.id,
      clientMessageId: clientId,
    );
    final history = List<ChatMessage>.from(chatHistories[sessionId] ?? []);
    history.add(optimistic);
    chatHistories[sessionId] = history;
    sessions = [
      for (final s in sessions)
        if (s.id == sessionId)
          s.copyWith(subtitle: content, updatedAt: DateTime.now(), unread: 0)
        else
          s,
    ];
    notifyListeners();
    try {
      final saved = await social.sendMessage(
        conversationId: sessionId,
        body: content,
        clientMessageId: clientId,
      );
      final idx = history.indexWhere((m) => m.clientMessageId == clientId);
      if (idx >= 0) {
        final prev = history[idx];
        // 静默替换服务端 id，不 notify，避免列表二次重建造成跳动
        history[idx] = ChatMessage(
          id: saved.id,
          role: 'user',
          content: saved.content,
          createdAt: prev.createdAt,
          senderId: saved.senderId,
          clientMessageId: clientId,
        );
        chatHistories[sessionId] = history;
      }
    } catch (e, st) {
      AppLog.e('sendDirectMessage failed', scope: 'social', error: e, stackTrace: st);
      history.removeWhere((m) => m.clientMessageId == clientId);
      chatHistories[sessionId] = List<ChatMessage>.from(history);
      if (e is ApiException && e.code == 'ACCOUNT_MUTED') {
        account = account?.copyWith(
          accountStatus: 'muted',
          mutedUntil: e.mutedUntil,
        );
      }
      socialError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendAiMessage(String text) async {
    final content = text.trim();
    if (content.isEmpty || aiSending) {
      AppLog.w(
        'sendAiMessage skipped',
        scope: 'chat',
        data: {'empty': content.isEmpty, 'aiSending': aiSending},
      );
      return;
    }
    aiSending = true;
    aiError = null;
    final history = List<ChatMessage>.from(chatHistories['ai'] ?? []);
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
    history.add(userMsg);
    chatHistories['ai'] = history;
    sessions = [
      for (final s in sessions)
        if (s.id == 'ai')
          s.copyWith(subtitle: content, updatedAt: DateTime.now(), unread: 0)
        else
          s,
    ];
    AppLog.i(
      'sendAiMessage',
      scope: 'chat',
      data: {
        'chars': content.length,
        'historyBeforeReply': history.length,
        'preview': content.length > 60 ? '${content.substring(0, 60)}…' : content,
      },
    );
    notifyListeners();

    try {
      final reply = await _ai.chat(history, sessionId: 'ai');
      history.add(
        ChatMessage(
          id: _uuid.v4(),
          role: 'assistant',
          content: reply,
          createdAt: DateTime.now(),
        ),
      );
      chatHistories['ai'] = history;
      sessions = [
        for (final s in sessions)
          if (s.id == 'ai')
            s.copyWith(subtitle: reply, updatedAt: DateTime.now())
          else
            s,
      ];
      await _persist();
      await _pushAiHistory();
      AppLog.i('sendAiMessage ok', scope: 'chat', data: {'replyChars': reply.length});
    } catch (e, st) {
      aiError = e.toString();
      AppLog.e('sendAiMessage failed', scope: 'chat', error: e, stackTrace: st);
    } finally {
      aiSending = false;
      notifyListeners();
    }
  }
}
