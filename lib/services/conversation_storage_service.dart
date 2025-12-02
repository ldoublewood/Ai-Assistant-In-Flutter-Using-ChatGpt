import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

import '../model/conversation.dart';
import '../utils/logger.dart';

/// 对话历史存储服务
class ConversationStorageService {
  static const String _conversationDir = 'conversations';
  static const String _historyFileName = 'conversation_history.json';
  
  /// 获取对话存储目录
  static Future<Directory> _getConversationDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final conversationDir = Directory('${appDir.path}/$_conversationDir');
    
    if (!await conversationDir.exists()) {
      await conversationDir.create(recursive: true);
      Logger.debug('创建对话存储目录: ${conversationDir.path}');
    }
    
    return conversationDir;
  }

  /// 生成唯一的对话ID
  /// 格式: YYYYMMDDHHMMSS + 6位随机数
  static String generateConversationId() {
    final now = DateTime.now();
    final dateTimeStr = now.year.toString().padLeft(4, '0') +
        now.month.toString().padLeft(2, '0') +
        now.day.toString().padLeft(2, '0') +
        now.hour.toString().padLeft(2, '0') +
        now.minute.toString().padLeft(2, '0') +
        now.second.toString().padLeft(2, '0');
    
    final random = Random();
    final randomStr = random.nextInt(999999).toString().padLeft(6, '0');
    
    return dateTimeStr + randomStr;
  }

  /// 保存问题
  static Future<void> saveQuestion(String conversationId, String question) async {
    try {
      final dir = await _getConversationDirectory();
      final questionFile = File('${dir.path}/${conversationId}_q.txt');
      
      await questionFile.writeAsString(question, encoding: utf8);
      Logger.debug('保存问题文件: ${questionFile.path}');
    } catch (e) {
      Logger.error('保存问题失败: $e', error: e);
      rethrow;
    }
  }

  /// 保存回答
  static Future<void> saveAnswer(String conversationId, String answer) async {
    try {
      final dir = await _getConversationDirectory();
      final answerFile = File('${dir.path}/${conversationId}_a.txt');
      
      await answerFile.writeAsString(answer, encoding: utf8);
      Logger.debug('保存回答文件: ${answerFile.path}');
      
      // 更新对话历史索引
      await _updateConversationHistory(conversationId);
    } catch (e) {
      Logger.error('保存回答失败: $e', error: e);
      rethrow;
    }
  }

  /// 读取问题
  static Future<String?> loadQuestion(String conversationId) async {
    try {
      final dir = await _getConversationDirectory();
      final questionFile = File('${dir.path}/${conversationId}_q.txt');
      
      if (await questionFile.exists()) {
        return await questionFile.readAsString(encoding: utf8);
      }
      return null;
    } catch (e) {
      Logger.error('读取问题失败: $e', error: e);
      return null;
    }
  }

  /// 读取回答
  static Future<String?> loadAnswer(String conversationId) async {
    try {
      final dir = await _getConversationDirectory();
      final answerFile = File('${dir.path}/${conversationId}_a.txt');
      
      if (await answerFile.exists()) {
        return await answerFile.readAsString(encoding: utf8);
      }
      return null;
    } catch (e) {
      Logger.error('读取回答失败: $e', error: e);
      return null;
    }
  }

  /// 加载完整对话
  static Future<Conversation?> loadConversation(String conversationId) async {
    try {
      final question = await loadQuestion(conversationId);
      final answer = await loadAnswer(conversationId);
      
      if (question != null && answer != null) {
        // 从对话ID中解析创建时间
        final createdAt = _parseCreatedTimeFromId(conversationId);
        
        return Conversation(
          id: conversationId,
          createdAt: createdAt,
          question: question,
          answer: answer,
        );
      }
      return null;
    } catch (e) {
      Logger.error('加载对话失败: $e', error: e);
      return null;
    }
  }

  /// 从对话ID解析创建时间
  static DateTime _parseCreatedTimeFromId(String conversationId) {
    try {
      // 提取前14位作为时间戳 YYYYMMDDHHMMSS
      final timeStr = conversationId.substring(0, 14);
      final year = int.parse(timeStr.substring(0, 4));
      final month = int.parse(timeStr.substring(4, 6));
      final day = int.parse(timeStr.substring(6, 8));
      final hour = int.parse(timeStr.substring(8, 10));
      final minute = int.parse(timeStr.substring(10, 12));
      final second = int.parse(timeStr.substring(12, 14));
      
      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      Logger.warning('解析对话ID时间失败: $e');
      return DateTime.now();
    }
  }

  /// 更新对话历史索引
  static Future<void> _updateConversationHistory(String conversationId) async {
    try {
      final dir = await _getConversationDirectory();
      final historyFile = File('${dir.path}/$_historyFileName');
      
      List<ConversationHistoryItem> history = [];
      
      // 读取现有历史
      if (await historyFile.exists()) {
        final content = await historyFile.readAsString(encoding: utf8);
        final List<dynamic> jsonList = json.decode(content);
        history = jsonList.map((json) => ConversationHistoryItem.fromJson(json)).toList();
      }
      
      // 检查是否已存在该对话
      final existingIndex = history.indexWhere((item) => item.id == conversationId);
      
      if (existingIndex == -1) {
        // 新对话，添加到历史
        final question = await loadQuestion(conversationId);
        final title = _generateTitle(question ?? '未知问题');
        final createdAt = _parseCreatedTimeFromId(conversationId);
        
        final newItem = ConversationHistoryItem(
          id: conversationId,
          createdAt: createdAt,
          title: title,
          messageCount: 1,
        );
        
        history.insert(0, newItem); // 插入到开头，最新的在前面
      }
      
      // 保存更新后的历史
      final jsonList = history.map((item) => item.toJson()).toList();
      await historyFile.writeAsString(json.encode(jsonList), encoding: utf8);
      
      Logger.debug('更新对话历史索引: $conversationId');
    } catch (e) {
      Logger.error('更新对话历史索引失败: $e', error: e);
    }
  }

  /// 生成对话标题（从问题中提取前30个字符）
  static String _generateTitle(String question) {
    final cleanQuestion = question.trim();
    if (cleanQuestion.length <= 30) {
      return cleanQuestion;
    }
    return '${cleanQuestion.substring(0, 30)}...';
  }

  /// 获取对话历史列表
  static Future<List<ConversationHistoryItem>> getConversationHistory() async {
    try {
      final dir = await _getConversationDirectory();
      final historyFile = File('${dir.path}/$_historyFileName');
      
      if (await historyFile.exists()) {
        final content = await historyFile.readAsString(encoding: utf8);
        final List<dynamic> jsonList = json.decode(content);
        return jsonList.map((json) => ConversationHistoryItem.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      Logger.error('获取对话历史失败: $e', error: e);
      return [];
    }
  }

  /// 删除对话
  static Future<bool> deleteConversation(String conversationId) async {
    try {
      final dir = await _getConversationDirectory();
      
      // 删除问题和回答文件
      final questionFile = File('${dir.path}/${conversationId}_q.txt');
      final answerFile = File('${dir.path}/${conversationId}_a.txt');
      
      if (await questionFile.exists()) {
        await questionFile.delete();
      }
      
      if (await answerFile.exists()) {
        await answerFile.delete();
      }
      
      // 从历史索引中移除
      await _removeFromHistory(conversationId);
      
      Logger.debug('删除对话: $conversationId');
      return true;
    } catch (e) {
      Logger.error('删除对话失败: $e', error: e);
      return false;
    }
  }

  /// 从历史索引中移除对话
  static Future<void> _removeFromHistory(String conversationId) async {
    try {
      final dir = await _getConversationDirectory();
      final historyFile = File('${dir.path}/$_historyFileName');
      
      if (await historyFile.exists()) {
        final content = await historyFile.readAsString(encoding: utf8);
        final List<dynamic> jsonList = json.decode(content);
        final history = jsonList.map((json) => ConversationHistoryItem.fromJson(json)).toList();
        
        // 移除指定对话
        history.removeWhere((item) => item.id == conversationId);
        
        // 保存更新后的历史
        final updatedJsonList = history.map((item) => item.toJson()).toList();
        await historyFile.writeAsString(json.encode(updatedJsonList), encoding: utf8);
      }
    } catch (e) {
      Logger.error('从历史索引中移除对话失败: $e', error: e);
    }
  }

  /// 清空所有对话历史
  static Future<bool> clearAllConversations() async {
    try {
      final dir = await _getConversationDirectory();
      
      // 删除所有对话文件
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
      
      Logger.debug('清空所有对话历史');
      return true;
    } catch (e) {
      Logger.error('清空对话历史失败: $e', error: e);
      return false;
    }
  }

  /// 获取存储统计信息
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final dir = await _getConversationDirectory();
      final history = await getConversationHistory();
      
      int totalFiles = 0;
      int totalSize = 0;
      
      await for (final entity in dir.list()) {
        if (entity is File) {
          totalFiles++;
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return {
        'conversationCount': history.length,
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'storagePath': dir.path,
      };
    } catch (e) {
      Logger.error('获取存储统计信息失败: $e', error: e);
      return {
        'conversationCount': 0,
        'totalFiles': 0,
        'totalSize': 0,
        'storagePath': '',
      };
    }
  }
}