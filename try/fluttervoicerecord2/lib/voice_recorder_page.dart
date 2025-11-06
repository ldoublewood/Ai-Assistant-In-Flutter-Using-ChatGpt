import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorderPage extends StatefulWidget {
  const VoiceRecorderPage({super.key});

  @override
  State<VoiceRecorderPage> createState() => _VoiceRecorderPageState();
}

class _VoiceRecorderPageState extends State<VoiceRecorderPage> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  String? _recordedFilePath;
  String _statusText = '准备就绪';

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }

  // 初始化录音器
  Future<void> _initializeRecorder() async {
    try {
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();

      // 请求录音权限
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        setState(() {
          _statusText = '录音权限被拒绝';
        });
        return;
      }

      // 初始化录音器和播放器
      await _recorder!.openRecorder();
      await _player!.openPlayer();

      setState(() {
        _isRecorderInitialized = true;
        _isPlayerInitialized = true;
        _statusText = '录音器已准备就绪';
      });
    } catch (e) {
      setState(() {
        _statusText = '初始化失败: $e';
      });
    }
  }

  // 开始录音
  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;

    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordedFilePath = filePath;
        _statusText = '正在录音...';
      });
    } catch (e) {
      setState(() {
        _statusText = '录音失败: $e';
      });
    }
  }

  // 停止录音
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _statusText = '录音完成';
      });
    } catch (e) {
      setState(() {
        _statusText = '停止录音失败: $e';
      });
    }
  }

  // 播放录音
  Future<void> _playRecording() async {
    if (!_isPlayerInitialized || _recordedFilePath == null) return;

    try {
      if (_isPlaying) {
        await _player!.stopPlayer();
        setState(() {
          _isPlaying = false;
          _statusText = '播放停止';
        });
      } else {
        await _player!.startPlayer(
          fromURI: _recordedFilePath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
              _statusText = '播放完成';
            });
          },
        );
        setState(() {
          _isPlaying = true;
          _statusText = '正在播放...';
        });
      }
    } catch (e) {
      setState(() {
        _statusText = '播放失败: $e';
      });
    }
  }

  // 删除录音文件
  Future<void> _deleteRecording() async {
    if (_recordedFilePath == null) return;

    try {
      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _recordedFilePath = null;
        _statusText = '录音文件已删除';
      });
    } catch (e) {
      setState(() {
        _statusText = '删除失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音录制演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 状态显示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 录音按钮
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _isRecorderInitialized
                    ? (_isRecording ? _stopRecording : _startRecording)
                    : null,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              _isRecording ? '点击停止录音' : '点击开始录音',
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 40),
            
            // 播放和删除按钮
            if (_recordedFilePath != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isPlayerInitialized ? _playRecording : null,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? '停止播放' : '播放录音'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _deleteRecording,
                    icon: const Icon(Icons.delete),
                    label: const Text('删除录音'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 40),
            
            // 文件信息
            if (_recordedFilePath != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '录音文件信息:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '路径: ${_recordedFilePath!.split('/').last}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}