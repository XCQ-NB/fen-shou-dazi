import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 前端统一调试日志。
/// - debug/profile 默认开启
/// - release 也可通过 [forceEnable] 打开（真机排查闪退时有用）
class AppLog {
  /// Release 默认关闭：避免把用户名、消息预览等打进设备日志。
  /// 真机排查闪退时可临时改为 true 重新打包。
  static bool forceEnable = false;
  static const String tag = 'runner2';

  static bool get enabled => forceEnable || !kReleaseMode;

  static void d(String message, {String? scope, Object? data}) {
    _write('D', message, scope: scope, data: data);
  }

  static void i(String message, {String? scope, Object? data}) {
    _write('I', message, scope: scope, data: data);
  }

  static void w(String message, {String? scope, Object? data}) {
    _write('W', message, scope: scope, data: data);
  }

  static void e(
    String message, {
    String? scope,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write('E', message, scope: scope, data: error);
    if (enabled && stackTrace != null) {
      developer.log(
        stackTrace.toString(),
        name: '$tag/${scope ?? 'app'}',
        level: 1000,
      );
      // ignore: avoid_print
      print('[$tag/${scope ?? 'app'}][E] $stackTrace');
    }
  }

  static void _write(
    String level,
    String message, {
    String? scope,
    Object? data,
  }) {
    if (!enabled) return;
    final name = '$tag/${scope ?? 'app'}';
    final text = data == null ? message : '$message | $data';
    developer.log(text, name: name, level: level == 'E' ? 1000 : 800);
    // 同步打到控制台，方便 Xcode / flutter run 直接看
    // ignore: avoid_print
    print('[$name][$level] $text');
  }
}
