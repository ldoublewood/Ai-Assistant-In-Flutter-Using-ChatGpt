import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'audio_format_config.dart';

/// 音频录制服务类，支持多种格式录制
class AudioRecorderService {
  AudioRecorder? _recorder;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  String _currentFormat = 'aac';
  
  /// 初始化录制器
  Future<void> initialize() async {
    try {
      // 请求录音权限
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('录音权限被拒绝');
      }
      
      // 检查录音权限
      if (!await AudioRecorder().hasPermission()) {
        throw Exception('录音权限被拒绝');
      }
      
      _recorder = AudioRecorder();
      
      Logger.debug('音频录制器初始化成功');
    } catch (e) {
      Logger.error('音频录制器初始化失败: $e', error: e);
      _recorder = null;
      rethrow;
    }
  }
  
  /// 开始录制
  Future<String> startRecording() async {
    if (_recorder == null) {
      throw Exception('录制器未初始化');
    }
    
    // 获取当前配置的音频格式
    _currentFormat = AudioFormatConfig.audioFormat;
    Logger.voice('开始录制，格式: $_currentFormat');
    
    // 获取应用文档目录
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    switch (_currentFormat) {
      case 'aac':
        return await _startAACRecording(directory, timestamp);
      case 'wav':
        return await _startWAVRecording(directory, timestamp);
      case 'pcm2wav':
        return await _startPCMRecording(directory, timestamp);
      default:
        throw Exception('不支持的音频格式: $_currentFormat');
    }
  }
  
  /// 开始AAC格式录制
  Future<String> _startAACRecording(Directory directory, int timestamp) async {
    _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';
    _recordingStartTime = DateTime.now();
    
    await _recorder!.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        bitRate: 128000,
        numChannels: 1,
      ),
      path: _currentRecordingPath!,
    );
    
    Logger.voice('AAC录制已启动，文件路径: $_currentRecordingPath');
    return _currentRecordingPath!;
  }
  
  /// 开始WAV格式录制
  Future<String> _startWAVRecording(Directory directory, int timestamp) async {
    _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';
    _recordingStartTime = DateTime.now();
    
    await _recorder!.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 256000,
        numChannels: 1,
      ),
      path: _currentRecordingPath!,
    );
    
    Logger.voice('WAV录制已启动，文件路径: $_currentRecordingPath');
    return _currentRecordingPath!;
  }
  
  /// 开始PCM格式录制（后续转换为WAV）
  Future<String> _startPCMRecording(Directory directory, int timestamp) async {
    // record库不直接支持PCM，我们使用WAV格式代替
    return await _startWAVRecording(directory, timestamp);
  }
  
  /// 停止录制
  Future<String?> stopRecording() async {
    if (_recorder == null || _currentRecordingPath == null) {
      return null;
    }
    
    try {
      final recordedPath = await _recorder!.stop();
      
      // 计算录制时长
      Duration? recordingDuration;
      if (_recordingStartTime != null) {
        recordingDuration = DateTime.now().difference(_recordingStartTime!);
        Logger.voice('录制时长: ${recordingDuration.inMilliseconds}毫秒');
      }
      
      Logger.voice('录制已停止，文件路径: $recordedPath');
      
      // 检查录制文件
      if (recordedPath == null) {
        Logger.error('录制失败，未生成文件');
        return null;
      }
      
      final recordedFile = File(recordedPath);
      if (!await recordedFile.exists()) {
        Logger.error('录制文件不存在: $recordedPath');
        return null;
      }
      
      final fileSize = await recordedFile.length();
      Logger.voice('录制文件大小: $fileSize字节 (${(fileSize / 1024).toStringAsFixed(2)}KB)');
      
      if (fileSize == 0) {
        Logger.error('录制文件为空');
        return null;
      }
      
      // 检查录制时长是否太短
      if (recordingDuration != null && recordingDuration.inMilliseconds < 500) {
        Logger.warning('录制时间太短: ${recordingDuration.inMilliseconds}毫秒');
        return null;
      }
      
      return recordedPath;
    } catch (e) {
      Logger.error('停止录制失败: $e', error: e);
      return null;
    } finally {
      _currentRecordingPath = null;
      _recordingStartTime = null;
    }
  }
  

  
  /// 验证录制文件
  Future<bool> validateRecordedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        Logger.error('录制文件不存在: $filePath');
        return false;
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        Logger.error('录制文件为空');
        return false;
      }
      
      // 根据文件格式进行不同的验证
      if (filePath.endsWith('.wav')) {
        return await _validateWAVFile(file);
      } else if (filePath.endsWith('.aac')) {
        return await _validateAACFile(file);
      } else if (filePath.endsWith('.m4a')) {
        return await _validateM4AFile(file);
      }
      
      return true;
    } catch (e) {
      Logger.error('验证录制文件失败: $e', error: e);
      return false;
    }
  }
  
  /// 验证WAV文件
  Future<bool> _validateWAVFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 44) {
        Logger.error('WAV文件太小，可能不是有效的WAV文件');
        return false;
      }
      
      // 检查WAV文件头
      String riffHeader = String.fromCharCodes(bytes.sublist(0, 4));
      if (riffHeader != 'RIFF') {
        Logger.error('WAV文件缺少RIFF头: $riffHeader');
        return false;
      }
      
      String waveHeader = String.fromCharCodes(bytes.sublist(8, 12));
      if (waveHeader != 'WAVE') {
        Logger.error('WAV文件缺少WAVE头: $waveHeader');
        return false;
      }
      
      Logger.voice('WAV文件格式验证通过，包含 ${bytes.length - 44} 字节音频数据');
      return true;
    } catch (e) {
      Logger.error('WAV文件验证异常: $e', error: e);
      return false;
    }
  }
  
  /// 验证AAC文件
  Future<bool> _validateAACFile(File file) async {
    try {
      final fileSize = await file.length();
      
      // AAC文件的基本大小检查
      if (fileSize < 100) {
        Logger.error('AAC文件太小: $fileSize字节');
        return false;
      }
      
      Logger.voice('AAC文件验证通过，文件大小: $fileSize字节');
      return true;
    } catch (e) {
      Logger.error('AAC文件验证异常: $e', error: e);
      return false;
    }
  }
  
  /// 验证M4A文件
  Future<bool> _validateM4AFile(File file) async {
    try {
      final fileSize = await file.length();
      
      // M4A文件的基本大小检查
      if (fileSize < 100) {
        Logger.error('M4A文件太小: $fileSize字节');
        return false;
      }
      
      Logger.voice('M4A文件验证通过，文件大小: $fileSize字节');
      return true;
    } catch (e) {
      Logger.error('M4A文件验证异常: $e', error: e);
      return false;
    }
  }
  
  /// 是否正在录制
  Future<bool> get isRecording async {
    if (_recorder == null) return false;
    return await _recorder!.isRecording();
  }
  
  /// 获取当前录制格式
  String get currentFormat => _currentFormat;
  
  /// 释放资源
  Future<void> dispose() async {
    try {
      if (_recorder != null) {
        await _recorder!.dispose();
        _recorder = null;
      }
    } catch (e) {
      Logger.warning('释放录制器资源时出错: $e');
    }
  }
}