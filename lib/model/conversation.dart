/// 对话模型
class Conversation {
  final String id;
  final DateTime createdAt;
  final String question;
  final String answer;

  Conversation({
    required this.id,
    required this.createdAt,
    required this.question,
    required this.answer,
  });

  /// 从JSON创建对话对象
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      question: json['question'],
      answer: json['answer'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'question': question,
      'answer': answer,
    };
  }
}

/// 对话历史项
class ConversationHistoryItem {
  final String id;
  final DateTime createdAt;
  final String title; // 从问题中提取的标题
  final int messageCount; // 消息数量

  ConversationHistoryItem({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.messageCount,
  });

  factory ConversationHistoryItem.fromJson(Map<String, dynamic> json) {
    return ConversationHistoryItem(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      title: json['title'],
      messageCount: json['messageCount'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'messageCount': messageCount,
    };
  }
}