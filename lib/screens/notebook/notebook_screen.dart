import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class NotebookScreen extends StatelessWidget {
  const NotebookScreen({super.key});

  IconData _moodIcon(String mood) {
    switch (mood) {
      case 'cloud':
        return Icons.cloud_outlined;
      case 'rain':
        return Icons.water_drop_outlined;
      case 'moon':
        return Icons.nightlight_round;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  Future<void> _writeToday(BuildContext context) async {
    final state = context.read<AppState>();
    if (!state.canCreateNote) {
      final go = await MembershipDialog.show(
        context,
        message: '免费版最多发布 2 条内容，开通会员后可继续写下今天',
      );
      if (go == true && context.mounted) {
        await state.setVip(true);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已开启会员演示状态')));
        }
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const NotebookEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notes = state.notes;

    return Scaffold(
      backgroundColor: AppColors.paperBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '想对Ta说的话',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Material(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _writeToday(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          '写下今天',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notes.isEmpty
                  ? const Center(
                      child: Text(
                        '还没有记录，点右上角写下今天',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: notes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == notes.length) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text(
                                '— 记录于 · 分手搭子 —',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }
                        final note = notes[index];
                        final abstinenceDay = state.dayIndexFor(note.date);
                        final weather = state.weatherMoodForDate(note.date);
                        final dateText = DateFormat('M月d日').format(note.date);
                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.only(right: 22),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text('删除这条记录？'),
                                    content: const Text('删除后不可恢复。'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('取消'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.danger,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const Text('删除'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) {
                            context.read<AppState>().deleteNote(note.id);
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) =>
                                      NotebookEditorScreen(noteId: note.id),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                                  Row(
                                    children: [
                                      Text(
                                        abstinenceDay == null
                                            ? dateText
                                            : '第$abstinenceDay天 · $dateText',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (weather != null)
                                        Icon(
                                          _moodIcon(weather),
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    note.content.isEmpty
                                        ? '（空内容）'
                                        : note.content,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: note.content.isEmpty
                                          ? AppColors.textSecondary
                                          : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotebookEditorScreen extends StatefulWidget {
  final String? noteId;

  const NotebookEditorScreen({super.key, this.noteId});

  @override
  State<NotebookEditorScreen> createState() => _NotebookEditorScreenState();
}

class _NotebookEditorScreenState extends State<NotebookEditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  String? _noteId;
  bool _saving = false;
  String _status = '';
  bool _creating = false;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noteId = widget.noteId;
    final existing = _noteId == null
        ? null
        : context.read<AppState>().noteById(_noteId!);
    _ctrl = TextEditingController(text: existing?.content ?? '');
    _ctrl.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = context.read<AppState>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _ctrl.removeListener(_onChanged);
    final state = _appState;
    final id = _noteId;
    final text = _ctrl.text;
    if (state != null && (id != null || text.trim().isNotEmpty)) {
      // ignore: discarded_futures
      state.upsertNoteContent(id: id, content: text);
    }
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flushSave();
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _flushSave);
    setState(() => _status = '编辑中…');
  }

  Future<void> _flushSave() async {
    _debounce?.cancel();
    if (_creating) return;
    final text = _ctrl.text;
    final state = context.read<AppState>();

    if (_noteId == null) {
      if (text.trim().isEmpty) {
        if (mounted) setState(() => _status = '');
        return;
      }
      if (!state.canCreateNote) {
        if (mounted) {
          setState(() => _status = '免费额度已用完');
          await MembershipDialog.show(context);
        }
        return;
      }
      _creating = true;
      setState(() {
        _saving = true;
        _status = '保存中…';
      });
      final created = await state.upsertNoteContent(content: text);
      _creating = false;
      if (!mounted) return;
      _noteId = created?.id;
      setState(() {
        _saving = false;
        _status = created == null ? '保存失败' : '已保存';
      });
      return;
    }

    setState(() {
      _saving = true;
      _status = '保存中…';
    });
    await state.upsertNoteContent(id: _noteId, content: text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _status = '已保存';
    });
  }

  Future<void> _copyAll() async {
    await _flushSave();
    if (!mounted) return;
    final text = _ctrl.text;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无内容可复制')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制全文')));
  }

  Future<void> _onBack() async {
    await _flushSave();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final note = _noteId == null ? null : state.noteById(_noteId!);
    final date = note?.date ?? DateTime.now();
    final day = state.dayIndexFor(date);
    final dateText = DateFormat('M月d日').format(date);
    final title = day == null ? dateText : '第$day天 · $dateText';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _onBack();
          return;
        }
        await _flushSave();
      },
      child: Scaffold(
        backgroundColor: AppColors.paperBg,
        appBar: AppBar(
          backgroundColor: AppColors.paperBg,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 30),
            onPressed: _onBack,
          ),
          title: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_status.isNotEmpty)
                Text(
                  _saving ? '保存中…' : _status,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _copyAll,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text('复制全文', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: TextField(
                    controller: _ctrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: '写下今天想对Ta说的话...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    style: const TextStyle(fontSize: 17, height: 1.7),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    '— 记录于 · 分手搭子 —',
                    style: TextStyle(color: AppColors.textSecondary),
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
