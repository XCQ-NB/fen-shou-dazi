# Android 构建验证记录

验证日期：2026-07-18

## 验证环境

- Flutter：3.44.6 stable
- Dart：3.12.2
- Java：OpenJDK 17
- Android SDK：36.1.0
- Android applicationId：`com.dazi.runner2`
- 应用名称：找搭子

## 已执行命令

```text
dart format lib test
flutter analyze
flutter test
flutter build ios --simulator
flutter build apk --debug
```

## 验证结果

- Dart/Flutter 静态分析：通过，0 个问题
- 单元测试：7 项全部通过
- iOS 模拟器构建：通过
- Android Gradle Debug 构建：通过
- APK：`runner2-v2-android-debug.apk`
- APK SHA-256：
  `fef83034c1cfb3fb81260df5b92e4bd58fb6132af46414c5280918bf9b7ca4c0`
- 源码包 SHA-256：
  `5ccc096de1a705a4fa4b494815e1eabda92bb7a10ad87ea9fa236e6c55b4a08a`

## 本次交互升级摘要

- 找搭子顶部：在线 / 同城 / 推荐 / 消息
- 列表仅展示异性；推荐优先在线与聊天活跃度
- 头像进入完整个人主页（含我的故事）
- 记事本统一编辑页，实时保存，右上角复制全文
- 记事本天气图标同步戒断状态（未启用显示太阳）
- 戒断计时精确到秒：上层天/时，下层分/秒
