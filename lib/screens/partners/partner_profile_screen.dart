import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../messages/chat_screen.dart';
import 'report_user_screen.dart';

class PartnerProfileScreen extends StatelessWidget {
  final UserAccount user;

  const PartnerProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final nameColor = user.gender == Gender.female
        ? AppColors.femaleName
        : AppColors.maleName;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        title: const Text('个人主页'),
        actions: [
          IconButton(
            tooltip: '举报',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportUserScreen(user: user),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Center(
            child: GestureDetector(
              onTap: user.avatarUrl == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AvatarPreviewScreen(user: user),
                      ),
                    ),
              child: Hero(
                tag: 'partner-avatar-${user.id}',
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: _avatarProvider(user.avatarUrl),
                  child: user.avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (user.avatarUrl != null) ...[
            const SizedBox(height: 6),
            const Center(
              child: Text(
                '点击查看头像',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.username,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: nameColor,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                user.gender == Gender.female ? Icons.female : Icons.male,
                color: nameColor,
              ),
              if (user.isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '在线',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${user.gender.label} · ${user.age}岁 · ${user.height}cm · ${user.city}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 18),
            _sectionCard(
              title: '个性签名',
              child: Text(user.bio, style: const TextStyle(height: 1.5)),
            ),
          ],
          const SizedBox(height: 14),
          _sectionCard(
            title: '我的故事',
            onTap: user.story.isEmpty && user.storyImageUrls.isEmpty
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoryDetailScreen(user: user),
                    ),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.story.isEmpty ? '这个人还没有填写故事。' : user.story,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.7,
                    color: user.story.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.ink,
                  ),
                ),
                if (user.story.isNotEmpty ||
                    user.storyImageUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '查看全文 ›',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () async {
                try {
                  final session =
                      await context.read<AppState>().ensureDirectSession(user);
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(session: session),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('发消息'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _avatarProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }
}

class AvatarPreviewScreen extends StatelessWidget {
  final UserAccount user;

  const AvatarPreviewScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final path = user.avatarUrl!;
    final image = path.startsWith('http://') || path.startsWith('https://')
        ? Image.network(path, fit: BoxFit.contain)
        : Image.file(File(path), fit: BoxFit.contain);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${user.username}的头像'),
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: 'partner-avatar-${user.id}',
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: SizedBox.expand(child: image),
            ),
          ),
        ),
      ),
    );
  }
}

class StoryDetailScreen extends StatelessWidget {
  final UserAccount user;

  const StoryDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        title: Text('${user.username}的故事'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              user.story.isEmpty ? '这个人还没有填写文字故事。' : user.story,
              style: TextStyle(
                height: 1.8,
                fontSize: 16,
                color: user.story.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.ink,
              ),
            ),
          ),
          if (user.storyImageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: user.storyImageUrls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final path = user.storyImageUrls[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child:
                      path.startsWith('http://') ||
                          path.startsWith('https://')
                      ? Image.network(path, fit: BoxFit.cover)
                      : Image.file(File(path), fit: BoxFit.cover),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
