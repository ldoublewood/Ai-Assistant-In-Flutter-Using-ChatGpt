import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/chat_controller.dart';
import '../services/voice_config.dart';
import '../services/audio_format_config.dart';
import '../utils/log_test.dart';
import '../utils/logger.dart';

/// 语音识别测试界面
class VoiceTestScreen extends StatefulWidget {
  const VoiceTestScreen({super.key});

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  String _testResult = '';
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音识别测试'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前配置信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前配置',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('使用远程语音识别: ${VoiceConfig.useRemoteVoice ? "是" : "否"}'),
                    Text('服务器地址: ${VoiceConfig.remoteVoiceUrl}'),
                    Text('识别语言: ${VoiceConfig.voiceLanguage}'),
                    Text('录音格式: ${AudioFormatConfig.getFormatName(AudioFormatConfig.audioFormat)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 测试按钮
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTesting ? null : _runDiagnostics,
                        icon: _isTesting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bug_report),
                        label: Text(_isTesting ? '测试中...' : '运行诊断'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _chatController.isListening.value ? null : _testVoiceInput,
                        icon: const Icon(Icons.mic),
                        label: const Text('测试语音输入'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testLogs,
                        icon: const Icon(Icons.terminal),
                        label: const Text('测试日志输出'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testVoiceLogs,
                        icon: const Icon(Icons.record_voice_over),
                        label: const Text('测试语音日志'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 测试结果
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '测试结果',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResult.isEmpty ? '点击上方按钮开始测试' : _testResult,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 语音识别状态
            Obx(() => _chatController.isListening.value
                ? Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _chatController.recognizedText.value.isEmpty 
                                ? '正在监听...' 
                                : _chatController.recognizedText.value,
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: _chatController.stopListening,
                          child: const Text('停止'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// 运行诊断测试
  Future<void> _runDiagnostics() async {
    setState(() {
      _isTesting = true;
      _testResult = '开始运行诊断测试...\n\n';
    });

    try {
      await _chatController.testVoiceRecognition();
      
      // 这里可以添加更多的测试逻辑
      setState(() {
        _testResult += '诊断测试完成，请查看控制台日志获取详细信息。\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '诊断测试失败: $e\n';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// 测试语音输入
  Future<void> _testVoiceInput() async {
    setState(() {
      _testResult += '\n开始语音输入测试...\n';
      _testResult += '请说话，系统将尝试识别您的语音。\n\n';
    });

    try {
      await _chatController.startListening();
    } catch (e) {
      setState(() {
        _testResult += '启动语音输入失败: $e\n';
      });
    }
  }

  /// 测试日志输出
  void _testLogs() {
    setState(() {
      _testResult += '\n=== 开始日志输出测试 ===\n';
      _testResult += '正在测试各种日志级别...\n';
      _testResult += '请查看logcat或控制台输出\n\n';
    });

    // 运行日志测试
    LogTest.testAllLogMethods();
    
    setState(() {
      _testResult += '日志测试完成！\n';
      _testResult += '如果配置正确，你应该能在以下位置看到日志：\n';
      _testResult += '• Android Studio的Logcat窗口\n';
      _testResult += '• 命令行: adb logcat | grep AiAssistant\n';
      _testResult += '• VS Code的Debug Console\n\n';
    });
  }

  /// 测试语音相关日志
  void _testVoiceLogs() {
    setState(() {
      _testResult += '\n=== 开始语音日志测试 ===\n';
      _testResult += '正在输出语音识别相关日志...\n\n';
    });

    // 运行语音日志测试
    LogTest.testVoiceLogs();
    LogTest.testNetworkLogs();
    
    Logger.info('语音日志测试完成，请检查logcat输出');
    
    setState(() {
      _testResult += '语音日志测试完成！\n';
      _testResult += '请在logcat中查找 [Voice] 和 [Network] 标签的日志\n\n';
    });
  }
}