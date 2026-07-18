import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AbstinenceScreen extends StatefulWidget {
  const AbstinenceScreen({super.key});

  @override
  State<AbstinenceScreen> createState() => _AbstinenceScreenState();
}

class _AbstinenceScreenState extends State<AbstinenceScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _confirmStart() async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmStartSheet(),
    );
    if (result == null || !mounted) return;
    await context.read<AppState>().startAbstinence(
      hours: result['hours']!,
      minutes: result['minutes']!,
    );
  }

  Future<void> _openCalendar() async {
    final state = context.read<AppState>();
    if (!state.isVip) {
      final go = await MembershipDialog.show(context, message: '开通会员后可查看断联日历');
      if (go == true && mounted) {
        await state.setVip(true);
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AbstinenceCalendarScreen()));
  }

  Future<void> _confirmContacted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认联系 Ta 了吗？'),
        content: const Text('确认后，今天仍计入本轮断联天数；从明天起留白，本轮计时暂停。'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认联系了'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('我点错了'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AppState>().markContacted();
  }

  @override
  Widget build(BuildContext context) {
    final abs = context.watch<AppState>().abstinence;
    if (abs.started) {
      return _RunningView(
        abstinence: abs,
        onContacted: _confirmContacted,
        onCalendar: _openCalendar,
      );
    }
    return _IdleView(
      onStart: _confirmStart,
      onCalendar: _openCalendar,
    );
  }
}

