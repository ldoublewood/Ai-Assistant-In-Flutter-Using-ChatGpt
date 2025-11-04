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
    
    // 测试录音功能
    await _testRecordingCapability();
  }

  /// 测试录音能力
  Future<void> _testRecordingCapability() async {
    Logger.debug('=== 开始录音能力测试 ===');
    
    try {
      // 重新初始化录音器
      if (_audioRecorder != null) {
        await _audioRecorder!.closeRecorder();
      }
      await _initAudioRecorder();
      
      if (_audioRecorder == null) {
        Logger.error('录音器初始化失败');
        return;
      }
      
      // 创建测试录音文件
      final tempDir = await getTemporaryDirectory();
      final testPath = '${tempDir.path}/test_recording.wav';
      
      Logger.debug('开始测试录音，文件路径: $testPath');
      
      // 开始录音
      await _audioRecorder!.startRecorder(
        toFile: testPath,
        codec: Codec.pcm16WAV,
      );
      
      Logger.debug('录音器状态: ${_audioRecorder!.isRecording ? "正在录音" : "未录音"}');
      
      // 录音2秒
      await Future.delayed(const Duration(seconds: 2));
      
      // 停止录音
      await _audioRecorder!.stopRecorder();
      
      // 检查文件
      final testFile = File(testPath);
      if (await testFile.exists()) {
        final fileSize = await testFile.length();
        Logger.debug('测试录音文件大小: ${fileSize}字节');
        
        if (fileSize > 44) {
          Logger.debug('录音测试成功 - 文件包含音频数据');
        } else {
          Logger.error('录音测试失败 - 文件只包含头部，无音频数据');
        }
        
        // 清理测试文件
        await testFile.delete();
      } else {
        Logger.error('录音测试失败 - 文件未创建');
      }
      
    } catch (e) {
      Logger.error('录音能力测试异常: $e', error: e);
    }
    
    Logger.debug('=== 录音能力测试完成 ===');
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
      
      // 检查并请求录音权限
      var status = await Permission.microphone.status;
      Logger.debug('当前麦克风权限状态: $status');
      
      if (status != PermissionStatus.granted) {
        Logger.debug('请求麦克风权限...');
        status = await Permission.microphone.request();
        Logger.debug('权限请求结果: $status');
        
        if (status != PermissionStatus.granted) {
          Logger.error('麦克风权限被拒绝');
          throw Exception('麦克风权限被拒绝');
        }
      }
      
      Logger.debug('开始打开录音器...');
      await _audioRecorder!.openRecorder();
      
      // 检查录音器是否成功打开
      if (_audioRecorder!.isStopped) {
        Logger.debug('录音器已成功打开');
      } else {
        Logger.warning('录音器状态异常');
      }
      
      Logger.debug('音频录制器初始化成功');
      Logger.debug('录音器状态: ${_audioRecorder!.isRecording ? "正在录音" : "空闲"}');
    } catch (e) {
      Logger.error('音频录制器初始化失败: $e', error: e);
      _audioRecorder = null;
      rethrow; // 重新抛出异常，让调用者知道初始化失败
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

  // 录音开始时间
  DateTime? _recordingStartTime;

  /// 验证WAV文件格式
  Future<bool> _validateWavFile(File audioFile) async {
    try {
      final bytes = await audioFile.readAsBytes();
      if (bytes.length < 44) {
        Logger.error('WAV文件太小，可能不是有效的WAV文件');
        return false;
      }
      
      // 检查是否只有文件头没有音频数据
      if (bytes.length == 44) {
        Logger.error('WAV文件只包含文件头，没有音频数据 - 录音可能失败');
        return false;
      }
      
      // 检查WAV文件头
      // RIFF标识符 (0-3字节)
      String riffHeader = String.fromCharCodes(bytes.sublist(0, 4));
      if (riffHeader != 'RIFF') {
        Logger.error('WAV文件缺少RIFF头: $riffHeader');
        return false;
      }
      
      // WAVE标识符 (8-11字节)
      String waveHeader = String.fromCharCodes(bytes.sublist(8, 12));
      if (waveHeader != 'WAVE') {
        Logger.error('WAV文件缺少WAVE头: $waveHeader');
        return false;
      }
      
      // fmt标识符 (12-15字节)
      String fmtHeader = String.fromCharCodes(bytes.sublist(12, 16));
      if (fmtHeader != 'fmt ') {
        Logger.error('WAV文件缺少fmt头: $fmtHeader');
        return false;
      }
      
      Logger.voice('WAV文件格式验证通过，包含 ${bytes.length - 44} 字节音频数据');
      return true;
    } catch (e) {
      Logger.error('WAV文件验证异常: $e', error: e);
      return false;
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
      
      // 记录录音开始时间
      _recordingStartTime = DateTime.now();
      
      // 尝试不同的录音配置
      Logger.voice('尝试使用WAV格式录音...');
      try {
        await _audioRecorder!.startRecorder(
          toFile: _currentAudioPath,
          codec: Codec.pcm16WAV,
        );
      } catch (e) {
        Logger.warning('WAV格式录音失败，尝试AAC格式: $e');
        // 如果WAV失败，尝试AAC格式
        _currentAudioPath = _currentAudioPath!.replaceAll('.wav', '.aac');
        await _audioRecorder!.startRecorder(
          toFile: _currentAudioPath,
          codec: Codec.aacADTS,
        );
      }
      
      // 等待一小段时间确保录音真正开始
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 检查录音状态
      bool isRecording = _audioRecorder!.isRecording;
      Logger.voice('录音已开始，文件路径: $_currentAudioPath');
      Logger.voice('录音器状态检查: ${isRecording ? "正在录音" : "录音未启动"}');
      
      if (!isRecording) {
        throw Exception('录音器启动失败，状态检查显示未在录音');
      }
    } catch (e) {
      Logger.error('开始录音失败: $e', error: e);
      _currentAudioPath = null;
      _recordingStartTime = null;
      rethrow;
    }
  }

  /// 停止音频录制并处理远程识别
  Future<void> _stopAudioRecordingAndProcess() async {
    try {
      isListening.value = false;
      
      // 停止录音
      await _audioRecorder!.stopRecorder();
      
      // 计算录音时长
      Duration? recordingDuration;
      if (_recordingStartTime != null) {
        recordingDuration = DateTime.now().difference(_recordingStartTime!);
        Logger.voice('录音时长: ${recordingDuration.inMilliseconds}毫秒');
      }
      
      Logger.voice('录音已停止，文件路径: $_currentAudioPath');
      
      if (_currentAudioPath != null && File(_currentAudioPath!).existsSync()) {
        // 检查录音文件大小
        final audioFile = File(_currentAudioPath!);
        final fileSize = await audioFile.length();
        Logger.voice('录音文件大小: ${fileSize}字节 (${(fileSize / 1024).toStringAsFixed(2)}KB)');
        
        if (fileSize == 0) {
          recognizedText.value = '录音文件为空，请重试';
          Logger.error('录音文件为空: $_currentAudioPath');
          MyDialog.info('录音失败：文件为空，请重试');
          return;
        }
        
        // 检查录音时长是否太短
        if (recordingDuration != null && recordingDuration.inMilliseconds < 500) {
          recognizedText.value = '录音时间太短，请重试';
          Logger.warning('录音时间太短: ${recordingDuration.inMilliseconds}毫秒');
          MyDialog.info('录音时间太短，请说话时间长一些');
          return;
        }
        
        // 验证WAV文件格式
        if (!await _validateWavFile(audioFile)) {
          recognizedText.value = '音频文件格式无效，请重试';
          Logger.error('音频文件格式验证失败: $_currentAudioPath');
          MyDialog.info('音频文件格式无效，请重试');
          return;
        }
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
      _recordingStartTime = null;
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
