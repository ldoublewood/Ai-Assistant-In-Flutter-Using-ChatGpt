import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../apis/apis.dart';
import '../helper/my_dialog.dart';
import '../model/message.dart';

class ChatController extends GetxController {
  final textC = TextEditingController();
  final scrollC = ScrollController();
  
  // 语音识别相关
  final SpeechToText _speechToText = SpeechToText();
  final RxBool isListening = false.obs;
  final RxBool speechEnabled = false.obs;
  final RxString recognizedText = ''.obs;

  final list = <Message>[
    Message(msg: '你好！我是AI助手，有什么可以帮助你的吗？', msgType: MessageType.bot)
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _initSpeech();
  }

  /// 初始化语音识别
  void _initSpeech() async {
    try {
      // 首先检查设备是否支持语音识别
      bool available = await _speechToText.hasPermission;
      if (!available) {
        print('语音识别：设备不支持或权限不足');
        speechEnabled.value = false;
        return;
      }

      // 初始化语音识别服务
      speechEnabled.value = await _speechToText.initialize(
        onError: (error) {
          print('语音识别错误: ${error.errorMsg}');
          isListening.value = false;
          // 根据错误类型给出具体提示
          if (error.errorMsg.contains('network')) {
            MyDialog.info('网络连接异常，请检查网络设置');
          } else if (error.errorMsg.contains('permission')) {
            MyDialog.info('麦克风权限被拒绝，请在设置中开启权限');
          }
        },
        onStatus: (status) {
          print('语音识别状态: $status');
          // 语音识别状态处理
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
          }
        },
        debugLogging: true, // 开启调试日志
      );

      if (speechEnabled.value) {
        print('语音识别初始化成功');
        // 检查可用的语言
        var locales = await _speechToText.locales();
        print('支持的语言: ${locales.map((l) => l.localeId).join(', ')}');
      } else {
        print('语音识别初始化失败');
      }
    } catch (e) {
      print('语音识别初始化异常: $e');
      speechEnabled.value = false;
    }
  }

  /// 开始语音识别
  Future<void> startListening() async {
    try {
      // 检查麦克风权限
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        MyDialog.info('需要麦克风权限才能使用语音输入功能，请在设置中开启麦克风权限');
        return;
      }

      // 如果语音识别未初始化成功，尝试重新初始化
      if (!speechEnabled.value) {
        print('语音识别未启用，尝试重新初始化...');
        await _initSpeech();
        
        if (!speechEnabled.value) {
          // 检查具体原因
          bool hasPermission = await _speechToText.hasPermission;
          if (!hasPermission) {
            MyDialog.info('设备不支持语音识别或权限不足，请检查设备设置');
          } else {
            MyDialog.info('语音识别服务不可用，请确保设备已安装语音识别服务');
          }
          return;
        }
      }

      if (!isListening.value) {
        isListening.value = true;
        recognizedText.value = '';
        
        // 检查可用的语言并选择合适的
        var locales = await _speechToText.locales();
        String localeId = 'zh_CN';
        
        // 查找中文语言包
        var chineseLocale = locales.firstWhere(
          (locale) => locale.localeId.startsWith('zh'),
          orElse: () => locales.isNotEmpty ? locales.first : null,
        );
        
        if (chineseLocale != null) {
          localeId = chineseLocale.localeId;
          print('使用语言: $localeId');
        }
        
        await _speechToText.listen(
          onResult: (result) {
            recognizedText.value = result.recognizedWords;
            print('识别结果: ${result.recognizedWords}');
            if (result.finalResult) {
              textC.text = recognizedText.value;
              isListening.value = false;
            }
          },
          localeId: localeId,
          listenFor: const Duration(seconds: 30), // 最长监听30秒
          pauseFor: const Duration(seconds: 3),   // 暂停3秒后停止
        );
      }
    } catch (e) {
      print('开始语音识别异常: $e');
      isListening.value = false;
      MyDialog.info('启动语音识别失败，请重试');
    }
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    if (isListening.value) {
      await _speechToText.stop();
      isListening.value = false;
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
      bool available = await _speechToText.hasPermission;
      var locales = await _speechToText.locales();
      
      print('=== 语音识别状态检查 ===');
      print('权限状态: $available');
      print('初始化状态: ${speechEnabled.value}');
      print('支持的语言数量: ${locales.length}');
      print('支持的语言: ${locales.map((l) => '${l.name}(${l.localeId})').join(', ')}');
      print('========================');
      
      if (!available) {
        MyDialog.info('设备不支持语音识别功能');
      } else if (locales.isEmpty) {
        MyDialog.info('未找到可用的语音识别语言包');
      } else if (!speechEnabled.value) {
        MyDialog.info('语音识别服务初始化失败，请重启应用重试');
      } else {
        MyDialog.info('语音识别功能正常，支持${locales.length}种语言');
      }
    } catch (e) {
      print('检查语音识别可用性异常: $e');
      MyDialog.info('检查语音识别功能时出错: $e');
    }
  }

  @override
  void onClose() {
    textC.dispose();
    scrollC.dispose();
    _speechToText.cancel();
    super.onClose();
  }
}
