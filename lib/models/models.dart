enum Gender { female, male }

extension GenderX on Gender {
  Gender get opposite => this == Gender.male ? Gender.female : Gender.male;

  String get label => this == Gender.male ? '男' : '女';
}

class UserAccount {
  final String id;
  final String username;
  final String phone;
  final int age;
  final int height;
  final Gender gender;
  final String city;
  final String? avatarUrl;
  final String bio;
  final String story;
  final List<String> storyImageUrls;
  final bool isOnline;
  final bool profileComplete;
  final bool isVip;
  final String role;
  final String accountStatus;
  final DateTime? mutedUntil;
  final DateTime? lastActiveAt;
  final int chatActivityScore;

  const UserAccount({
    this.id = '',
    required this.username,
    this.phone = '',
    required this.age,
    this.height = 170,
    required this.gender,
    this.city = '未知',
    this.avatarUrl,
    this.bio = '',
    this.story = '',
    this.storyImageUrls = const [],
    this.isOnline = false,
    this.profileComplete = false,
    this.isVip = false,
    this.role = 'user',
    this.accountStatus = 'active',
    this.mutedUntil,
    this.lastActiveAt,
    this.chatActivityScore = 0,
  });

  UserAccount copyWith({
    String? id,
    String? username,
    String? phone,
    int? age,
    int? height,
    Gender? gender,
    String? city,
    String? avatarUrl,
    String? bio,
    String? story,
    List<String>? storyImageUrls,
    bool? isOnline,
    bool? profileComplete,
    bool? isVip,
    String? role,
    String? accountStatus,
    DateTime? mutedUntil,
    DateTime? lastActiveAt,
    int? chatActivityScore,
  }) {
    return UserAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      story: story ?? this.story,
      storyImageUrls: storyImageUrls ?? this.storyImageUrls,
      isOnline: isOnline ?? this.isOnline,
      profileComplete: profileComplete ?? this.profileComplete,
      isVip: isVip ?? this.isVip,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      chatActivityScore: chatActivityScore ?? this.chatActivityScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'phone': phone,
    'age': age,
    'height': height,
    'gender': gender == Gender.male ? 'male' : 'female',
    'city': city,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'story': story,
    'storyImageUrls': storyImageUrls,
    'profileComplete': profileComplete,
    'isVip': isVip,
    'role': role,
    'accountStatus': accountStatus,
    'mutedUntil': mutedUntil?.toIso8601String(),
  };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ??
          json['nickname'] as String? ??
          '用户',
      phone: json['phone'] as String? ?? '',
      age: json['age'] as int? ?? 18,
      height: json['height'] as int? ?? 170,
      gender: (json['gender'] as String?) == 'male'
          ? Gender.male
          : Gender.female,
      city: json['city'] as String? ?? '未知',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      story: json['story'] as String? ?? '',
      storyImageUrls: (json['storyImageUrls'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      profileComplete: json['profileComplete'] as bool? ?? false,
      isVip: json['isVip'] as bool? ?? false,
      role: json['role'] as String? ?? 'user',
      accountStatus: json['accountStatus'] as String? ?? 'active',
      mutedUntil: json['mutedUntil'] == null
          ? null
          : DateTime.tryParse(json['mutedUntil'].toString()),
      isOnline: json['isOnline'] as bool? ?? false,
      lastActiveAt: json['lastSeenAt'] == null
          ? null
          : DateTime.tryParse(json['lastSeenAt'] as String),
    );
  }

  factory UserAccount.fromServer(Map<String, dynamic> json) =>
      UserAccount.fromJson({
        ...json,
        'username': json['nickname'] ?? json['username'],
      });
}

class FeedPost {
  final String id;
  final String authorName;
  final Gender gender;
  final String avatarUrl;
  final String imageUrl;
  final String content;
  final String city;
  final DateTime createdAt;

  const FeedPost({
    required this.id,
    required this.authorName,
    required this.gender,
    required this.avatarUrl,
    required this.imageUrl,
    required this.content,
    required this.city,
    required this.createdAt,
  });
}

class ChatSession {
  final String id;
  final String title;
  final String subtitle;
  final String avatarUrl;
  final DateTime updatedAt;
  final bool isAi;
  final int unread;
  final String? peerUserId;
  final Gender? peerGender;

  const ChatSession({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    required this.updatedAt,
    this.isAi = false,
    this.unread = 0,
    this.peerUserId,
    this.peerGender,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? avatarUrl,
    DateTime? updatedAt,
    bool? isAi,
    int? unread,
    String? peerUserId,
    Gender? peerGender,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      isAi: isAi ?? this.isAi,
      unread: unread ?? this.unread,
      peerUserId: peerUserId ?? this.peerUserId,
      peerGender: peerGender ?? this.peerGender,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'avatarUrl': avatarUrl,
    'updatedAt': updatedAt.toIso8601String(),
    'isAi': isAi,
    'unread': unread,
    'peerUserId': peerUserId,
    'peerGender': peerGender == null
        ? null
        : (peerGender == Gender.male ? 'male' : 'female'),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final gender = json['peerGender'] as String?;
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isAi: json['isAi'] as bool? ?? false,
      unread: json['unread'] as int? ?? 0,
      peerUserId: json['peerUserId'] as String?,
      peerGender: gender == null
          ? null
          : (gender == 'male' ? Gender.male : Gender.female),
    );
  }
}

