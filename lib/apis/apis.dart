import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../helper/global.dart';

class APIs {
  /// 从Google Gemini AI获取回答
  static Future<String> getAnswer(String question) async {
    try {
      log('正在调用AI接口，API Key: ${apiKey.substring(0, 10)}...');

      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );

      // 添加系统提示，让AI更好地支持中文和Markdown格式
      final prompt = '''
你是一个友好、专业的AI助手。请用中文回答用户的问题。
在回答时，你可以使用Markdown格式来让内容更清晰易读，包括：
- 使用**粗体**强调重点
- 使用`代码`标记技术术语
- 使用```代码块```展示代码
- 使用列表和标题组织内容
- 使用>引用重要信息

用户问题：$question
''';

      final content = [Content.text(prompt)];
      final res = await model.generateContent(
        content,
        safetySettings: [
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        ],
      );

      final answer = res.text ?? '抱歉，我无法生成回答。';
      log('AI回答: ${answer.substring(0, answer.length > 100 ? 100 : answer.length)}...');

      return answer;
    } catch (e) {
      log('AI接口调用错误: $e');
      return '抱歉，服务暂时不可用，请稍后重试。如果问题持续存在，请检查网络连接或API密钥配置。';
    }
  }
}
