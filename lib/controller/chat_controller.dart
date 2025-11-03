import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer';

import '../apis/apis.dart';
import '../helper/my_dialog.dart';
import '../model/message.dart';
import '../services/voice_service.dart';
import '../services/voice_config.dart';

class ChatController extends GetxController {
  final textC = TextEditingController();
  final scrollC = ScrollController();
  
  // 语音识别相关
  final SpeechToText _speechToText = SpeechToText();
  final RxBool isListening = false.obs;
  final RxBool speechEnabled = false.obs;
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
  }

  /// 加载语音配置
  void _loadVoiceConfig() {
    useRemoteVoice.value = VoiceConfig.useRemoteVoice;
    log('当前语音识别模式: ${useRemoteVoice.value ? "远程" : "本地"}');
  }

  /// 初始化语音识别
  Future<void> _initSpeech() async {
    try {
      // 首先检查设备是否支持语音识别
      bool available = await _speechToText.hasPermission;
      if (!available) {
        log('语音识别：设备不支持或权限不足');
        speechEnabled.value = false;
        return;
      }

      // 初始化语音识别服务
      speechEnabled.value = await _speechToText.initialize(
        onError: (error) {
          log('语音识别错误: ${error.errorMsg}');
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
          log('语音识别状态: $status');
          // 语音识别状态处理 - 更精确的状态管理
          if (status == 'done') {
            // 识别完成，但不立即停止监听状态，等待处理结果
            log('语音识别完成，等待处理结果...');
          } else if (status == 'notListening') {
            // 只有在用户主动停止或出现错误时才更新状态
            if (!isListening.value) {
              log('语音识别已停止');
            }
          } else if (status == 'listening') {
            log('正在监听语音输入...');
          }
        },
        debugLogging: true, // 开启调试日志
      );

      if (speechEnabled.value) {
        log('语音识别初始化成功');
        // 检查可用的语言
        var locales = await _speechToText.locales();
        log('支持的语言: ${locales.map((l) => l.localeId).join(', ')}');
      } else {
        log('语音识别初始化失败');
      }
    } catch (e) {
      log('语音识别初始化异常: $e');
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
      log('开始语音识别异常: $e');
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

      // 如果本地语音识别未初始化，尝试初始化（用于录音）
      if (!speechEnabled.value) {
        await _initSpeech();
        // 等待一下让初始化完成
        await Future.delayed(const Duration(milliseconds: 500));
        if (!speechEnabled.value) {
          isListening.value = false;
          recognizedText.value = '';
          MyDialog.info('无法初始化录音功能，请检查设备设置');
          return;
        }
      }

      // 清空识别文本，准备开始录音
      recognizedText.value = '请开始说话...';
      
      // 使用本地语音识别进行录音，但不使用其识别结果
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
          // 显示本地识别的临时结果，但最终会被远程识别结果替换
          recognizedText.value = result.recognizedWords.isEmpty 
              ? '正在监听...' 
              : result.recognizedWords;
          log('本地临时识别结果: ${result.recognizedWords}');
          
          if (result.finalResult) {
            // 本地识别完成，准备发送到远程服务器
            _processRemoteRecognition(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      log('远程语音识别启动异常: $e');
      isListening.value = false;
      recognizedText.value = '';
      MyDialog.info('启动远程语音识别失败: $e');
    }
  }

  /// 处理远程语音识别
  Future<void> _processRemoteRecognition(String localResult) async {
    try {
      isListening.value = false;
      
      // 这里应该保存录音文件并发送到远程服务器
      // 由于speech_to_text包不直接提供音频文件，我们使用本地识别结果作为备选
      // 在实际应用中，你可能需要使用其他录音插件来获取音频文件
      
      MyDialog.info('正在使用远程服务器识别语音...');
      
      // 模拟远程识别过程
      // 在实际实现中，这里应该是音频文件路径
      String audioPath = await _saveTemporaryAudio(localResult);
      
      if (audioPath.isNotEmpty) {
        String remoteResult = await VoiceService.speechToText(audioPath);
        
        if (remoteResult.isNotEmpty && !remoteResult.contains('失败') && !remoteResult.contains('错误')) {
          textC.text = remoteResult;
          recognizedText.value = remoteResult;
          log('远程语音识别成功: $remoteResult');
        } else {
          // 远程识别失败，使用本地结果作为备选
          textC.text = localResult;
          recognizedText.value = localResult;
          log('远程识别失败，使用本地结果: $localResult');
          MyDialog.info('远程识别失败，已使用本地识别结果');
        }
      } else {
        // 无法获取音频文件，使用本地结果
        textC.text = localResult;
        recognizedText.value = localResult;
      }
    } catch (e) {
      log('远程语音识别处理异常: $e');
      // 发生异常时使用本地结果
      textC.text = localResult;
      recognizedText.value = localResult;
      MyDialog.info('远程识别出错，已使用本地识别结果');
    }
  }

  /// 保存临时音频文件（模拟实现）
  /// 在实际应用中，你需要使用专门的录音插件来获取音频文件
  Future<String> _saveTemporaryAudio(String text) async {
    try {
      // 这是一个模拟实现，实际应用中需要真实的音频文件
      // 你可以使用 flutter_sound 或其他录音插件来获取音频文件
      log('模拟保存音频文件，文本内容: $text');
      return ''; // 返回空字符串表示无法获取音频文件
    } catch (e) {
      log('保存临时音频文件失败: $e');
      return '';
    }
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    if (isListening.value) {
      try {
        await _speechToText.stop();
        isListening.value = false;
        recognizedText.value = '';
        log('语音识别已手动停止');
      } catch (e) {
        log('停止语音识别异常: $e');
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
      
      log('=== 语音识别状态检查 ===');
      log('当前模式: ${useRemoteVoice.value ? "远程" : "本地"}');
      
      if (useRemoteVoice.value) {
        // 检查远程语音识别
        log('检查远程语音识别服务...');
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
      
      log('========================');
    } catch (e) {
      log('检查语音识别可用性异常: $e');
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
    super.onClose();
  }
}