class ChatMessage {
  final String id;
  final String role; // user | assistant | peer
  final String content;
  final DateTime createdAt;
  final String? senderId;
  final String? clientMessageId;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.senderId,
    this.clientMessageId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'senderId': senderId,
    'clientMessageId': clientMessageId,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      senderId: json['senderId'] as String?,
      clientMessageId: json['clientMessageId'] as String?,
    );
  }
}

class NotebookEntry {
  final String id;
  final int dayIndex;
  final DateTime date;
  final String content;
  final String mood; // rain | cloud | moon | sun
  final DateTime? updatedAt;

  const NotebookEntry({
    required this.id,
    required this.dayIndex,
    required this.date,
    required this.content,
    required this.mood,
    this.updatedAt,
  });

  NotebookEntry copyWith({
    String? id,
    int? dayIndex,
    DateTime? date,
    String? content,
    String? mood,
    DateTime? updatedAt,
  }) {
    return NotebookEntry(
      id: id ?? this.id,
      dayIndex: dayIndex ?? this.dayIndex,
      date: date ?? this.date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayIndex': dayIndex,
    'date': date.toIso8601String(),
    'content': content,
    'mood': mood,
    'updatedAt': (updatedAt ?? date).toIso8601String(),
  };

  factory NotebookEntry.fromJson(Map<String, dynamic> json) {
    return NotebookEntry(
      id: json['id'] as String,
      dayIndex: json['dayIndex'] as int,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      mood: json['mood'] as String? ?? 'sun',
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }
}

enum DayStatus { noContact, contacted }

class ContactBreakEvent {
  final DateTime at;
  final DateTime? segmentStartedAt;
  final DateTime? restartedAt;
  final int daysBefore;

  const ContactBreakEvent({
    required this.at,
    this.segmentStartedAt,
    this.restartedAt,
    required this.daysBefore,
  });

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'segmentStartedAt': segmentStartedAt?.toIso8601String(),
    'restartedAt': restartedAt?.toIso8601String(),
    'daysBefore': daysBefore,
  };

  factory ContactBreakEvent.fromJson(Map<String, dynamic> json) {
    return ContactBreakEvent(
      at: DateTime.parse(json['at'] as String),
      segmentStartedAt: json['segmentStartedAt'] == null
          ? null
          : DateTime.parse(json['segmentStartedAt'] as String),
      restartedAt: json['restartedAt'] == null
          ? null
          : DateTime.parse(json['restartedAt'] as String),
      daysBefore: json['daysBefore'] as int,
    );
  }
}

class AbstinenceState {
  final bool started;
  final DateTime? startedAt;
  final int initialHours;
  final int initialMinutes;
  final List<ContactBreakEvent> breaks;

  const AbstinenceState({
    this.started = false,
    this.startedAt,
    this.initialHours = 0,
    this.initialMinutes = 0,
    this.breaks = const [],
  });

  Duration get elapsed {
    if (!started || startedAt == null) {
      return Duration(hours: initialHours, minutes: initialMinutes);
    }
    return DateTime.now().difference(startedAt!) +
        Duration(hours: initialHours, minutes: initialMinutes);
  }

  int get dayCount {
    if (!started || startedAt == null) return 1;
    final effectiveStart = startedAt!.subtract(
      Duration(hours: initialHours, minutes: initialMinutes),
    );
    final startDay = DateTime(
      effectiveStart.year,
      effectiveStart.month,
      effectiveStart.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final total = today.difference(startDay).inDays;
    return total < 0 ? 1 : total + 1;
  }

  /// Weather synced with notebook icons.
  String get weatherMood {
    if (!started) return 'sun';
    final days = dayCount;
    if (days <= 3) return 'rain';
    if (days <= 7) return 'cloud';
    return 'sun';
  }

  AbstinenceState copyWith({
    bool? started,
    DateTime? startedAt,
    int? initialHours,
    int? initialMinutes,
    List<ContactBreakEvent>? breaks,
    bool clearStartedAt = false,
  }) {
    return AbstinenceState(
      started: started ?? this.started,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      initialHours: initialHours ?? this.initialHours,
      initialMinutes: initialMinutes ?? this.initialMinutes,
      breaks: breaks ?? this.breaks,
    );
  }

  Map<String, dynamic> toJson() => {
    'started': started,
    'startedAt': startedAt?.toIso8601String(),
    'initialHours': initialHours,
    'initialMinutes': initialMinutes,
    'breaks': breaks.map((e) => e.toJson()).toList(),
  };

  factory AbstinenceState.fromJson(Map<String, dynamic> json) {
    return AbstinenceState(
      started: json['started'] as bool? ?? false,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      initialHours: json['initialHours'] as int? ?? 0,
      initialMinutes: json['initialMinutes'] as int? ?? 0,
      breaks: (json['breaks'] as List? ?? [])
          .map(
            (e) =>
                ContactBreakEvent.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
