import 'remote_voice_service.dart';
import 'voice_config.dart';
import '../utils/logger.dart';

/// 语音服务统一接口类，支持本地和远程语音识别
class VoiceService {
  /// 将音频文件进行语音识别
  /// [audioPath] 音频文件路径
  /// 返回识别出的文字内容
  static Future<String> speechToText(String audioPath) async {
    try {
      Logger.voice('开始语音识别，音频文件路径: $audioPath');
      Logger.voice('使用${VoiceConfig.useRemoteVoice ? "远程" : "本地"}语音识别');
      
      if (VoiceConfig.useRemoteVoice) {
        // 使用远程语音识别
        RemoteVoiceService.setBaseUrl(VoiceConfig.remoteVoiceUrl);
        return await RemoteVoiceService.speechToText(
          audioPath,
          language: VoiceConfig.voiceLanguage,
        );
      } else {
        // 本地语音识别已被屏蔽，提示用户
        Logger.warning('本地语音识别已被禁用');
        return '本地语音识别功能已禁用，请在设置中启用远程语音识别';
      }
    } catch (e) {
      Logger.error('语音识别异常: $e', error: e);
      return '语音识别出错: ${e.toString()}';
    }
  }
  
  /// 检查语音识别服务连接状态
  static Future<bool> checkServerConnection() async {
    try {
      if (VoiceConfig.useRemoteVoice) {
        // 检查远程服务器连接
        RemoteVoiceService.setBaseUrl(VoiceConfig.remoteVoiceUrl);
        return await RemoteVoiceService.checkServerConnection();
      } else {
        // 本地语音识别已被屏蔽
        Logger.warning('本地语音识别已被禁用');
        return false;
      }
    } catch (e) {
      Logger.error('服务器连接检查失败: $e', error: e);
      return false;
    }
  }
  
  /// 获取当前语音识别配置信息
  static Map<String, dynamic> getConfigInfo() {
    return VoiceConfig.getAllConfig();
  }
  
  /// 获取服务器信息（仅远程模式）
  static Future<Map<String, dynamic>?> getServerInfo() async {
    if (VoiceConfig.useRemoteVoice) {
      RemoteVoiceService.setBaseUrl(VoiceConfig.remoteVoiceUrl);
      return await RemoteVoiceService.getServerInfo();
    }
    return null;
  }
}