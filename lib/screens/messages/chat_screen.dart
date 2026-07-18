import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final ChatSession session;

  const ChatScreen({super.key, required this.session});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  int _lastCount = 0;
  bool _nearBottom = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<AppState>();
      if (!widget.session.isAi) {
        await state.loadMessages(widget.session.id);
      }
      await state.markSessionRead(widget.session.id);
      _lastCount = state.messagesFor(widget.session.id).length;
      _jumpToBottom();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    _nearBottom = pos.maxScrollExtent - pos.pixels < 80;
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
    _nearBottom = true;
  }

  void _animateToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    _nearBottom = true;
  }

  void _scheduleScrollIfNeeded(int count) {
    if (count == _lastCount) return;
    final grew = count > _lastCount;
    final shouldScroll = grew && _nearBottom;
    _lastCount = count;
    if (!shouldScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animateToBottom();
    });
  }

  Future<void> _refresh() async {
    if (widget.session.isAi) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return;
    }
    final state = context.read<AppState>();
    await state.loadMessages(widget.session.id);
    if (!mounted) return;
    await state.markSessionRead(widget.session.id);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    HapticFeedback.lightImpact();
    _nearBottom = true;
    final state = context.read<AppState>();
    try {
      if (widget.session.isAi) {
        await state.sendAiMessage(text);
      } else {
        await state.sendDirectMessage(widget.session.id, text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.messagesFor(widget.session.id);
    final sendingAi = state.aiSending && widget.session.isAi;
    final muted = !widget.session.isAi &&
        state.account?.accountStatus == 'muted' &&
        (state.account?.mutedUntil?.isAfter(DateTime.now()) ?? false);
    final itemCount = messages.length + (sendingAi ? 1 : 0);
    _scheduleScrollIfNeeded(itemCount);

    final titleColor = widget.session.isAi
        ? AppColors.primary
        : (widget.session.peerGender == Gender.male
            ? AppColors.maleName
            : AppColors.femaleName);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PeerAvatar(session: widget.session, radius: 16),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.session.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.session.isAi)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFD9EFE4)),
                ),
              ),
              child: const Text(
                'AI 由服务器安全代理，密钥不会写入 App',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: _refresh,
              child: messages.isEmpty && !sendingAi
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                        const _EmptyChatHint(),
                      ],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (index >= messages.length) {
                          return const _TypingBubble();
                        }
                        final m = messages[index];
                        final mine = m.role == 'user';
                        final prev = index > 0 ? messages[index - 1] : null;
                        final showTime = prev == null ||
                            m.createdAt.difference(prev.createdAt).inMinutes >=
                                8;
                        return KeyedSubtree(
                          key: ValueKey(m.clientMessageId ?? m.id),
                          child: Column(
                            children: [
                              if (showTime) _TimeChip(time: m.createdAt),
                              _MessageRow(
                                message: m,
                                mine: mine,
                                session: widget.session,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (state.aiError != null && widget.session.isAi)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                state.aiError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
          if (muted)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF0E8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '账号已被禁言至 ${DateFormat('M月d日 HH:mm').format(state.account!.mutedUntil!.toLocal())}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _Composer(
            controller: _ctrl,
            focusNode: _focus,
            enabled: !muted && !(state.aiSending && widget.session.isAi),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5F3),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: enabled ? (_) => onSend() : null,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '说点什么…',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: enabled ? 1 : 0.45,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: enabled ? onSend : null,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final ChatSession session;

  const _MessageRow({
    required this.message,
    required this.mine,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = _Bubble(mine: mine, text: message.content);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            _PeerAvatar(session: session, radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
          if (mine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool mine;
  final String text;

  const _Bubble({required this.mine, required this.text});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(mine ? 18 : 5),
      bottomRight: Radius.circular(mine ? 5 : 18),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        gradient: mine
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3AD68F), AppColors.primaryDark],
              )
            : null,
        color: mine ? null : Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: mine ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: mine ? Colors.white : AppColors.textPrimary,
          height: 1.45,
          fontSize: 15.5,
        ),
      ),
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  final ChatSession session;
  final double radius;

  const _PeerAvatar({required this.session, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage:
          session.avatarUrl.isEmpty ? null : NetworkImage(session.avatarUrl),
      child: session.avatarUrl.isEmpty
          ? Icon(
              session.isAi ? Icons.auto_awesome : Icons.person,
              size: radius,
              color: AppColors.primary,
            )
          : null,
    );
  }
}

class _TimeChip extends StatelessWidget {
  final DateTime time;

  const _TimeChip({required this.time});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sameDay =
        now.year == time.year && now.month == time.month && now.day == time.day;
    final label = sameDay
        ? DateFormat('HH:mm').format(time)
        : DateFormat('M月d日 HH:mm').format(time);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE4EAE6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10, left: 40),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _Bubble(mine: false, text: '正在输入…'),
      ),
    );
  }
}

class _EmptyChatHint extends StatelessWidget {
  const _EmptyChatHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCDEADB)),
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 14),
        const Text(
          '打个招呼吧',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '下拉可刷新消息',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
