import 'package:appwrite/appwrite.dart';

import '../utils/logger.dart';

class AppWrite {
  static final _client = Client();
  // static final _database = Databases(_client); // 暂时注释，因为当前未使用

  static void init() {
    _client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('658813fd62bd45e744cd')
        .setSelfSigned(status: true);
    
    // 注意：由于已实现多AI提供商配置系统，暂时禁用AppWrite的API密钥获取
    // 如需重新启用，请更新为新的AppWrite API方法
    // getApiKey();
    
    Logger.config('AppWrite已初始化（API密钥获取已禁用）');
  }

  /// 获取API密钥（已弃用，使用新的AI提供商配置系统）
  @Deprecated('请使用AIProviderConfigService管理API密钥')
  static Future<String> getApiKey() async {
    try {
      // TODO: 当需要重新启用时，请使用新的AppWrite API方法替换listDocuments
      // 参考: https://appwrite.io/docs/references/cloud/client-web/databases#listDocuments
      
      Logger.warning('AppWrite API密钥获取功能已禁用，请使用AI提供商设置');
      return '';
      
      /* 原始代码（已注释以避免deprecated警告）:
      final response = await _database.listDocuments(
        databaseId: 'MyDatabase',
        collectionId: 'ApiKey',
        queries: [
          Query.equal('\$id', 'chatGptKey'),
        ],
      );

      if (response.documents.isNotEmpty) {
        final document = response.documents.first;
        final data = document.data;
        
        if (data.containsKey('apiKey') && data['apiKey'] != null) {
          apiKey = data['apiKey'].toString();
          Logger.config('API Key已成功获取');
          return apiKey;
        } else {
          Logger.warning('文档中未找到有效的apiKey字段');
          return '';
        }
      } else {
        Logger.warning('未找到API Key文档');
        return '';
      }
      */
    } catch (e) {
      Logger.error('获取API Key失败: $e', error: e);
      return _getFallbackApiKey();
    }
  }

  /// 获取备用API密钥的方法
  static String _getFallbackApiKey() {
    // 这里可以从环境变量、配置文件或其他安全存储中获取API密钥
    // 作为演示，返回空字符串，实际应用中应该有适当的备用方案
    Logger.info('使用备用API Key获取方法');
    return '';
  }
}
