import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../legal/legal_screen.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _agreed = true;
  bool _sending = false;
  bool _submitting = false;
  int _cooldown = 0;
  Timer? _timer;
  final _agreementTap = TapGestureRecognizer();
  final _privacyTap = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _agreementTap.onTap = () => _openLegal(LegalDoc.agreement);
    _privacyTap.onTap = () => _openLegal(LegalDoc.privacy);
  }

  void _openLegal(LegalDoc doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalScreen(doc: doc)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _agreementTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _startCooldown(int sec) {
    _timer?.cancel();
    setState(() => _cooldown = sec);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else if (mounted) {
        setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先同意用户协议和隐私政策')),
      );
      return;
    }
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的 11 位手机号')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<AppState>().sendSmsCode(phone);
      if (!mounted) return;
      _startCooldown(60);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已发送')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先同意用户协议和隐私政策')),
      );
      return;
    }
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的 11 位手机号')),
      );
      return;
    }
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入验证码')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final needProfile = await context.read<AppState>().loginWithSms(
            phone: phone,
            code: code,
          );
      if (!mounted) return;
      if (needProfile) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 72),
              const Text(
                '手机号登录/注册',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '未注册手机号验证后将自动创建账号',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  hintText: '手机号',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        hintText: '验证码',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: (_sending || _cooldown > 0) ? null : _sendCode,
                      child: Text(
                        _cooldown > 0
                            ? '${_cooldown}s'
                            : (_sending ? '发送中' : '获取验证码'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: _submitting ? '登录中…' : '登录/注册',
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Icon(
                      _agreed ? Icons.check_circle : Icons.circle_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: '您已经阅读并同意 '),
                          TextSpan(
                            text: '用户协议',
                            style: const TextStyle(color: AppColors.primary),
                            recognizer: _agreementTap,
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: '隐私政策',
                            style: const TextStyle(color: AppColors.primary),
                            recognizer: _privacyTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing;

  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _storyCtrl;
  Gender _gender = Gender.male;
  String? _avatarPath;
  bool _inited = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _ageCtrl = TextEditingController(text: '24');
    _heightCtrl = TextEditingController(text: '170');
    _bioCtrl = TextEditingController();
    _storyCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final account = context.read<AppState>().account;
    _nameCtrl.text = account?.username ?? '';
    _ageCtrl.text = '${account?.age == 0 ? 24 : (account?.age ?? 24)}';
    _heightCtrl.text = '${account?.height == 0 ? 170 : (account?.height ?? 170)}';
    _bioCtrl.text = account?.bio ?? '';
    _storyCtrl.text = account?.story ?? '';
    _avatarPath = account?.avatarUrl;
    _gender = account?.gender ?? Gender.male;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _bioCtrl.dispose();
    _storyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
      // 尽量拿到 JPEG，避免 iOS HEIC 上传 MIME 异常
      requestFullMetadata: false,
    );
    if (image != null && mounted) {
      final directory = await getApplicationDocumentsDirectory();
      var extension = image.path.contains('.')
          ? image.path.substring(image.path.lastIndexOf('.')).toLowerCase()
          : '.jpg';
      if (extension == '.heic' || extension == '.heif') {
        extension = '.jpg';
      }
      final fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}$extension';
      await File(image.path).copy('${directory.path}/$fileName');
      if (mounted) {
        setState(() => _avatarPath = fileName);
      }
    }
  }

  Future<void> _done() async {
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 18;
    final height = int.tryParse(_heightCtrl.text.trim()) ?? 0;
    if (_avatarPath == null || _avatarPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先设置头像')),
      );
      return;
    }
    if (age < 18 || age > 100 || height < 120 || height > 230) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写有效的年龄和身高')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppState>().completeProfile(
            username:
                _nameCtrl.text.trim().isEmpty ? '用户' : _nameCtrl.text.trim(),
            age: age,
            height: height,
            gender: _gender,
            avatarUrl: _avatarPath!,
            bio: _bioCtrl.text,
            story: _storyCtrl.text,
            storyImageUrls: const [],
          );
      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '编辑资料' : '完善个人资料'),
        leading: widget.isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFCCCCCC),
                    backgroundImage: _avatarImage(),
                    child: _avatarPath == null
                        ? const Icon(
                            Icons.person,
                            size: 42,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: '昵称'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '年龄'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '身高 cm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _genderBtn('男', Gender.male, AppColors.maleName)),
                const SizedBox(width: 12),
                Expanded(
                  child: _genderBtn('女', Gender.female, AppColors.femaleName),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioCtrl,
              maxLength: 50,
              decoration: const InputDecoration(hintText: '个性签名（可选）'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _storyCtrl,
              maxLines: 5,
              maxLength: 50000,
              decoration: const InputDecoration(hintText: '我的故事（可选）'),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '头像和资料以后都可以在“我的”Tab 中设置或修改。',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _saving ? '保存中…' : '完成',
              onPressed: _saving ? null : _done,
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _avatarImage() {
    return context.read<AppState>().imageProviderFor(_avatarPath);
  }

  Widget _genderBtn(String label, Gender value, Color active) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? active : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
