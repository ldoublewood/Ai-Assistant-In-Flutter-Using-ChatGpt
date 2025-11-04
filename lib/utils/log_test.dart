import 'logger.dart';
import 'platform_logger.dart';

/// 日志测试工具类
class LogTest {
  /// 测试所有日志输出方式
  static void testAllLogMethods() {
    Logger.info('=== 开始日志测试 ===');
    
    // 测试不同级别的日志
    Logger.debug('这是一条调试日志');
    Logger.info('这是一条信息日志');
    Logger.warning('这是一条警告日志');
    Logger.error('这是一条错误日志');
    
    // 测试带标签的日志
    Logger.voice('语音识别测试日志');
    Logger.network('网络请求测试日志');
    Logger.config('配置更新测试日志');
    
    // 测试错误日志（带异常信息）
    try {
      throw Exception('这是一个测试异常');
    } catch (e, stackTrace) {
      Logger.error('捕获到测试异常', error: e, stackTrace: stackTrace);
    }
    
    // 测试平台特定日志
    PlatformLogger.forceLog('平台强制日志测试');
    PlatformLogger.verbose('详细日志测试');
    
    Logger.info('=== 日志测试完成 ===');
    Logger.info('如果你能在logcat中看到这些消息，说明日志配置正常');
  }
  
  /// 测试语音相关日志
  static void testVoiceLogs() {
    Logger.voice('开始语音识别测试');
    Logger.voice('音频文件路径: /test/path/audio.wav');
    Logger.voice('使用服务器地址: http://localhost:8000');
    Logger.voice('语音识别成功: 测试识别结果');
    Logger.voice('语音识别测试完成');
  }
  
  /// 测试网络相关日志
  static void testNetworkLogs() {
    Logger.network('发送HTTP请求: POST /extract_text');
    Logger.network('请求头: Content-Type: multipart/form-data');
    Logger.network('响应状态码: 200');
    Logger.network('响应数据: {"message": "success"}');
  }
}