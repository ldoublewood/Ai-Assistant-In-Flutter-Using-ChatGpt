import '../services/ai_service.dart';

class APIs {
  /// 获取AI回答（使用新的多提供商服务）
  static Future<String> getAnswer(String question) async {
    return await AIService.getAnswer(question);
  }
}
