import '../models/models.dart';

class MockData {
  static final now = DateTime.now();

  static final feedPosts = [
    FeedPost(
      id: '1',
      authorName: '佳银',
      gender: Gender.female,
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      imageUrl: 'https://picsum.photos/seed/dazi1/600/800',
      content: '大连甘井子区 明天一起出去吃饭玩耍有么？男女都可',
      city: '大连',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
  ];

  static final onlineUsers = [
    UserAccount(
      id: 'u_yangyang',
      username: '羊羊',
      age: 24,
      height: 165,
      gender: Gender.female,
      city: '娄底市',
      avatarUrl: 'https://i.pravatar.cc/150?img=20',
      bio: '不闲聊 🌈 dd 同城优先',
      story:
          '去年秋天我们结束了三年的关系。刚开始很不习惯一个人吃饭，也总会下意识把遇到的事情发给他。后来我开始学着自己做饭、散步、整理房间，把周末重新安排得充实一点。现在情绪已经平稳很多，只是偶尔仍会想起以前。来到这里，是想认识一个愿意认真说话、尊重彼此边界的人，不急着开始什么，先从真诚的交流开始。',
      isOnline: true,
      lastActiveAt: now.subtract(const Duration(minutes: 3)),
      chatActivityScore: 96,
    ),
    UserAccount(
      id: 'u_jiguang',
      username: '极光',
      age: 26,
      height: 178,
      gender: Gender.male,
      city: '上海市',
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      bio: '打游戏找搭子，也想聊聊近况',
      story:
          '分开以后，我把大部分注意力放回了工作和跑步。以前总觉得关系需要不断证明，后来才明白，舒服的相处应该允许两个人保留自己的节奏。最近完成了第一次半程马拉松，也重新捡起了搁置很久的摄影。希望认识一个情绪稳定、不相互消耗的人，可以分享日常，也可以安静地各自忙碌。',
      isOnline: true,
      lastActiveAt: now.subtract(const Duration(minutes: 8)),
      chatActivityScore: 88,
    ),
    UserAccount(
      id: 'u_wanfeng',
      username: '晚风',
      age: 22,
      height: 162,
      gender: Gender.female,
      city: '成都市',
      avatarUrl: 'https://i.pravatar.cc/150?img=32',
      bio: '想找个温柔的人聊聊',
      story:
          '有些话不适合再发给前任，但一直放在心里也很累。我开始用文字记录那些反复出现的情绪：遗憾、委屈，也有感谢。写下来以后才发现，告别不一定需要对方给出答案。希望在这里遇到愿意安静听我说完的人，也愿意倾听你的故事，我们不急着评价彼此。',
      isOnline: false,
      lastActiveAt: now.subtract(const Duration(hours: 5)),
      chatActivityScore: 42,
    ),
    UserAccount(
      id: 'u_lulu',
      username: '露露',
      age: 25,
      height: 168,
      gender: Gender.female,
      city: '娄底市',
      avatarUrl: 'https://i.pravatar.cc/150?img=25',
      bio: '周末想散步、喝咖啡',
      story:
          '断联进入第三周，情绪偶尔还是会突然起伏，但我已经不像最开始那样慌张了。我重新开始规律睡觉，周末去公园散步，偶尔和朋友喝咖啡。经历这段关系后，我比以前更清楚自己需要怎样的沟通和陪伴。想找一个温柔、坦诚、有边界感的人慢慢认识。',
      isOnline: true,
      lastActiveAt: now.subtract(const Duration(minutes: 15)),
      chatActivityScore: 75,
    ),
    UserAccount(
      id: 'u_akai',
      username: '阿凯',
      age: 27,
      height: 182,
      gender: Gender.male,
      city: '广州市',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      bio: '晚上健身有人一起吗',
      story:
          '上一段关系让我重新理解了边界感。喜欢一个人并不代表要放弃自己的生活，也不应该用沉默和猜测代替沟通。现在我把时间留给健身、工作和家人，生活正在慢慢恢复秩序。如果我们聊得来，可以从朋友开始慢慢认识，不催促，也不敷衍。',
      isOnline: false,
      lastActiveAt: now.subtract(const Duration(hours: 12)),
      chatActivityScore: 30,
    ),
    UserAccount(
      id: 'u_qiqi',
      username: '琪琪',
      age: 23,
      height: 160,
      gender: Gender.female,
      city: '上海市',
      avatarUrl: 'https://i.pravatar.cc/150?img=36',
      bio: '周末有空吗',
      story:
          '我喜欢电影、散步，也喜欢偶尔进行一场没有标准答案的深夜聊天。分开后曾经很害怕独处，后来发现一个人也能把生活过得有趣。现在不急着定义任何关系，更希望先成为能互相支持的搭子：开心时分享，低落时陪伴，同时尊重彼此需要安静的时刻。',
      isOnline: true,
      lastActiveAt: now.subtract(const Duration(minutes: 1)),
      chatActivityScore: 90,
    ),
    UserAccount(
      id: 'u_mumu',
      username: '木木',
      age: 28,
      height: 175,
      gender: Gender.male,
      city: '娄底市',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      bio: '同城找个能聊得来的人',
      story:
          '我学会了把难过写下来，而不是在情绪最重的时候反复联系对方。那些没有发出的消息，后来变成了一篇篇日记，也让我看见自己真正舍不得的是什么。现在依然在往前走，如果你也正在经历相似的阶段，我们可以交换故事，互相提醒按时吃饭、早点休息。',
      isOnline: true,
      lastActiveAt: now.subtract(const Duration(minutes: 20)),
      chatActivityScore: 68,
    ),
    UserAccount(
      id: 'u_xiaoyu',
      username: '小雨',
      age: 21,
      height: 158,
      gender: Gender.female,
      city: '深圳市',
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      bio: '听听别人的故事也可以',
      story:
          '有时候只是想被理解，并不是想被谁拯救。过去我总习惯隐藏自己的感受，直到关系结束才发现，很多误会都来自没有说出口的话。现在我在练习更坦诚地表达，也学习接受别人和我不同。如果你愿意认真倾听，我也会同样认真地听你的故事。',
      isOnline: false,
      lastActiveAt: now.subtract(const Duration(days: 1)),
      chatActivityScore: 18,
    ),
  ];

  static UserAccount? userById(String id) {
    for (final user in onlineUsers) {
      if (user.id == id) return user;
    }
    return null;
  }

  static List<ChatSession> defaultSessions({Gender? myGender}) {
    final opposite = myGender?.opposite;
    final peers = onlineUsers
        .where((u) => opposite == null || u.gender == opposite)
        .take(3)
        .toList();
    final sessions = <ChatSession>[
      ChatSession(
        id: 'ai',
        title: 'AI 情绪陪伴',
        subtitle: '我在这里陪你慢慢走出来',
        avatarUrl: 'https://i.pravatar.cc/150?img=68',
        updatedAt: now,
        isAi: true,
        unread: 1,
      ),
    ];
    for (var i = 0; i < peers.length; i++) {
      final user = peers[i];
      sessions.add(
        ChatSession(
          id: 'chat_${user.id}',
          title: user.username,
          subtitle: i == 0 ? '嘿你好' : (i == 1 ? '周末有空吗' : '今天天气不错'),
          avatarUrl: user.avatarUrl ?? '',
          updatedAt: now.subtract(Duration(hours: i + 1)),
          peerUserId: user.id,
          peerGender: user.gender,
          unread: i == 0 ? 1 : 0,
        ),
      );
    }
    return sessions;
  }

  static Map<String, List<ChatMessage>> defaultHistories(
    List<ChatSession> sessions,
  ) {
    final map = <String, List<ChatMessage>>{};
    for (final s in sessions) {
      if (s.isAi) {
        map[s.id] = [
          ChatMessage(
            id: 'ai_welcome',
            role: 'assistant',
            content: '你好，我是你的情绪陪伴助手。今天想聊聊什么？',
            createdAt: now.subtract(const Duration(minutes: 2)),
          ),
        ];
      } else {
        map[s.id] = [
          ChatMessage(
            id: '${s.id}_1',
            role: 'peer',
            content: s.subtitle,
            createdAt: s.updatedAt,
          ),
        ];
      }
    }
    return map;
  }
}
