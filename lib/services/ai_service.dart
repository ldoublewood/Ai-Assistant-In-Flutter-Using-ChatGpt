import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

import '../model/ai_provider.dart';
import '../services/ai_provider_config.dart';
import '../utils/logger.dart';

/// AI服务类，统一处理不同AI提供商的调用
class AIService {
  /// 获取AI回答
  static Future<String> getAnswer(String question) async {
    final config = AIProviderConfigService.getCurrentProviderConfig();
    
    if (config == null || !config.isValid) {
      return '请先在设置中配置AI提供商的API密钥和模型';
    }

    try {
      Logger.debug('正在调用${config.type.name} API，模型: ${config.model}');
      
      switch (config.type) {
        case AIProviderType.gemini:
          return await _callGeminiAPI(config, question);
        case AIProviderType.openai:
        case AIProviderType.deepseek:
        case AIProviderType.custom:
          return await _callOpenAICompatibleAPI(config, question);
      }
    } catch (e) {
      Logger.error('AI接口调用错误: $e', error: e);
      return '抱歉，AI服务暂时不可用，请稍后重试。错误信息: $e';
    }
  }

  /// 调用Google Gemini API
  static Future<String> _callGeminiAPI(AIProviderConfig config, String question) async {
    try {
      final model = GenerativeModel(
        model: config.model,
        apiKey: config.apiKey,
      );

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
      Logger.debug('Gemini回答长度: ${answer.length}');
      return answer;
    } catch (e) {
      Logger.error('Gemini API调用失败: $e', error: e);
      rethrow;
    }
  }

  /// 调用OpenAI兼容的API（支持OpenAI、DeepSeek、自定义）
  static Future<String> _callOpenAICompatibleAPI(AIProviderConfig config, String question) async {
    try {
      final url = '${config.apiUrl}/chat/completions';
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      };

      final body = {
        'model': config.model,
        'messages': [
          {
            'role': 'system',
            'content': '''你是一个友好、专业的AI助手。请用中文回答用户的问题。
在回答时，你可以使用Markdown格式来让内容更清晰易读，包括：
- 使用**粗体**强调重点
- 使用`代码`标记技术术语
- 使用```代码块```展示代码
- 使用列表和标题组织内容
- 使用>引用重要信息'''
          },
          {
            'role': 'user',
            'content': question,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
        'stream': false,
      };

      Logger.debug('请求URL: $url');
      Logger.debug('请求模型: ${config.model}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      Logger.debug('响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (responseData['choices'] != null && 
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null) {
          
          final answer = responseData['choices'][0]['message']['content'] ?? '抱歉，我无法生成回答。';
          Logger.debug('${config.type.name}回答长度: ${answer.length}');
          return answer;
        } else {
          Logger.error('API响应格式异常: $responseData');
          return '抱歉，AI服务返回了异常的响应格式。';
        }
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        Logger.error('API请求失败，状态码: ${response.statusCode}，响应: $errorBody');
        
        // 尝试解析错误信息
        try {
          final errorData = jsonDecode(errorBody);
          final errorMessage = errorData['error']?['message'] ?? '未知错误';
          return '抱歉，AI服务请求失败: $errorMessage';
        } catch (e) {
          return '抱歉，AI服务请求失败，状态码: ${response.statusCode}';
        }
      }
    } catch (e) {
      Logger.error('${config.type.name} API调用失败: $e', error: e);
      rethrow;
    }
  }

  /// 测试API连接
  static Future<bool> testConnection(AIProviderConfig config) async {
    try {
      Logger.debug('测试${config.type.name} API连接...');
      
      switch (config.type) {
        case AIProviderType.gemini:
          return await _testGeminiConnection(config);
        case AIProviderType.openai:
        case AIProviderType.deepseek:
        case AIProviderType.custom:
          return await _testOpenAICompatibleConnection(config);
      }
    } catch (e) {
      Logger.error('API连接测试失败: $e', error: e);
      return false;
    }
  }

  /// 测试Gemini API连接
  static Future<bool> _testGeminiConnection(AIProviderConfig config) async {
    try {
      final model = GenerativeModel(
        model: config.model,
        apiKey: config.apiKey,
      );

      final content = [Content.text('测试连接')];
      await model.generateContent(content);
      
      Logger.debug('Gemini API连接测试成功');
      return true;
    } catch (e) {
      Logger.error('Gemini API连接测试失败: $e', error: e);
      return false;
    }
  }

  /// 测试OpenAI兼容API连接
  static Future<bool> _testOpenAICompatibleConnection(AIProviderConfig config) async {
    try {
      final url = '${config.apiUrl}/chat/completions';
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      };

      final body = {
        'model': config.model,
        'messages': [
          {
            'role': 'user',
            'content': '测试连接',
          }
        ],
        'max_tokens': 10,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        Logger.debug('${config.type.name} API连接测试成功');
        return true;
      } else {
        Logger.error('${config.type.name} API连接测试失败，状态码: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('${config.type.name} API连接测试失败: $e', error: e);
      return false;
    }
  }
}