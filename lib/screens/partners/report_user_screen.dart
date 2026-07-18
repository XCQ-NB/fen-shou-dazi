import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class ReportUserScreen extends StatefulWidget {
  final UserAccount user;

  const ReportUserScreen({super.key, required this.user});

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  static const _reasons = <(String, String, String)>[
    ('sexual', '色情低俗或黄色信息', '频繁发送露骨、色情或令人不适的内容'),
    ('fraud', '欺诈或诱导转账', '冒充投资、借款、刷单或诱导提供验证码'),
    ('harassment', '骚扰、辱骂或威胁', '持续纠缠、人身攻击、恐吓或恶意骚扰'),
    ('impersonation', '冒充他人或虚假身份', '盗用头像、伪造资料或冒充其他用户'),
    ('spam', '广告、引流或垃圾消息', '推广商品、拉群、导流至其他平台'),
    ('illegal', '传播违法违规内容', '涉及赌博、毒品、暴力或其他违法信息'),
    ('minor_safety', '未成年人相关不当内容', '诱导、骚扰或伤害未成年人的内容'),
    ('privacy', '泄露他人隐私', '公开手机号、住址、照片等个人信息'),
    ('other', '其他问题', '请在下方补充具体情况'),
  ];

  final _detail = TextEditingController();
  String? _selected;
  bool _submitting = false;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择举报原因')),
      );
      return;
    }
    if (_selected == 'other' && _detail.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请补充具体情况')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<AppState>().reportUser(
            userId: widget.user.id,
            reasonCode: _selected!,
            detail: _detail.text,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('举报已提交'),
          content: const Text('我们会尽快审核。若确认违规，将对账号采取禁言或封禁等措施。'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        title: Text('举报 ${widget.user.username}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              '请选择最符合的原因',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '举报内容仅用于平台安全审核，请勿恶意举报。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _reasons.length; i++) ...[
                    ListTile(
                      leading: Icon(
                        _selected == _reasons[i].$1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _selected == _reasons[i].$1
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        _reasons[i].$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(_reasons[i].$3),
                      onTap: () =>
                          setState(() => _selected = _reasons[i].$1),
                    ),
                    if (i != _reasons.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detail,
              minLines: 4,
              maxLines: 7,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: '补充说明（可选）',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: Text(_submitting ? '提交中…' : '提交举报'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
