# 分手搭子（找搭子）Flutter 客户端

跨平台 App：手机号登录、找搭子、即时聊天、记事本、戒断计时、AI 情绪陪伴。  
iOS / Android 共用同一套 Dart 代码，默认连接线上服务：

`https://social.ctm.cloudpasture.site`

别人拉取本仓库后，按下面步骤即可运行。

## 环境要求

- Flutter **3.44.6**（stable）或兼容版本
- Dart 3.12+
- iOS：macOS + Xcode（建议 16+）
- Android：Android Studio + JDK 17 + Android SDK

检查环境：

```bash
flutter doctor
```

## 快速开始

```bash
git clone https://github.com/XCQ-NB/fen-shou-dazi.git
cd fen-shou-dazi
flutter pub get
```

### 运行到 Android

```bash
# 启动模拟器，或连接已开启 USB 调试的手机
flutter devices
flutter run
```

正式包（可选）：

```bash
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

### 运行到 iOS（仅 macOS）

```bash
cd ios
pod install
cd ..
flutter run
```

真机若 Debug 不稳定，可用 Release：

```bash
flutter run --release
```

## 登录说明

1. 打开 App 后用 **中国大陆手机号** 获取验证码并登录。
2. 开发/测试环境可用固定验证码：`123456`。
3. 新用户首次登录需完善昵称、性别、年龄、身高、头像等资料。

## 主要功能

- 找搭子：在线 / 同城 / 推荐
- 消息：真人聊天 + AI 情绪陪伴（WebSocket）
- 记事本、戒断计时（跨设备云同步）
- 他人主页查看故事，可举报违规账号
- 设置：会员演示、意见反馈、协议与隐私

## 目录结构

```text
lib/                 # 业务与 UI
android/ ios/        # 原生工程
test/                # 单元 / UI 回归测试
integration_test/    # 截图与集成测试
```

## 常见问题

**1. `pod install` 报错**  
先执行：`cd ios && pod install --repo-update`

**2. Android 构建缺少 cmdline-tools**  
安装 Android SDK Command-line Tools，并执行 `flutter doctor --android-licenses`

**3. 无法收短信**  
测试阶段可直接输入 `123456`

**4. 想自建后端**  
后端为独立 Node.js 服务（短信登录、社交、同步、管理后台）。仓库默认指向线上 API；自建需单独部署服务并修改：

- `lib/services/api_client.dart`
- `lib/services/ai_api.dart`

中的 `baseUrl`。

## 许可证

仅供学习与演示使用。请勿用于违法违规用途。
