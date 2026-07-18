import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:runner2/main.dart' as app;
import 'package:runner2/state/app_state.dart';
import 'package:runner2/screens/partners/partner_profile_screen.dart';
import 'package:runner2/screens/settings/settings_screen.dart';
import 'package:runner2/widgets/common_widgets.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 戒断页有 1s 周期计时器，pumpAndSettle 会永远卡住 —— 全程用手动泵帧。
  Future<void> settle(WidgetTester tester,
      {int seconds = 3, int step = 200}) async {
    final ticks = (seconds * 1000) ~/ step;
    for (var i = 0; i < ticks; i++) {
      await tester.pump(Duration(milliseconds: step));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await settle(tester, seconds: 1);
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await settle(tester, seconds: 1);
    }
    await binding.takeScreenshot(name);
  }

  Future<void> tapNav(WidgetTester tester, int index) async {
    final item = find
        .descendant(of: find.byType(AppBottomNav), matching: find.byType(InkWell))
        .at(index);
    await tester.tap(item);
    await settle(tester, seconds: 2);
  }

  AppState stateOf(WidgetTester tester) {
    final ctx = tester.element(find.byType(MaterialApp));
    return Provider.of<AppState>(ctx, listen: false);
  }

  // 直接弹出栈顶路由，避免 pageBack 在多个返回按钮时报错。
  Future<void> goBack(WidgetTester tester) async {
    final navCtx = tester.element(find.byType(Navigator).last);
    Navigator.of(navCtx).pop();
    await settle(tester, seconds: 1);
  }

  testWidgets('capture all pages', (tester) async {
    app.main();
    await settle(tester, seconds: 6);

    // 1. 登录页（登录前先截）
    await shoot(tester, '15_login');

    // 通过 AppState 直接用测试验证码登录 luluasda（女）
    final state = stateOf(tester);
    try {
      await state.loginWithSms(phone: '17799324380', code: '123456');
    } catch (e) {
      debugPrint('login failed: $e');
    }
    await settle(tester, seconds: 4);

    // 即时补齐本地数据：会员演示 + 戒断 15 天 + 记事本若干
    try {
      await state.setVip(true);
      await state.startAbstinence(hours: 360, minutes: 0);
      final notes = <String>[
        '决定开始记录的第一天。把想说的话写在这里，而不是发给他。手有点抖，但写完之后，胸口那块石头轻了一点。',
        '今天路过我们常去的那家店，差点走进去。骤雨突然下起来，我站在屋檐下等了很久，雨停的时候，冲动也停了。',
        '第一次一个人去看电影。旁边情侣在分享爆米花，我居然没有难过，反而觉得——原来一个人也可以把周末过得很满。',
        '报名了陶艺课。手上沾满泥土的那一刻，忽然觉得踏实：我的双手可以创造美好，而不只是用来挽留。',
        '同事问我最近气色为什么变好了。其实是因为我终于开始好好吃饭、好好睡觉、好好爱自己了。',
        '半个月了。翻回去看第一天写的字，像在看另一个人。谢谢那个没有放弃的自己，明天继续。',
      ];
      for (final c in notes) {
        await state.createNote(c);
        await settle(tester, seconds: 1);
      }
    } catch (e) {
      debugPrint('seed local failed: $e');
    }
    await settle(tester, seconds: 3);

    // 1. 找搭子（在线）
    await shoot(tester, '01_find_partners');

    // 2. 推荐筛选
    try {
      await tester.tap(find.text('推荐'));
      await settle(tester, seconds: 2);
      await shoot(tester, '02_find_partners_recommend');
    } catch (e) {
      debugPrint('step02 failed: $e');
    }

    // 3. 他人资料
    try {
      await tester.tap(find.textContaining('Milkyway').first);
      await settle(tester, seconds: 2);
      await shoot(tester, '03_partner_profile');

      // 4. 故事详情
      final storyCard = find.descendant(
        of: find.byType(PartnerProfileScreen),
        matching: find.text('我的故事'),
      );
      await tester.tap(storyCard);
      await settle(tester, seconds: 2);
      await shoot(tester, '04_story_detail');
      await goBack(tester);
      await settle(tester, seconds: 1);
      await goBack(tester);
      await settle(tester, seconds: 2);
    } catch (e) {
      debugPrint('step03/04 failed: $e');
    }

    // 5. 消息列表
    try {
      await tester.tap(find.text('消息'));
      await settle(tester, seconds: 2);
      await shoot(tester, '05_messages');

      // 6. 聊天页
      await tester.tap(find.text('Milkyway').first);
      await settle(tester, seconds: 3);
      await shoot(tester, '06_chat');
      await goBack(tester);
      await settle(tester, seconds: 1);
      await tester.tap(find.text('在线'));
      await settle(tester, seconds: 1);
    } catch (e) {
      debugPrint('step05/06 failed: $e');
    }

    // 7. 记事本
    try {
      await tapNav(tester, 1);
      await shoot(tester, '07_notebook');

      // 8. 记事本详情（点最上方最新一条，避免懒加载未构建）
      await tester.tap(find.textContaining('半个月了').first);
      await settle(tester, seconds: 2);
      await shoot(tester, '08_notebook_editor');
      await goBack(tester);
      await settle(tester, seconds: 1);
    } catch (e) {
      debugPrint('step07/08 failed: $e');
    }

    // 9. 戒断计时
    try {
      await tapNav(tester, 2);
      await shoot(tester, '09_abstinence');
    } catch (e) {
      debugPrint('step09 failed: $e');
    }

    // 10. 我的
    try {
      await tapNav(tester, 3);
      await shoot(tester, '10_settings');
    } catch (e) {
      debugPrint('step10 failed: $e');
    }

    // 11. 我的故事编辑
    try {
      await tester.tap(find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.text('我的故事'),
      ));
      await settle(tester, seconds: 2);
      await shoot(tester, '11_story_editor');
      await goBack(tester);
      await settle(tester, seconds: 1);
    } catch (e) {
      debugPrint('step11 failed: $e');
    }

    // 12. 编辑资料
    try {
      await tester.tap(find.text('编辑资料'));
      await settle(tester, seconds: 2);
      await shoot(tester, '12_profile_edit');
      await goBack(tester);
      await settle(tester, seconds: 1);
    } catch (e) {
      debugPrint('step12 failed: $e');
    }

    // 13. 意见反馈
    try {
      await tester.tap(find.text('意见反馈'));
      await settle(tester, seconds: 2);
      await shoot(tester, '13_feedback');
      await goBack(tester);
      await settle(tester, seconds: 1);
    } catch (e) {
      debugPrint('step13 failed: $e');
    }

    // 14. 用户协议
    try {
      await tester.tap(find.text('用户协议'));
      await settle(tester, seconds: 2);
      await shoot(tester, '14_legal_agreement');
      await goBack(tester);
      await settle(tester, seconds: 1);
    } catch (e) {
      debugPrint('step14 failed: $e');
    }
  });
}
