import 'dart:io';
import 'package:flutter/foundation.dart';

/// 平台特定的日志工具
class PlatformLogger {
  /// 强制输出到平台日志系统
  static void forceLog(String message, {String? tag}) {
    if (kDebugMode) {
      final logTag = tag ?? 'AiAssistant';
      final logMessage = '[$logTag] $message';
      
      // 在Android上，使用print确保输出到logcat
      if (Platform.isAndroid) {
        print(logMessage);
      }
      
      // 在iOS上，使用debugPrint
      if (Platform.isIOS) {
        debugPrint(logMessage);
      }
      
      // 其他平台使用标准输出
      if (!Platform.isAndroid && !Platform.isIOS) {
        print(logMessage);
      }
    }
  }
  
  /// 输出详细的调试信息
  static void verbose(String message, {String? tag}) {
    forceLog('[VERBOSE] $message', tag: tag);
  }
  
  /// 输出错误信息并包含堆栈跟踪
  static void errorWithStack(String message, Object? error, StackTrace? stackTrace, {String? tag}) {
    forceLog('[ERROR] $message', tag: tag);
    if (error != null) {
      forceLog('[ERROR] Exception: $error', tag: tag);
    }
    if (stackTrace != null && kDebugMode) {
      // 只在debug模式下输出堆栈跟踪的前几行
      final stackLines = stackTrace.toString().split('\n');
      for (int i = 0; i < stackLines.length && i < 5; i++) {
        forceLog('[ERROR] ${stackLines[i]}', tag: tag);
      }
    }
  }
}