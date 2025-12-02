import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/chat_controller.dart';
import '../../helper/global.dart';
import '../../widget/message_card.dart';
import '../conversation_history_screen.dart';

class ChatBotFeature extends StatefulWidget {
  const ChatBotFeature({super.key});

  @override
  State<ChatBotFeature> createState() => _ChatBotFeatureState();
}

class _ChatBotFeatureState extends State<ChatBotFeature> {
  final _c = Get.find<ChatController>();
  final _isDarkMode = Get.isDarkMode.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 应用栏
      appBar: AppBar(
        title: const Text('AI 智能助手'),
        centerTitle: true,
        elevation: 1,
        actions: [
          // 对话历史按钮
          IconButton(
            onPressed: () => Get.to(() => const ConversationHistoryScreen()),
            icon: const Icon(Icons.history, size: 20),
            tooltip: '对话历史',
          ),
          // 新对话按钮
          IconButton(
            onPressed: () => _c.startNewConversation(),
            icon: const Icon(Icons.add_comment, size: 20),
            tooltip: '新对话',
          ),
          // 更多选项菜单
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ai_settings',
                child: Row(
                  children: [
                    Icon(Icons.psychology, size: 18),
                    SizedBox(width: 8),
                    Text('AI提供商设置'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'voice_settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_voice, size: 18),
                    SizedBox(width: 8),
                    Text('语音设置'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'voice_test',
                child: Row(
                  children: [
                    Icon(Icons.mic_external_on, size: 18),
                    SizedBox(width: 8),
                    Text('检查语音功能'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'theme_toggle',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6, size: 18),
                    SizedBox(width: 8),
                    Text('切换主题'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // 输入区域
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // 语音输入按钮
              Obx(() => GestureDetector(
                onTap: () {
                  if (_c.isListening.value) {
                    _c.stopListening();
                  } else {
                    _c.startListening();
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _c.isListening.value 
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _c.isListening.value ? Colors.red : Colors.blue,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _c.isListening.value ? Icons.stop : Icons.mic_none,
                    color: _c.isListening.value ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                ),
              )),

              const SizedBox(width: 12),

              // 文本输入框
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextFormField(
                    controller: _c.textC,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _c.askQuestion(),
                    decoration: InputDecoration(
                      hintText: '输入消息或点击语音按钮输入...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 发送按钮
              GestureDetector(
                onTap: _c.askQuestion,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 消息列表
      body: Obx(
        () => Column(
          children: [
            // 语音识别状态提示
            if (_c.isListening.value)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '正在听取语音输入...',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // 显示识别的文本
                    if (_c.recognizedText.value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _c.recognizedText.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            
            // 消息列表
            Expanded(
              child: _c.list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '开始与AI助手对话吧！',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      controller: _c.scrollC,
                      padding: EdgeInsets.only(
                        top: mq.height * .02,
                        bottom: 16,
                        left: 8,
                        right: 8,
                      ),
                      itemCount: _c.list.length,
                      itemBuilder: (context, index) {
                        return MessageCard(message: _c.list[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(String value) {
    switch (value) {
      case 'ai_settings':
        _c.openAIProviderSettings();
        break;
      case 'voice_settings':
        _c.openVoiceSettings();
        break;
      case 'voice_test':
        _c.checkSpeechAvailability();
        break;
      case 'theme_toggle':
        Get.changeThemeMode(
          _isDarkMode.value ? ThemeMode.light : ThemeMode.dark,
        );
        _isDarkMode.value = !_isDarkMode.value;
        break;
    }
  }
}
