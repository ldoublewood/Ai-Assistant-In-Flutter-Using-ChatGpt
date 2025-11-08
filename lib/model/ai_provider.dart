/// AI提供商类型枚举
enum AIProviderType {
  openai,
  deepseek,
  gemini,
  custom,
}

/// AI提供商扩展方法
extension AIProviderTypeExtension on AIProviderType {
  /// 获取提供商名称
  String get name {
    switch (this) {
      case AIProviderType.openai:
        return 'OpenAI';
      case AIProviderType.deepseek:
        return 'DeepSeek';
      case AIProviderType.gemini:
        return 'Google Gemini';
      case AIProviderType.custom:
        return '自定义';
    }
  }

  /// 获取默认API地址
  String get defaultApiUrl {
    switch (this) {
      case AIProviderType.openai:
        return 'https://api.openai.com/v1';
      case AIProviderType.deepseek:
        return 'https://api.deepseek.com/v1';
      case AIProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AIProviderType.custom:
        return '';
    }
  }

  /// 获取默认模型
  String get defaultModel {
    switch (this) {
      case AIProviderType.openai:
        return 'gpt-3.5-turbo';
      case AIProviderType.deepseek:
        return 'deepseek-chat';
      case AIProviderType.gemini:
        return 'gemini-1.5-flash-latest';
      case AIProviderType.custom:
        return 'gpt-3.5-turbo';
    }
  }

  /// 获取支持的模型列表
  List<String> get supportedModels {
    switch (this) {
      case AIProviderType.openai:
        return [
          'gpt-3.5-turbo',
          'gpt-4',
          'gpt-4-turbo',
          'gpt-4o',
          'gpt-4o-mini',
        ];
      case AIProviderType.deepseek:
        return [
          'deepseek-chat',
          'deepseek-coder',
        ];
      case AIProviderType.gemini:
        return [
          'gemini-1.5-flash-latest',
          'gemini-1.5-pro-latest',
          'gemini-pro',
        ];
      case AIProviderType.custom:
        return [
          'gpt-3.5-turbo',
          'gpt-4',
          'gpt-4-turbo',
          'gpt-4o',
          'gpt-4o-mini',
        ];
    }
  }

  /// 是否需要自定义URL
  bool get needsCustomUrl {
    return this == AIProviderType.custom;
  }
}

/// AI提供商配置模型
class AIProviderConfig {
  final AIProviderType type;
  final String apiKey;
  final String model;
  final String? customUrl;

  const AIProviderConfig({
    required this.type,
    required this.apiKey,
    required this.model,
    this.customUrl,
  });

  /// 从JSON创建配置
  factory AIProviderConfig.fromJson(Map<String, dynamic> json) {
    return AIProviderConfig(
      type: AIProviderType.values[json['type'] ?? 0],
      apiKey: json['apiKey'] ?? '',
      model: json['model'] ?? '',
      customUrl: json['customUrl'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'apiKey': apiKey,
      'model': model,
      'customUrl': customUrl,
    };
  }

  /// 获取API基础URL
  String get apiUrl {
    if (type == AIProviderType.custom && customUrl != null && customUrl!.isNotEmpty) {
      return customUrl!;
    }
    return type.defaultApiUrl;
  }

  /// 验证配置是否有效
  bool get isValid {
    if (apiKey.isEmpty || model.isEmpty) {
      return false;
    }
    if (type == AIProviderType.custom && (customUrl == null || customUrl!.isEmpty)) {
      return false;
    }
    return true;
  }

  /// 复制并修改配置
  AIProviderConfig copyWith({
    AIProviderType? type,
    String? apiKey,
    String? model,
    String? customUrl,
  }) {
    return AIProviderConfig(
      type: type ?? this.type,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      customUrl: customUrl ?? this.customUrl,
    );
  }
}