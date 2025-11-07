import 'package:appwrite/appwrite.dart';

import '../helper/global.dart';
import '../utils/logger.dart';

class AppWrite {
  static final _client = Client();
  static final _database = Databases(_client);

  static void init() {
    _client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('658813fd62bd45e744cd')
        .setSelfSigned(status: true);
    getApiKey();
  }

  static Future<String> getApiKey() async {
    try {
      // 注意：listDocuments在AppWrite 1.8.0+中已弃用，建议升级到新版本API
      // 但当前AppWrite SDK版本仍使用此方法，等待SDK更新后再迁移
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
    } catch (e) {
      Logger.error('获取API Key失败: $e', error: e);
      // 如果从数据库获取失败，可以考虑使用环境变量或配置文件
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
