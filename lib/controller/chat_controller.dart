import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../apis/apis.dart';
import '../helper/my_dialog.dart';
import '../model/message.dart';
import '../services/voice_service.dart';
import '../services/voice_config.dart';
import '../utils/logger.dart';

class ChatController extends GetxController {
  final textC = TextEditingController();
  final scrollC = ScrollController();
  
  // 语音识别相关
  final SpeechToText _speechToText = SpeechToText();
  final RxBool isListening = false.obs;
  final RxBool speechEnabled = false.obs;
  
  // 音频录制相关
  FlutterSoundRecorder? _audioRecorder;
  String? _currentAudioPath;
  final RxString recognizedText = ''.obs;
  final RxBool useRemoteVoice = false.obs;

  final list = <Message>[
    Message(msg: '你好！我是AI助手，有什么可以帮助你的吗？', msgType: MessageType.bot)
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _loadVoiceConfig();
    _initSpeech();
    _initAudioRecorder();
  }



  /// 测试语音识别功能（调试用）
  Future<void> testVoiceRecognition() async {
    Logger.debug('开始测试语音识别功能');
    
    // 检查配置
    Logger.config('当前配置: 使用远程语音识别=${VoiceConfig.useRemoteVoice}');
    Logger.config('服务器地址: ${VoiceConfig.remoteVoiceUrl}');
    Logger.config('识别语言: ${VoiceConfig.voiceLanguage}');
    
    // 检查服务器连接
    bool isConnected = await VoiceService.checkServerConnection();
    Logger.network('服务器连接状态: $isConnected');
    
    // 检查录音器状态
    Logger.debug('录音器状态: ${_audioRecorder != null ? "已初始化" : "未初始化"}');
    
    // 检查权限
    var micPermission = await Permission.microphone.status;
    Logger.debug('麦克风权限状态: $micPermission');
  }

  /// 加载语音配置
  void _loadVoiceConfig() {
    useRemoteVoice.value = VoiceConfig.useRemoteVoice;
    Logger.config('当前语音识别模式: ${useRemoteVoice.value ? "远程" : "本地"}');
  }

  /// 重新加载语音配置（公共方法）
  void reloadVoiceConfig() {
    _loadVoiceConfig();
  }

  /// 初始化音频录制器
  Future<void> _initAudioRecorder() async {
    try {
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();
      Logger.debug('音频录制器初始化成功');
    } catch (e) {
      Logger.error('音频录制器初始化失败: $e', error: e);
      _audioRecorder = null;
    }
  }

  /// 初始化语音识别
  Future<void> _initSpeech() async {
    try {
      // 首先检查设备是否支持语音识别
      bool available = await _speechToText.hasPermission;
      if (!available) {
        Logger.warning('语音识别：设备不支持或权限不足');
        speechEnabled.value = false;
        return;
      }

      // 初始化语音识别服务
      speechEnabled.value = await _speechToText.initialize(
        onError: (error) {
          Logger.error('语音识别错误: ${error.errorMsg}');
          // 只有在真正出现严重错误时才停止监听
          if (error.errorMsg.contains('permission') || 
              error.errorMsg.contains('not available') ||
              error.errorMsg.contains('initialization')) {
            isListening.value = false;
            recognizedText.value = '';
            // 根据错误类型给出具体提示
            if (error.errorMsg.contains('network')) {
              MyDialog.info('网络连接异常，请检查网络设置');
            } else if (error.errorMsg.contains('permission')) {
              MyDialog.info('麦克风权限被拒绝，请在设置中开启权限');
            } else {
              MyDialog.info('语音识别出现错误: ${error.errorMsg}');
            }
          }
        },
        onStatus: (status) {
          Logger.voice('语音识别状态: $status');
          // 语音识别状态处理 - 更精确的状态管理
          if (status == 'done') {
            // 识别完成，但不立即停止监听状态，等待处理结果
            Logger.voice('语音识别完成，等待处理结果...');
          } else if (status == 'notListening') {
            // 只有在用户主动停止或出现错误时才更新状态
            if (!isListening.value) {
              Logger.voice('语音识别已停止');
            }
          } else if (status == 'listening') {
            Logger.voice('正在监听语音输入...');
          }
        },
        debugLogging: true, // 开启调试日志
      );

      if (speechEnabled.value) {
        Logger.voice('语音识别初始化成功');
        // 检查可用的语言
        var locales = await _speechToText.locales();
        Logger.voice('支持的语言: ${locales.map((l) => l.localeId).join(', ')}');
      } else {
        Logger.error('语音识别初始化失败');
      }
    } catch (e) {
      Logger.error('语音识别初始化异常: $e', error: e);
      speechEnabled.value = false;
    }
  }

