import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// 远程语音识别服务类，基于SenseVoice-Api
class RemoteVoiceService {
  // SenseVoice-Api默认端口是8000
  static const String _defaultBaseUrl = 'http://localhost:8000';
  static String _baseUrl = _defaultBaseUrl;
  
  /// 设置服务器地址
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    Logger.config('远程语音识别服务地址设置为: $_baseUrl');
  }
  
  /// 获取当前服务器地址
  static String get baseUrl => _baseUrl;
  
  /// 将音频文件发送到SenseVoice服务器进行语音识别
  /// [audioPath] 音频文件路径
  /// [language] 识别语言，默认为auto自动检测
  /// 返回识别出的文字内容
  static Future<String> speechToText(String audioPath, {String language = 'auto'}) async {
    try {
      Logger.voice('开始远程语音识别，音频文件路径: $audioPath');
      Logger.voice('使用服务器地址: $_baseUrl');
      
      // 检查文件是否存在
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        Logger.error('音频文件不存在: $audioPath');
        return '音频文件不存在';
      }
      
      // 检查文件大小（SenseVoice建议不超过30MB）
      final fileSize = await audioFile.length();
      if (fileSize > 30 * 1024 * 1024) {
        Logger.warning('音频文件过大: ${fileSize / 1024 / 1024}MB');
        return '音频文件过大，请使用小于30MB的文件';
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/extract_text'),
      );
      
      // 添加音频文件 - 新API使用 'file' 字段名
      request.files.add(
        await http.MultipartFile.fromPath('file', audioPath),
      );
      
      Logger.network('发送请求到: $_baseUrl/extract_text');
      
      var response = await request.send().timeout(
        const Duration(seconds: 30), // 30秒超时
      );
      var responseData = await response.stream.bytesToString();
      
      Logger.network('响应状态码: ${response.statusCode}');
      Logger.network('响应数据: $responseData');
      
      if (response.statusCode == 200) {
        try {
          var jsonData = json.decode(responseData);
          
          // 检查新API的响应格式
          if (jsonData['message'] == 'input processed successfully') {
            String recognizedText = jsonData['results'] ?? '';
            String labelResult = jsonData['label_result'] ?? '';
            
            Logger.voice('语音识别成功: $recognizedText');
            Logger.voice('完整标签结果: $labelResult');
            
            // 从标签结果中提取语言和情感信息
            if (labelResult.isNotEmpty) {
              _parseLabels(labelResult);
            }
            
            return recognizedText.isNotEmpty ? recognizedText : '未识别到语音内容';
          } else {
            String errorMsg = jsonData['message'] ?? '未知错误';
            Logger.error('语音识别失败: $errorMsg');
            return '语音识别失败: $errorMsg';
          }
        } catch (e) {
          Logger.error('解析响应数据失败: $e');
          return '服务器响应格式错误';
        }
      } else {
        Logger.error('语音识别失败，状态码: ${response.statusCode}');
        Logger.error('错误响应: $responseData');
        
        // 尝试解析错误信息
        try {
          var errorData = json.decode(responseData);
          String errorMsg = errorData['detail'] ?? '未知错误';
          return '语音识别失败: $errorMsg';
        } catch (e) {
          return '语音识别失败，服务器错误 (${response.statusCode})';
        }
      }
    } catch (e) {
      Logger.error('语音识别异常: $e', error: e);
      if (e.toString().contains('TimeoutException')) {
        return '语音识别超时，请检查网络连接或服务器状态';
      } else if (e.toString().contains('SocketException')) {
        return '无法连接到语音识别服务器，请检查服务器地址和网络连接';
      } else {
        return '语音识别出错: ${e.toString()}';
      }
    }
  }
  
  /// 解析标签结果，提取语言、情感和事件信息
  static void _parseLabels(String labelResult) {
    try {
      // 解析格式如: <|zh|><|NEUTRAL|><|Speech|><|withitn|>你好，这是一段测试音频。
      RegExp langRegex = RegExp(r'<\|([a-z]{2})\|>');
      RegExp emotionRegex = RegExp(r'<\|([A-Z]+)\|>');
      
      var langMatch = langRegex.firstMatch(labelResult);
      var emotionMatch = emotionRegex.firstMatch(labelResult);
      
      if (langMatch != null) {
        String detectedLang = langMatch.group(1) ?? '';
        Logger.voice('检测到的语言: $detectedLang');
      }
      
      if (emotionMatch != null) {
        String emotion = emotionMatch.group(1) ?? '';
        Logger.voice('检测到的情感: $emotion');
      }
      
      // 检测音频事件
      List<String> events = [];
      RegExp allEventRegex = RegExp(r'<\|([A-Za-z]+)\|>');
      var matches = allEventRegex.allMatches(labelResult);
      for (var match in matches) {
        String event = match.group(1) ?? '';
        if (!['zh', 'en', 'NEUTRAL', 'HAPPY', 'SAD', 'ANGRY', 'Speech', 'withitn'].contains(event)) {
          events.add(event);
        }
      }
      
      if (events.isNotEmpty) {
        Logger.voice('检测到的音频事件: ${events.join(', ')}');
      }
    } catch (e) {
      Logger.error('解析标签结果失败: $e', error: e);
    }
  }
  
  /// 检查SenseVoice服务器连接状态
  /// 注意：由于远程服务器暂时不支持health接口，此方法暂时返回true
  static Future<bool> checkServerConnection() async {
    try {
      Logger.network('检查SenseVoice服务器连接: $_baseUrl');
      Logger.warning('注意：health接口暂时被屏蔽，默认返回连接正常');
      
      // TODO: 暂时屏蔽health接口调用，等服务器支持后再启用
      /*
      var response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      log('健康检查响应状态码: ${response.statusCode}');
      log('健康检查响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          var jsonData = json.decode(response.body);
          log('SenseVoice服务器状态: ${jsonData['status']}');
          log('SenseVoice版本: ${jsonData['version']}');
          log('使用模型: ${jsonData['model']}');
          return true;
        } catch (e) {
          log('解析健康检查响应失败: $e');
          return response.statusCode == 200;
        }
      } else {
        log('SenseVoice服务器健康检查失败，状态码: ${response.statusCode}');
        return false;
      }
      */
      
      // 暂时返回true，假设服务器连接正常
      return true;
    } catch (e) {
      Logger.error('SenseVoice服务器连接检查失败: $e', error: e);
      return false;
    }
  }
  
  /// 获取服务器信息
  /// 注意：由于远程服务器暂时不支持health接口，此方法暂时返回null
  static Future<Map<String, dynamic>?> getServerInfo() async {
    try {
      Logger.network('获取服务器信息: $_baseUrl');
      Logger.warning('注意：health接口暂时被屏蔽，返回null');
      
      // TODO: 暂时屏蔽health接口调用，等服务器支持后再启用
      /*
      var response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      */
      
      // 暂时返回null，表示无法获取服务器信息
      return null;
    } catch (e) {
      Logger.error('获取服务器信息失败: $e', error: e);
    }
    return null;
  }
}