class _IdleView extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onCalendar;

  const _IdleView({
    required this.onStart,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE0C2),
                  Color(0xFFD7E8F5),
                  Color(0xFFB8C9D9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '00:00',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '从这里开始，等一个晴天',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 28),
                            PrimaryButton(
                              label: '从此刻开始',
                              color: AppColors.orange,
                              onPressed: onStart,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onCalendar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '断联日历 >',
                      style: TextStyle(color: AppColors.ink),
                    ),
                  ),
                ),
                const Spacer(),
                const Center(
                  child: Text(
                    '— 记录于 · 分手搭子 —',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmStartSheet extends StatefulWidget {
  const _ConfirmStartSheet();

  @override
  State<_ConfirmStartSheet> createState() => _ConfirmStartSheetState();
}

class _ConfirmStartSheetState extends State<_ConfirmStartSheet> {
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;

  String get _summary {
    if (_days == 0 && _hours == 0 && _minutes == 0) {
      return '从现在开始，计时从 0 起';
    }
    final parts = <String>[];
    if (_days > 0) parts.add('$_days 天');
    if (_hours > 0) parts.add('$_hours 小时');
    if (_minutes > 0) parts.add('$_minutes 分钟');
    return '已断联 ${parts.join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '你们已经断联了多久？',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '滑动选择，精确到分钟；也可以直接从 0 开始',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text(
              _summary,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 168,
              child: Row(
                children: [
                  Expanded(
                    child: _WheelColumn(
                      label: '天',
                      itemCount: 91,
                      selected: _days,
                      onChanged: (v) => setState(() => _days = v),
                    ),
                  ),
                  Expanded(
                    child: _WheelColumn(
                      label: '小时',
                      itemCount: 24,
                      selected: _hours,
                      onChanged: (v) => setState(() => _hours = v),
                    ),
                  ),
                  Expanded(
                    child: _WheelColumn(
                      label: '分',
                      itemCount: 60,
                      selected: _minutes,
                      onChanged: (v) => setState(() => _minutes = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: '从此刻开始',
              color: AppColors.orange,
              onPressed: () => Navigator.pop(context, {
                'hours': _days * 24 + _hours,
                'minutes': _minutes,
              }),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '— 我再想想 >',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelColumn extends StatefulWidget {
  final String label;
  final int itemCount;
  final int selected;
  final ValueChanged<int> onChanged;

  const _WheelColumn({
    required this.label,
    required this.itemCount,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<_WheelColumn> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.selected);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              ListWheelScrollView.useDelegate(
                itemExtent: 40,
                diameterRatio: 1.3,
                perspective: 0.003,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: widget.onChanged,
                controller: _controller,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.itemCount,
                  builder: (context, index) {
                    final active = index == widget.selected;
                    return Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: active ? 22 : 16,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color: active
                              ? AppColors.orange
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherTheme {
  final String title;
  final String description;
  final List<Color> sky;
  final Color glow;
  final Color timerValue;
  final Color timerUnit;
  final Color message;
  final Color footer;
  final Color glass;
  final Color actionMuted;
  final Color actionAccent;
  final bool rainy;
  final bool sunny;

  const _WeatherTheme({
    required this.title,
    required this.description,
    required this.sky,
    required this.glow,
    required this.timerValue,
    required this.timerUnit,
    required this.message,
    required this.footer,
    required this.glass,
    required this.actionMuted,
    required this.actionAccent,
    required this.rainy,
    required this.sunny,
  });

  factory _WeatherTheme.fromDay(int dayIndex) {
    if (dayIndex <= 2) {
      return _WeatherTheme(
        title: '骤雨时分',
        description: '雨正下得急，但你已经走到了第$dayIndex天，先照顾好自己',
        sky: [Color(0xFF1B2838), Color(0xFF2A3F55), Color(0xFF0E1620)],
        glow: Color(0xFF5B7C99),
        timerValue: Color(0xFFF4F7FA),
        timerUnit: Color(0xFFB7C5D3),
        message: Color(0xFFFFB08A),
        footer: Color(0x99FFFFFF),
        glass: Color(0x28FFFFFF),
        actionMuted: Color(0xFFD5DEE8),
        actionAccent: Color(0xFF7DDBB0),
        rainy: true,
        sunny: false,
      );
    }
    if (dayIndex <= 4) {
      return _WeatherTheme(
        title: '细雨未停',
        description: '雨声正在变轻，你已经坚持了$dayIndex天，比昨天更从容',
        sky: [Color(0xFF34495E), Color(0xFF607D8B), Color(0xFF263746)],
        glow: Color(0xFFA9C4D6),
        timerValue: Color(0xFFF5F8FA),
        timerUnit: Color(0xFFC5D1DA),
        message: Color(0xFFFFC09F),
        footer: Color(0xB3FFFFFF),
        glass: Color(0x30FFFFFF),
        actionMuted: Color(0xFFE0E7ED),
        actionAccent: Color(0xFF86E0B9),
        rainy: true,
        sunny: false,
      );
    }
    if (dayIndex <= 7) {
      return _WeatherTheme(
        title: '阴云渐薄',
        description: '云层慢慢散开，坚持到第$dayIndex天的你，正在等来新的光',
        sky: [Color(0xFF7E94A8), Color(0xFFB7C7D4), Color(0xFFE8EEF2)],
        glow: Color(0xFFFFFFFF),
        timerValue: Color(0xFF243447),
        timerUnit: Color(0xFF6A7C8C),
        message: Color(0xFFE56B3A),
        footer: Color(0xFF6A7C8C),
        glass: Color(0x66FFFFFF),
        actionMuted: Color(0xFF5A6B7A),
        actionAccent: Color(0xFF1DBF85),
        rainy: false,
        sunny: false,
      );
    }
    if (dayIndex <= 14) {
      return _WeatherTheme(
        title: '天光初现',
        description: '第$dayIndex天，云缝里已经有了光，生活正在一点点回来',
        sky: [Color(0xFFFFB86B), Color(0xFFFFD9A8), Color(0xFFB8E4F5)],
        glow: Color(0xFFFFF3D6),
        timerValue: Color(0xFF2A2A2A),
        timerUnit: Color(0xFF7A6A5A),
        message: Color(0xFFD35400),
        footer: Color(0xFF7A6A5A),
        glass: Color(0x73FFFFFF),
        actionMuted: Color(0xFF6B5B4B),
        actionAccent: Color(0xFF1DBF85),
        rainy: false,
        sunny: true,
      );
    }
    if (dayIndex <= 30) {
      return _WeatherTheme(
        title: '晴空相伴',
        description: '晴天已经来到第$dayIndex天，你也找回了属于自己的节奏',
        sky: [Color(0xFF73C8F0), Color(0xFFBDE7F7), Color(0xFFFFE8B8)],
        glow: Color(0xFFFFF1A8),
        timerValue: Color(0xFF234052),
        timerUnit: Color(0xFF587485),
        message: Color(0xFFCE6838),
        footer: Color(0xFF587485),
        glass: Color(0x66FFFFFF),
        actionMuted: Color(0xFF526C7A),
        actionAccent: Color(0xFF159A6B),
        rainy: false,
        sunny: true,
      );
    }
    if (dayIndex <= 60) {
      return _WeatherTheme(
        title: '清风长路',
        description: '第$dayIndex天，风很轻，路很长，你已不再停留在那场雨里',
        sky: [Color(0xFF8FD5C2), Color(0xFFD6EFE3), Color(0xFFFCE6BD)],
        glow: Color(0xFFFFF7D6),
        timerValue: Color(0xFF24483F),
        timerUnit: Color(0xFF658177),
        message: Color(0xFFB76A3D),
        footer: Color(0xFF658177),
        glass: Color(0x70FFFFFF),
        actionMuted: Color(0xFF587269),
        actionAccent: Color(0xFF11895E),
        rainy: false,
        sunny: true,
      );
    }
    return _WeatherTheme(
      title: '星河新生',
      description: '走到第$dayIndex天，你已穿过风雨，开始书写自己的新故事',
      sky: [Color(0xFF182848), Color(0xFF4B6CB7), Color(0xFF768DC7)],
      glow: Color(0xFFFFF3D6),
      timerValue: Color(0xFFF7F8FF),
      timerUnit: Color(0xFFD3DCF3),
      message: Color(0xFFFFD3A5),
      footer: Color(0xB3FFFFFF),
      glass: Color(0x2EFFFFFF),
      actionMuted: Color(0xFFE0E7FA),
      actionAccent: Color(0xFF8BE0B9),
      rainy: false,
      sunny: false,
    );
  }
}

class _RunningView extends StatefulWidget {
  final AbstinenceState abstinence;
  final VoidCallback onContacted;
  final VoidCallback onCalendar;

  const _RunningView({
    required this.abstinence,
    required this.onContacted,
    required this.onCalendar,
  });

  @override
  State<_RunningView> createState() => _RunningViewState();
}

class _RunningViewState extends State<_RunningView>
    with TickerProviderStateMixin {
  late final AnimationController _rainCtrl;
  late final AnimationController _breatheCtrl;
  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _rainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _rainCtrl.dispose();
    _breatheCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.abstinence.elapsed;
    final dayIndex = widget.abstinence.dayCount;
    final days = elapsed.inDays;
    final hours = elapsed.inHours % 24;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;
    final theme = _WeatherTheme.fromDay(dayIndex);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.sky,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_breatheCtrl.value);
              return IgnorePointer(
                child: Stack(
                  children: [
                    Positioned(
                      top: -80 + 20 * t,
                      left: -40,
                      child: _GlowOrb(
                        size: 220,
                        color: theme.glow.withValues(alpha: 0.22 + 0.08 * t),
                      ),
                    ),
                    Positioned(
                      bottom: 120 - 16 * t,
                      right: -60,
                      child: _GlowOrb(
                        size: 260,
                        color: theme.glow.withValues(alpha: 0.16 + 0.06 * t),
                      ),
                    ),
                    if (theme.sunny)
                      Positioned(
                        top: 72 + 8 * t,
                        right: 36,
                        child: _GlowOrb(
                          size: 120,
                          color: const Color(0xFFFFE082).withValues(
                            alpha: 0.45 + 0.15 * t,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (theme.rainy)
            AnimatedBuilder(
              animation: _rainCtrl,
              builder: (context, _) => CustomPaint(
                painter: _RainPainter(progress: _rainCtrl.value),
                size: Size.infinite,
              ),
            ),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _enterCtrl,
                curve: Curves.easeOutCubic,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _enterCtrl,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 36),
                      Text(
                        theme.title,
                        style: TextStyle(
                          color: theme.timerUnit.withValues(alpha: 0.9),
                          fontSize: 13,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(flex: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          _TimeUnit(
                            value: '$days',
                            unit: '天',
                            large: true,
                            valueColor: theme.timerValue,
                            unitColor: theme.timerUnit,
                          ),
                          const SizedBox(width: 22),
                          _TimeUnit(
                            value: hours.toString().padLeft(2, '0'),
                            unit: '时',
                            large: true,
                            valueColor: theme.timerValue,
                            unitColor: theme.timerUnit,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          _TimeUnit(
                            value: minutes.toString().padLeft(2, '0'),
                            unit: '分',
                            valueColor: theme.timerValue.withValues(alpha: 0.78),
                            unitColor: theme.timerUnit,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '·',
                              style: TextStyle(
                                color: theme.timerUnit.withValues(alpha: 0.5),
                                fontSize: 18,
                              ),
                            ),
                          ),
                          _TimeUnit(
                            value: seconds.toString().padLeft(2, '0'),
                            unit: '秒',
                            valueColor: theme.timerValue.withValues(alpha: 0.78),
                            unitColor: theme.timerUnit,
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Text(
                          theme.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.message,
                            height: 1.55,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(flex: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            decoration: BoxDecoration(
                              color: theme.glass,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: widget.onContacted,
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.actionMuted,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      '我联系Ta了',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 22,
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: widget.onCalendar,
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.actionAccent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      '断联日历 ›',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        '— 记录于 · 分手搭子 —',
                        style: TextStyle(
                          color: theme.footer,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final String value;
  final String unit;
  final bool large;
  final Color valueColor;
  final Color unitColor;

  const _TimeUnit({
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.unitColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: large ? 56 : 24,
              fontWeight: FontWeight.w300,
              letterSpacing: large ? 1.5 : 0.5,
              color: valueColor,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: unit,
            style: TextStyle(
              fontSize: large ? 18 : 12,
              fontWeight: FontWeight.w500,
              color: unitColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final double progress;

  _RainPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    for (var i = 0; i < 56; i++) {
      final x = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final len = 14.0 + rnd.nextDouble() * 18;
      final drift = rnd.nextDouble() * 10;
      final speed = 0.55 + rnd.nextDouble() * 0.9;
      final y = (baseY + progress * size.height * speed) % (size.height + len);
      final alpha = 0.12 + rnd.nextDouble() * 0.22;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, y - len),
        Offset(x + drift, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class AbstinenceCalendarScreen extends StatefulWidget {
  const AbstinenceCalendarScreen({super.key});

  @override
  State<AbstinenceCalendarScreen> createState() =>
      _AbstinenceCalendarScreenState();
}

class _AbstinenceCalendarScreenState extends State<AbstinenceCalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isFutureDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return d.isAfter(_today);
  }

  String _lunarLabel(DateTime day) {
    final lunar = Lunar.fromDate(day);
    final festivals = lunar.getFestivals();
    if (festivals.isNotEmpty) return festivals.first;
    final other = lunar.getOtherFestivals();
    if (other.isNotEmpty) return other.first;
    final jieQi = lunar.getJieQi();
    if (jieQi.isNotEmpty) return jieQi;
    final dayText = lunar.getDayInChinese();
    if (dayText == '初一') {
      return '${lunar.getMonthInChinese()}月';
    }
    return dayText;
  }

  void _showDayDialog(DateTime day) {
    // 未来日期不可点击，无弹窗
    if (_isFutureDay(day)) return;

    final state = context.read<AppState>();
    if (state.isContactedDay(day)) {
      final event = state.breakForDate(day)!;
      showDialog(
        context: context,
        builder: (_) => _ContactedDayDialog(event: event),
      );
      return;
    }
    if (!state.isNoContactDay(day)) return;
    final dayIndex = state.dayIndexFor(day);
    if (dayIndex == null) return;
    if (dayIndex <= 1) {
      final segmentStart = state.segmentStartedAtFor(day) ?? day;
      showDialog(
        context: context,
        builder: (_) => _StartDayDialog(
          startedAt: segmentStart,
          days: dayIndex,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => _NormalDayDialog(dayIndex: dayIndex),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final firstWeekday =
        DateTime(_month.year, _month.month, 1).weekday % 7; // Sunday=0
    final cells = <DateTime?>[
      ...List.filled(firstWeekday, null),
      ...List.generate(
        daysInMonth,
        (i) => DateTime(_month.year, _month.month, i + 1),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Text('${_month.year}年 ${_month.month}月'),
            IconButton(
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['日', '一', '二', '三', '四', '五', '六']
                  .map(
                    (e) => Expanded(
                      child: Center(
                        child: Text(
                          e,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final day = cells[index];
                if (day == null) return const SizedBox.shrink();
                final marked = state.isNoContactDay(day);
                final future = _isFutureDay(day);
                final isToday = DateUtils.isSameDay(day, _today);
                final lunar = _lunarLabel(day);
                final dayColor = future
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : marked
                    ? Colors.white
                    : AppColors.ink;
                final lunarColor = future
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : marked
                    ? Colors.white70
                    : AppColors.textSecondary;
                return GestureDetector(
                  onTap: future ? null : () => _showDayDialog(day),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: marked
                              ? const Color(0xFF333333)
                              : isToday
                              ? AppColors.orange.withValues(alpha: 0.12)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !marked
                              ? Border.all(
                                  color: AppColors.orange.withValues(
                                    alpha: 0.55,
                                  ),
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: dayColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lunar,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: lunarColor,
                                fontSize: 9,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: marked && !future
                              ? AppColors.orange
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '点击黑色日期可查看详情',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Center(
              child: Text(
                '— 记录于 · 分手搭子 —',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartDayDialog extends StatelessWidget {
  final DateTime startedAt;
  final int days;
  const _StartDayDialog({required this.startedAt, required this.days});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '开始断联',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Text('这一轮断联从这一天开始。'),
            const SizedBox(height: 6),
            Text('起始时间：${DateFormat('M月d日 HH:mm').format(startedAt)}'),
            const SizedBox(height: 6),
            Text('你已经坚持了 $days 天。'),
            const SizedBox(height: 12),
            const Divider(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '好的',
                style: TextStyle(color: AppColors.orange, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NormalDayDialog extends StatelessWidget {
  final int dayIndex;
  const _NormalDayDialog({required this.dayIndex});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '第 $dayIndex 天',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Text('这一天，你没有联系Ta。'),
            const SizedBox(height: 6),
            const Text('你把它完整地交给了自己。'),
            const SizedBox(height: 10),
            const Text(
              '属于你自己的 24 小时。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '好的',
                style: TextStyle(color: AppColors.orange, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactedDayDialog extends StatelessWidget {
  final ContactBreakEvent event;
  const _ContactedDayDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ),
            const Text(
              '这一天，你联系了Ta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('断联在 ${DateFormat('M月d日 HH:mm').format(event.at)} 中断。'),
            Text('在此之前，你坚持了 ${event.daysBefore} 天。'),
            const SizedBox(height: 12),
            CustomPaint(
              painter: _DashedLinePainter(),
              child: const SizedBox(width: double.infinity, height: 1),
            ),
            const SizedBox(height: 12),
            Text(
              event.restartedAt == null
                  ? '你还没有重新开始断联。'
                  : '${DateFormat('M月d日 HH:mm').format(event.restartedAt!)} 你重新开始了断联。',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: '好的，我知道了',
              color: AppColors.orange,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 1;
    const dash = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