  /// 开始语音识别
  Future<void> startListening() async {
    // 防止重复启动
    if (isListening.value) {
      return;
    }

    try {
      // 重新加载配置
      _loadVoiceConfig();
      
      // 先设置为正在监听状态，给用户即时反馈
      isListening.value = true;
      
      // 检查麦克风权限
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        isListening.value = false;
        MyDialog.info('需要麦克风权限才能使用语音输入功能，请在设置中开启麦克风权限');
        return;
      }

      if (useRemoteVoice.value) {
        // 使用远程语音识别
        await _startRemoteListening();
      } else {
        // 使用本地语音识别（已被屏蔽）
        isListening.value = false;
        MyDialog.info('本地语音识别功能已禁用，请在设置中启用远程语音识别');
        return;
      }
    } catch (e) {
      Logger.error('开始语音识别异常: $e', error: e);
      isListening.value = false;
      MyDialog.info('启动语音识别失败，请重试');
    }
  }

  /// 开始远程语音识别
  Future<void> _startRemoteListening() async {
    try {
      // 显示正在检查服务器连接的提示
      recognizedText.value = '正在检查服务器连接...';
      
      // 首先检查远程服务器连接
      bool isConnected = await VoiceService.checkServerConnection();
      if (!isConnected) {
        isListening.value = false;
        recognizedText.value = '';
        MyDialog.info('无法连接到远程语音识别服务器，请检查设置');
        return;
      }

      // 显示正在初始化录音功能的提示
      recognizedText.value = '正在初始化录音功能...';

      // 检查录音器是否已初始化
      if (_audioRecorder == null) {
        await _initAudioRecorder();
        if (_audioRecorder == null) {
          isListening.value = false;
          recognizedText.value = '';
          MyDialog.info('无法初始化录音功能，请检查设备设置');
          return;
        }
      }

      // 开始录音
      try {
        await _startAudioRecording();
        Logger.voice('音频录制已启动，等待语音输入');
      } catch (e) {
        isListening.value = false;
        recognizedText.value = '';
        MyDialog.info('启动录音失败: $e');
        return;
      }
      
      // 清空识别文本，准备开始录音
      recognizedText.value = '请开始说话...';
      
      // 使用本地语音识别提供实时反馈
      if (speechEnabled.value) {
        var locales = await _speechToText.locales();
        String localeId = 'zh_CN';
        
        var chineseLocale = locales.isNotEmpty 
            ? locales.firstWhere(
                (locale) => locale.localeId.startsWith('zh'),
                orElse: () => locales.first,
              )
            : null;
        
        if (chineseLocale != null) {
          localeId = chineseLocale.localeId;
        }
        
        await _speechToText.listen(
          onResult: (result) {
            // 显示本地识别的临时结果作为实时反馈
            recognizedText.value = result.recognizedWords.isEmpty 
                ? '正在监听...' 
                : result.recognizedWords;
            Logger.voice('本地临时识别结果: ${result.recognizedWords}');
            
            if (result.finalResult) {
              // 本地识别完成，停止录音并处理远程识别
              _stopAudioRecordingAndProcess();
            }
          },
          localeId: localeId,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        );
      } else {
        // 如果本地语音识别不可用，设置定时器自动停止录音
        Future.delayed(const Duration(seconds: 10), () {
          if (isListening.value) {
            _stopAudioRecordingAndProcess();
          }
        });
      }
    } catch (e) {
      Logger.error('远程语音识别启动异常: $e', error: e);
      isListening.value = false;
      recognizedText.value = '';
      MyDialog.info('启动远程语音识别失败: $e');
    }
  }

  /// 开始音频录制
  Future<void> _startAudioRecording() async {
    try {
      if (_audioRecorder == null) {
        throw Exception('音频录制器未初始化');
      }
      
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentAudioPath = '${tempDir.path}/voice_$timestamp.wav';
      
      Logger.voice('准备开始录音，文件路径: $_currentAudioPath');
      
      // 开始录音
      await _audioRecorder!.startRecorder(
        toFile: _currentAudioPath,
        codec: Codec.pcm16WAV, // 使用WAV格式，兼容性更好
      );
      
      Logger.voice('录音已开始，文件路径: $_currentAudioPath');
    } catch (e) {
      Logger.error('开始录音失败: $e', error: e);
      _currentAudioPath = null;
      rethrow;
    }
  }

  /// 停止音频录制并处理远程识别
  Future<void> _stopAudioRecordingAndProcess() async {
    try {
      isListening.value = false;
      
      // 停止录音
      await _audioRecorder!.stopRecorder();
      Logger.voice('录音已停止，文件路径: $_currentAudioPath');
      
      if (_currentAudioPath != null && File(_currentAudioPath!).existsSync()) {
        recognizedText.value = '正在使用远程服务器识别语音...';
        
        // 发送音频文件到远程服务器进行识别
        String remoteResult = await VoiceService.speechToText(_currentAudioPath!);
        
        if (remoteResult.isNotEmpty && 
            !remoteResult.contains('失败') && 
            !remoteResult.contains('错误') &&
            !remoteResult.contains('未识别到语音内容')) {
          textC.text = remoteResult;
          recognizedText.value = remoteResult;
          Logger.voice('远程语音识别成功: $remoteResult');
        } else {
          recognizedText.value = '语音识别失败，请重试';
          Logger.error('远程语音识别失败: $remoteResult');
          MyDialog.info('语音识别失败: $remoteResult');
        }
        
        // 清理临时音频文件
        try {
          await File(_currentAudioPath!).delete();
          Logger.debug('临时音频文件已删除');
        } catch (e) {
          Logger.warning('删除临时音频文件失败: $e', error: e);
        }
      } else {
        recognizedText.value = '录音文件不存在';
        MyDialog.info('录音失败，请重试');
      }
    } catch (e) {
      Logger.error('停止录音和处理识别异常: $e', error: e);
      recognizedText.value = '';
      MyDialog.info('语音识别处理失败: $e');
    } finally {
      _currentAudioPath = null;
    }
  }



  /// 停止语音识别
  Future<void> stopListening() async {
    if (isListening.value) {
      try {
        await _speechToText.stop();
        
        // 如果正在使用远程识别且正在录音，停止录音并处理
        if (useRemoteVoice.value && _audioRecorder != null && _audioRecorder!.isRecording) {
          await _stopAudioRecordingAndProcess();
        } else {
          isListening.value = false;
          recognizedText.value = '';
        }
        
        Logger.voice('语音识别已手动停止');
      } catch (e) {
        Logger.error('停止语音识别异常: $e', error: e);
        isListening.value = false;
        recognizedText.value = '';
      }
    }
  }

  /// 发送问题
  Future<void> askQuestion() async {
    if (textC.text.trim().isNotEmpty) {
      // 用户消息
      list.add(Message(msg: textC.text, msgType: MessageType.user));
      list.add(Message(msg: '', msgType: MessageType.bot));
      _scrollDown();

      final question = textC.text;
      textC.text = '';

      try {
        final res = await APIs.getAnswer(question);
        
        // AI回复
        list.removeLast();
        list.add(Message(msg: res, msgType: MessageType.bot));
        _scrollDown();
      } catch (e) {
        list.removeLast();
        list.add(Message(msg: '抱歉，出现了一些问题，请稍后重试。', msgType: MessageType.bot));
        _scrollDown();
      }
    } else {
      MyDialog.info('请输入问题或使用语音输入！');
    }
  }

  /// 滚动到底部
  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollC.hasClients) {
        scrollC.animateTo(
          scrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    });
  }

  /// 检查语音识别可用性
  Future<void> checkSpeechAvailability() async {
    try {
      _loadVoiceConfig();
      
      Logger.debug('=== 语音识别状态检查 ===');
      Logger.debug('当前模式: ${useRemoteVoice.value ? "远程" : "本地"}');
      
      if (useRemoteVoice.value) {
        // 检查远程语音识别
        Logger.debug('检查远程语音识别服务...');
        bool isConnected = await VoiceService.checkServerConnection();
        
        if (isConnected) {
          var serverInfo = await VoiceService.getServerInfo();
          var configInfo = VoiceService.getConfigInfo();
          
          String infoText = '远程语音识别服务正常\n\n';
          infoText += '服务器地址: ${configInfo['remoteVoiceUrl']}\n';
          infoText += '识别语言: ${VoiceConfig.getLanguageName(configInfo['voiceLanguage'])}\n';
          
          if (serverInfo != null) {
            infoText += '服务器状态: ${serverInfo['status']}\n';
            infoText += '服务器版本: ${serverInfo['version']}\n';
            infoText += '使用模型: ${serverInfo['model']}';
          } else {
            infoText += '注意: 服务器详细信息暂时不可用\n(health接口暂时被屏蔽)';
          }
          
          MyDialog.info(infoText);
        } else {
          MyDialog.error('无法连接到远程语音识别服务器\n\n请检查:\n• 服务器地址是否正确\n• 网络连接是否正常\n• SenseVoice服务是否运行');
        }
      } else {
        // 本地语音识别已被禁用
        MyDialog.info('本地语音识别功能已被禁用\n\n请在设置中启用远程语音识别功能');
      }
      
      Logger.debug('========================');
    } catch (e) {
      Logger.error('检查语音识别可用性异常: $e', error: e);
      MyDialog.error('检查语音识别功能时出错: $e');
    }
  }

  /// 打开语音设置
  void openVoiceSettings() {
    Get.toNamed('/voice-settings');
  }

  @override
  void onClose() {
    textC.dispose();
    scrollC.dispose();
    _speechToText.cancel();
    _audioRecorder?.closeRecorder();
    super.onClose();
  }
}
