import '../helper/pref.dart';
import '../utils/logger.dart';

/// 音频格式配置管理类
class AudioFormatConfig {
  // 配置键名
  static const String _keyAudioFormat = 'audio_format';
  
  // 默认配置
  static const String _defaultFormat = 'aac';
  
  /// 支持的音频格式
  static const List<Map<String, String>> supportedFormats = [
    {'code': 'aac', 'name': 'AAC格式', 'description': '高质量压缩格式，文件较小'},
    {'code': 'wav', 'name': 'WAV格式', 'description': '无损音频格式，文件较大'},
    {'code': 'pcm2wav', 'name': 'PCM转WAV', 'description': '先录制PCM再转换为WAV（适用于华为等设备）'},
  ];
  
  /// 获取当前音频格式
  static String get audioFormat {
    return Pref.getString(_keyAudioFormat) ?? _defaultFormat;
  }
  
  /// 设置音频格式
  static Future<void> setAudioFormat(String format) async {
    if (!_isValidFormat(format)) {
      throw ArgumentError('不支持的音频格式: $format');
    }
    
    await Pref.setString(_keyAudioFormat, format);
    Logger.config('音频录制格式设置为: $format');
  }
  
  /// 验证音频格式是否有效
  static bool _isValidFormat(String format) {
    return supportedFormats.any((f) => f['code'] == format);
  }
  
  /// 根据格式代码获取格式名称
  static String getFormatName(String code) {
    final format = supportedFormats.firstWhere(
      (f) => f['code'] == code,
      orElse: () => {'code': code, 'name': code, 'description': ''},
    );
    return format['name'] ?? code;
  }
  
  /// 根据格式代码获取格式描述
  static String getFormatDescription(String code) {
    final format = supportedFormats.firstWhere(
      (f) => f['code'] == code,
      orElse: () => {'code': code, 'name': code, 'description': ''},
    );
    return format['description'] ?? '';
  }
  
  /// 获取所有配置信息
  static Map<String, dynamic> getAllConfig() {
    return {
      'audioFormat': audioFormat,
      'formatName': getFormatName(audioFormat),
      'formatDescription': getFormatDescription(audioFormat),
    };
  }
  
  /// 重置为默认配置
  static Future<void> resetToDefault() async {
    await setAudioFormat(_defaultFormat);
    Logger.config('音频格式配置已重置为默认值: $_defaultFormat');
  }
}