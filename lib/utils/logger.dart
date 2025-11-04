import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'platform_logger.dart';

/// 统一的日志工具类
/// 在Debug模式下同时输出到开发者工具和logcat
/// 在Release模式下不输出日志
class Logger {
  static const String _tag = 'AiAssistant';
  
  /// 输出信息日志
  static void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }
  
  /// 输出调试日志
  static void debug(String message, {String? tag}) {
    _log('DEBUG', message, tag: tag);
  }
  
  /// 输出警告日志
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('WARNING', message, tag: tag);
    
    // 如果有错误信息，也输出错误详情
    if (error != null) {
      _log('WARNING', 'Exception: $error', tag: tag);
    }
    if (stackTrace != null && kDebugMode) {
      // 只在debug模式下输出堆栈跟踪的前几行
      final stackLines = stackTrace.toString().split('\n');
      for (int i = 0; i < stackLines.length && i < 3; i++) {
        _log('WARNING', 'Stack: ${stackLines[i]}', tag: tag);
      }
    }
  }
  
  /// 输出错误日志
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, tag: tag);
    
    // 使用平台特定的错误日志输出，包含详细的堆栈信息
    if (error != null || stackTrace != null) {
      PlatformLogger.errorWithStack(message, error, stackTrace, tag: tag ?? _tag);
    }
  }
  
  /// 内部日志输出方法
  static void _log(String level, String message, {String? tag}) {
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      final logMessage = '[$level] $message';
      
      // 输出到Flutter开发者工具
      developer.log(logMessage, name: logTag);
      
      // 强制输出到平台日志系统（确保在logcat中可见）
      PlatformLogger.forceLog(logMessage, tag: logTag);
    }
  }
  
  /// 语音识别专用日志
  static void voice(String message) {
    info(message, tag: 'Voice');
  }
  
  /// 网络请求专用日志
  static void network(String message) {
    info(message, tag: 'Network');
  }
  
  /// 配置专用日志
  static void config(String message) {
    info(message, tag: 'Config');
  }
}