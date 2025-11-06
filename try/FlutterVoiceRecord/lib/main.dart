import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const VoiceRecordApp());
}

class VoiceRecordApp extends StatelessWidget {
  const VoiceRecordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter录音测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const VoiceRecordScreen(),
    );
  }
}

class VoiceRecordScreen extends StatefulWidget {
  const VoiceRecordScreen({super.key});

  @override
  State<VoiceRecordScreen> createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _currentFilePath;
  String _status = '准备中...';

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      // 请求录音权限
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        setState(() {
          _status = '麦克风权限被拒绝';
        });
        return;
      }

      // 初始化录音器
      await _recorder.openRecorder();
      
      setState(() {
        _isInitialized = true;
        _status = '准备就绪，点击开始录音';
      });
      
      print('录音器初始化成功');
    } catch (e) {
      setState(() {
        _status = '初始化失败: $e';
      });
      print('录音器初始化失败: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) return;

    try {
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFilePath = '${tempDir.path}/test_recording_$timestamp.wav';

      setState(() {
        _status = '开始录音...';
      });

      // 开始录音
      await _recorder.startRecorder(
        toFile: _currentFilePath,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _status = '正在录音中...';
      });

      print('录音已启动，文件路径: $_currentFilePath');

      // 检查文件状态
      _checkFileStatus();

    } catch (e) {
      setState(() {
        _status = '启动录音失败: $e';
      });
      print('启动录音失败: $e');
    }
  }

  Future<void> _checkFileStatus() async {
    if (_currentFilePath == null) return;
    
    final file = File(_currentFilePath!);
    if (await file.exists()) {
      final size = await file.length();
      print('录音文件大小: $size 字节');
      
      if (size > 44) {
        print('录音成功！文件包含 ${size - 44} 字节音频数据');
      } else {
        print('警告：文件只有文件头($size字节)，无音频数据');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      // 停止录音
      await _recorder.stopRecorder();

      setState(() {
        _isRecording = false;
        _status = '录音已停止';
      });

      print('录音已停止');

      // 检查最终文件状态
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          final size = await file.length();
          final duration = await file.length();
          
          setState(() {
            _status = '录音完成 - 文件大小: ${size}字节';
          });
          
          print('最终文件大小: $size 字节');
          print('文件路径: $_currentFilePath');
          
          if (size <= 44) {
            print('❌ 问题确认：文件只有文件头，无音频数据');
          } else {
            print('✅ 录音成功：文件包含音频数据');
          }
        }
      }

    } catch (e) {
      setState(() {
        _status = '停止录音失败: $e';
      });
      print('停止录音失败: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter录音测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 状态显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.mic, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isInitialized ? '录音器已初始化' : '录音器未初始化',
                      style: TextStyle(
                        color: _isInitialized ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 录音按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isInitialized && !_isRecording ? _startRecording : null,
                  icon: const Icon(Icons.mic),
                  label: const Text('开始录音'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止录音'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 文件信息
            if (_currentFilePath != null)
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '文件信息:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '路径: ${_currentFilePath!.split('/').last}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // 说明文本
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '测试说明:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• 点击"开始录音"按钮开始录音'),
                    Text('• 说话几秒钟后点击"停止录音"'),
                    Text('• 查看控制台输出文件大小信息'),
                    Text('• 正常情况：文件应大于44字节'),
                    Text('• 问题情况：文件等于44字节（只有文件头）'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}