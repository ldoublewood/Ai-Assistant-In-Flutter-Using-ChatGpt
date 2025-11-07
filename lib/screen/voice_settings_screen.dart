import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/voice_config.dart';
import '../services/remote_voice_service.dart';
import '../services/audio_format_config.dart';
import '../helper/my_dialog.dart';
import '../controller/chat_controller.dart';
import 'voice_test_screen.dart';

/// 语音设置界面
class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final _urlController = TextEditingController();
  bool _useRemoteVoice = false;
  String _selectedLanguage = 'auto';
  String _selectedAudioFormat = 'aac';
  bool _isTestingConnection = false;
  Map<String, dynamic>? _serverInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载当前设置
  void _loadSettings() {
    setState(() {
      _useRemoteVoice = VoiceConfig.useRemoteVoice;
      _urlController.text = VoiceConfig.remoteVoiceUrl;
      _selectedLanguage = VoiceConfig.voiceLanguage;
      _selectedAudioFormat = AudioFormatConfig.audioFormat;
    });
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      await VoiceConfig.setUseRemoteVoice(_useRemoteVoice);
      await VoiceConfig.setRemoteVoiceUrl(_urlController.text.trim());
      await VoiceConfig.setVoiceLanguage(_selectedLanguage);
      await AudioFormatConfig.setAudioFormat(_selectedAudioFormat);
      
      // 通知聊天控制器重新加载配置
      try {
        final chatController = Get.find<ChatController>();
        chatController.reloadVoiceConfig();
      } catch (e) {
        // 如果聊天控制器不存在，忽略错误
      }
      
      MyDialog.success('设置保存成功');
    } catch (e) {
      MyDialog.error('保存设置失败: $e');
    }
  }

  /// 测试服务器连接
  Future<void> _testConnection() async {
    if (!_useRemoteVoice) {
      MyDialog.info('请先启用远程语音识别');
      return;
    }

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      MyDialog.info('请输入服务器地址');
      return;
    }

    if (!VoiceConfig.isValidUrl(url)) {
      MyDialog.info('请输入有效的服务器地址');
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _serverInfo = null;
    });

    try {
      RemoteVoiceService.setBaseUrl(url);
      bool isConnected = await RemoteVoiceService.checkServerConnection();
      
      if (isConnected) {
        _serverInfo = await RemoteVoiceService.getServerInfo();
        if (_serverInfo != null) {
          MyDialog.success('服务器连接成功');
        } else {
          MyDialog.success('服务器连接成功\n(详细信息暂时不可用)');
        }
      } else {
        MyDialog.error('无法连接到服务器，请检查地址和网络');
      }
    } catch (e) {
      MyDialog.error('连接测试失败: $e');
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  /// 重置为默认设置
  Future<void> _resetToDefault() async {
    try {
      await VoiceConfig.resetToDefault();
      _loadSettings();
      setState(() {
        _serverInfo = null;
      });
      MyDialog.success('已重置为默认设置');
    } catch (e) {
      MyDialog.error('重置失败: $e');
    }
  }

  /// 打开测试界面
  void _openTestScreen() {
    Get.to(() => const VoiceTestScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音识别设置'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: '保存设置',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 识别模式选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '识别模式',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('使用远程语音识别'),
                      subtitle: Text(_useRemoteVoice 
                          ? '基于SenseVoice的远程识别服务' 
                          : '本地语音识别已禁用'),
                      value: _useRemoteVoice,
                      onChanged: (value) {
                        setState(() {
                          _useRemoteVoice = value;
                          if (!value) {
                            _serverInfo = null;
                          }
                        });
                      },
                    ),
                    if (!_useRemoteVoice)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '本地语音识别功能已被禁用，请启用远程识别',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 远程服务器设置
            if (_useRemoteVoice) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '远程服务器设置',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: '服务器地址',
                          hintText: 'http://localhost:8000',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isTestingConnection ? null : _testConnection,
                              icon: _isTestingConnection 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.wifi_find),
                              label: Text(_isTestingConnection ? '测试中...' : '测试连接'),
                            ),
                          ),
                        ],
                      ),
                      
                      // 服务器信息显示
                      if (_serverInfo != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '服务器连接正常',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('状态: ${_serverInfo!['status'] ?? 'unknown'}'),
                              Text('版本: ${_serverInfo!['version'] ?? 'unknown'}'),
                              Text('模型: ${_serverInfo!['model'] ?? 'unknown'}'),
                            ],
                          ),
                        ),
                      ] else if (_isTestingConnection == false && _useRemoteVoice) ...[
                        // 当连接测试完成但无法获取服务器信息时显示
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '服务器详细信息不可用',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('health接口暂时被屏蔽，但语音识别功能正常'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 音频格式设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '录音格式',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAudioFormat,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.audiotrack),
                        ),
                        items: AudioFormatConfig.supportedFormats.map((format) {
                          return DropdownMenuItem<String>(
                            value: format['code'],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  format['name']!,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  format['description']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedAudioFormat = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '格式说明',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• AAC格式：高质量压缩，文件小，适合大多数设备\n'
                              '• WAV格式：无损音质，文件大，兼容性最好\n'
                              '• PCM转WAV：适用于华为等不支持直接WAV录制的设备',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 语言设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '识别语言',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.language),
                        ),
                        items: VoiceConfig.supportedLanguages.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['code'],
                            child: Text(lang['name']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefault,
                    icon: const Icon(Icons.restore),
                    label: const Text('重置默认'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openTestScreen,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('测试功能'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('保存设置'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 使用说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用说明',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 远程语音识别基于SenseVoice-Api项目\n'
                      '• 默认服务器地址为 http://localhost:8000\n'
                      '• 请确保SenseVoice服务正在运行\n'
                      '• 支持多种音频格式：wav, mp3, flac, m4a等\n'
                      '• 建议音频文件大小不超过30MB\n'
                      '• 支持多语言识别、情感识别和音频事件检测',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}