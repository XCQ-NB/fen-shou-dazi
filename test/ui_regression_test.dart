import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runner2/models/models.dart';
import 'package:runner2/screens/auth/login_screen.dart';
import 'package:runner2/screens/legal/legal_screen.dart';
import 'package:runner2/screens/settings/settings_screen.dart';
import 'package:runner2/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpFrames(WidgetTester tester, [int n = 5]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('LegalScreen renders agreement and privacy docs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalScreen(doc: LegalDoc.agreement)),
    );
    await pumpFrames(tester);
    expect(find.text('用户协议'), findsWidgets);
    expect(find.textContaining('服务说明'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: LegalScreen(doc: LegalDoc.privacy)),
    );
    await pumpFrames(tester);
    expect(find.text('隐私政策'), findsWidgets);
    expect(find.textContaining('我们收集的信息'), findsOneWidget);
  });

  testWidgets('login page shows phone sms fields', (tester) async {
    final state = AppState();
    await state.init();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await pumpFrames(tester, 8);
    expect(find.textContaining('手机号'), findsWidgets);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.textContaining('用户协议'), findsOneWidget);
    expect(find.textContaining('隐私政策'), findsOneWidget);
  });

  testWidgets('settings 注销账户 clears local state', (tester) async {
    final state = AppState();
    await state.init();
    state.account = const UserAccount(
      id: 'u-del',
      username: 'alice',
      age: 24,
      height: 165,
      gender: Gender.female,
      profileComplete: true,
    );
    state.loggedIn = true;
    await state.createNote('笔记');

    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          routes: {
            '/login': (_) => const Scaffold(body: Text('login-route')),
          },
          home: const SettingsScreen(),
        ),
      ),
    );
    await pumpFrames(tester, 8);

    await tester.scrollUntilVisible(
      find.text('注销账户'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, 3);
    await tester.tap(find.text('注销账户'));
    await pumpFrames(tester, 8);
    expect(find.text('确定注销'), findsOneWidget);
    await tester.tap(find.text('确定注销'));
    await pumpFrames(tester, 15);

    expect(state.account, isNull);
    expect(find.text('login-route'), findsOneWidget);
  });

  testWidgets('意见反馈 submits successfully', (tester) async {
    final state = AppState();
    await state.init();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: FeedbackScreen()),
      ),
    );
    await pumpFrames(tester, 8);
    await tester.enterText(find.byType(TextField), '希望增加夜间模式');
    await tester.tap(find.text('提交'));
    await pumpFrames(tester, 10);

    expect(tester.takeException(), isNull);
  });
}
