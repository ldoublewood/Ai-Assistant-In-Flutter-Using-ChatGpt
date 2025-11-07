import '../helper/pref.dart';
import '../utils/logger.dart';
import 'audio_format_config.dart';

/// 语音识别配置管理类
class VoiceConfig {
  // 配置键名
  static const String _keyUseRemoteVoice = 'use_remote_voice';
  static const String _keyRemoteVoiceUrl = 'remote_voice_url';
  static const String _keyVoiceLanguage = 'voice_language';
  
  // 默认配置
  static const String _defaultRemoteUrl = 'http://localhost:8000';
  static const String _defaultLanguage = 'auto';
  
  /// 是否使用远程语音识别
  static bool get useRemoteVoice {
    return Pref.getBool(_keyUseRemoteVoice) ?? false;
  }
  
  /// 设置是否使用远程语音识别
  static Future<void> setUseRemoteVoice(bool value) async {
    await Pref.setBool(_keyUseRemoteVoice, value);
    Logger.config('语音识别模式设置为: ${value ? "远程" : "本地"}');
  }
  
  /// 获取远程语音识别服务器地址
  static String get remoteVoiceUrl {
    return Pref.getString(_keyRemoteVoiceUrl) ?? _defaultRemoteUrl;
  }
  
  /// 设置远程语音识别服务器地址
  static Future<void> setRemoteVoiceUrl(String url) async {
    final cleanUrl = url.trim();
    await Pref.setString(_keyRemoteVoiceUrl, cleanUrl);
    Logger.config('远程语音识别服务器地址设置为: $cleanUrl');
  }
  
  /// 获取语音识别语言
  static String get voiceLanguage {
    return Pref.getString(_keyVoiceLanguage) ?? _defaultLanguage;
  }
  
  /// 设置语音识别语言
  static Future<void> setVoiceLanguage(String language) async {
    await Pref.setString(_keyVoiceLanguage, language);
    Logger.config('语音识别语言设置为: $language');
  }
  
  /// 获取所有配置信息
  static Map<String, dynamic> getAllConfig() {
    return {
      'useRemoteVoice': useRemoteVoice,
      'remoteVoiceUrl': remoteVoiceUrl,
      'voiceLanguage': voiceLanguage,
      'audioFormat': AudioFormatConfig.audioFormat,
      'audioFormatName': AudioFormatConfig.getFormatName(AudioFormatConfig.audioFormat),
    };
  }
  
  /// 重置为默认配置
  static Future<void> resetToDefault() async {
    await setUseRemoteVoice(false);
    await setRemoteVoiceUrl(_defaultRemoteUrl);
    await setVoiceLanguage(_defaultLanguage);
    await AudioFormatConfig.resetToDefault();
    Logger.config('语音识别配置已重置为默认值');
  }
  
  /// 验证远程服务器地址格式
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// 支持的语言列表
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'auto', 'name': '自动检测'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'en', 'name': '英语'},
    {'code': 'ja', 'name': '日语'},
    {'code': 'ko', 'name': '韩语'},
    {'code': 'yue', 'name': '粤语'},
  ];
  
  /// 根据语言代码获取语言名称
  static String getLanguageName(String code) {
    final language = supportedLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'code': code, 'name': code},
    );
    return language['name'] ?? code;
  }
}