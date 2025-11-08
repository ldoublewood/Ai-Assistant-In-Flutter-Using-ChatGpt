import 'package:hive_flutter/hive_flutter.dart';
import '../model/ai_provider.dart';
import '../utils/logger.dart';

/// AI提供商配置服务
class AIProviderConfigService {
  static const String _keyCurrentProvider = 'current_ai_provider';
  static const String _keyProviderConfigs = 'ai_provider_configs';
  
  static Box get _box => Hive.box('myData');

  /// 获取当前AI提供商类型
  static AIProviderType getCurrentProviderType() {
    final index = _box.get(_keyCurrentProvider) ?? AIProviderType.gemini.index;
    return AIProviderType.values[index];
  }

  /// 设置当前AI提供商类型
  static Future<void> setCurrentProviderType(AIProviderType type) async {
    await _box.put(_keyCurrentProvider, type.index);
    Logger.config('当前AI提供商已设置为: ${type.name}');
  }

  /// 获取指定提供商的配置
  static AIProviderConfig? getProviderConfig(AIProviderType type) {
    final configs = _box.get(_keyProviderConfigs) as Map<dynamic, dynamic>?;
    if (configs == null) return null;

    final configData = configs[type.index.toString()] as Map<dynamic, dynamic>?;
    if (configData == null) return null;

    try {
      // 转换为 Map<String, dynamic>
      final Map<String, dynamic> jsonData = {};
      configData.forEach((key, value) {
        jsonData[key.toString()] = value;
      });
      return AIProviderConfig.fromJson(jsonData);
    } catch (e) {
      Logger.error('解析AI提供商配置失败: $e', error: e);
      return null;
    }
  }

  /// 保存指定提供商的配置
  static Future<void> saveProviderConfig(AIProviderConfig config) async {
    final configs = _box.get(_keyProviderConfigs) as Map<dynamic, dynamic>? ?? {};
    configs[config.type.index.toString()] = config.toJson();
    await _box.put(_keyProviderConfigs, configs);
    Logger.config('AI提供商配置已保存: ${config.type.name}');
  }

  /// 获取当前提供商的配置
  static AIProviderConfig? getCurrentProviderConfig() {
    final currentType = getCurrentProviderType();
    return getProviderConfig(currentType);
  }

  /// 获取所有已配置的提供商
  static List<AIProviderType> getConfiguredProviders() {
    final configs = _box.get(_keyProviderConfigs) as Map<dynamic, dynamic>?;
    if (configs == null) return [];

    final List<AIProviderType> providers = [];
    for (final key in configs.keys) {
      try {
        final index = int.parse(key.toString());
        if (index >= 0 && index < AIProviderType.values.length) {
          final type = AIProviderType.values[index];
          final config = getProviderConfig(type);
          if (config != null && config.isValid) {
            providers.add(type);
          }
        }
      } catch (e) {
        Logger.warning('解析提供商索引失败: $key');
      }
    }
    return providers;
  }

  /// 删除指定提供商的配置
  static Future<void> removeProviderConfig(AIProviderType type) async {
    final configs = _box.get(_keyProviderConfigs) as Map<dynamic, dynamic>? ?? {};
    configs.remove(type.index.toString());
    await _box.put(_keyProviderConfigs, configs);
    Logger.config('AI提供商配置已删除: ${type.name}');
  }

  /// 重置所有配置
  static Future<void> resetAllConfigs() async {
    await _box.delete(_keyCurrentProvider);
    await _box.delete(_keyProviderConfigs);
    Logger.config('所有AI提供商配置已重置');
  }

  /// 验证当前配置是否有效
  static bool isCurrentConfigValid() {
    final config = getCurrentProviderConfig();
    return config != null && config.isValid;
  }

  /// 获取默认配置（用于初始化）
  static AIProviderConfig getDefaultConfig(AIProviderType type) {
    return AIProviderConfig(
      type: type,
      apiKey: '',
      model: type.defaultModel,
      customUrl: type == AIProviderType.custom ? '' : null,
    );
  }
}