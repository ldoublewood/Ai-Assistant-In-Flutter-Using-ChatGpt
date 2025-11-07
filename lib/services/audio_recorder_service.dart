import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'audio_format_config.dart';

/// 音频录制服务类，支持多种格式录制
class AudioRecorderService {
  FlutterSoundRecorder? _recorder;
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
      
      // 如果已有录制器，先关闭
      if (_recorder != null) {
        try {
          await _recorder!.closeRecorder();
        } catch (e) {
          Logger.warning('关闭旧录制器时出错: $e');
        }
      }
      
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      
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
    _currentRecordingPath = '${directory.path}/recording_$timestamp.aac';
    _recordingStartTime = DateTime.now();
    
    await _recorder!.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.aacADTS,
    );
    
    Logger.voice('AAC录制已启动，文件路径: $_currentRecordingPath');
    return _currentRecordingPath!;
  }
  
  /// 开始WAV格式录制
  Future<String> _startWAVRecording(Directory directory, int timestamp) async {
    _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';
    _recordingStartTime = DateTime.now();
    
    await _recorder!.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.pcm16WAV,
    );
    
    Logger.voice('WAV录制已启动，文件路径: $_currentRecordingPath');
    return _currentRecordingPath!;
  }
  
  /// 开始PCM格式录制（后续转换为WAV）
  Future<String> _startPCMRecording(Directory directory, int timestamp) async {
    // 先录制为PCM格式
    _currentRecordingPath = '${directory.path}/recording_$timestamp.pcm';
    _recordingStartTime = DateTime.now();
    
    await _recorder!.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.pcm16,
    );
    
    Logger.voice('PCM录制已启动，文件路径: $_currentRecordingPath');
    return _currentRecordingPath!;
  }
  
  /// 停止录制
  Future<String?> stopRecording() async {
    if (_recorder == null || _currentRecordingPath == null) {
      return null;
    }
    
    try {
      await _recorder!.stopRecorder();
      
      // 计算录制时长
      Duration? recordingDuration;
      if (_recordingStartTime != null) {
        recordingDuration = DateTime.now().difference(_recordingStartTime!);
        Logger.voice('录制时长: ${recordingDuration.inMilliseconds}毫秒');
      }
      
      Logger.voice('录制已停止，文件路径: $_currentRecordingPath');
      
      // 检查录制文件
      final recordedFile = File(_currentRecordingPath!);
      if (!await recordedFile.exists()) {
        Logger.error('录制文件不存在: $_currentRecordingPath');
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
      
      // 如果是PCM格式，需要转换为WAV
      if (_currentFormat == 'pcm2wav') {
        return await _convertPCMToWAV(_currentRecordingPath!);
      }
      
      return _currentRecordingPath;
    } catch (e) {
      Logger.error('停止录制失败: $e', error: e);
      return null;
    } finally {
      _currentRecordingPath = null;
      _recordingStartTime = null;
    }
  }
  
  /// 将PCM文件转换为WAV文件
  Future<String?> _convertPCMToWAV(String pcmPath) async {
    try {
      Logger.voice('开始将PCM转换为WAV格式');
      
      final pcmFile = File(pcmPath);
      if (!await pcmFile.exists()) {
        Logger.error('PCM文件不存在: $pcmPath');
        return null;
      }
      
      // 读取PCM数据
      final pcmData = await pcmFile.readAsBytes();
      Logger.voice('PCM数据大小: ${pcmData.length}字节');
      
      if (pcmData.isEmpty) {
        Logger.error('PCM文件为空');
        return null;
      }
      
      // 生成WAV文件路径
      final wavPath = pcmPath.replaceAll('.pcm', '.wav');
      
      // 创建WAV文件头
      final wavData = _createWAVFile(pcmData);
      
      // 写入WAV文件
      final wavFile = File(wavPath);
      await wavFile.writeAsBytes(wavData);
      
      Logger.voice('PCM转WAV完成，WAV文件路径: $wavPath');
      Logger.voice('WAV文件大小: ${wavData.length}字节 (${(wavData.length / 1024).toStringAsFixed(2)}KB)');
      
      // 删除临时PCM文件
      try {
        await pcmFile.delete();
        Logger.debug('临时PCM文件已删除');
      } catch (e) {
        Logger.warning('删除临时PCM文件失败: $e');
      }
      
      return wavPath;
    } catch (e) {
      Logger.error('PCM转WAV失败: $e', error: e);
      return null;
    }
  }
  
  /// 创建WAV文件（添加WAV文件头到PCM数据）
  Uint8List _createWAVFile(Uint8List pcmData) {
    // WAV文件参数
    const int sampleRate = 16000; // 采样率 16kHz
    const int bitsPerSample = 16; // 16位采样
    const int channels = 1; // 单声道
    
    const int byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    const int blockAlign = channels * bitsPerSample ~/ 8;
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;
    
    // 创建WAV文件头（44字节）
    final header = ByteData(44);
    
    // RIFF头
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, fileSize, Endian.little); // 文件大小
    
    // WAVE标识
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'
    
    // fmt子块
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // fmt子块大小
    header.setUint16(20, 1, Endian.little);  // 音频格式（PCM）
    header.setUint16(22, channels, Endian.little); // 声道数
    header.setUint32(24, sampleRate, Endian.little); // 采样率
    header.setUint32(28, byteRate, Endian.little); // 字节率
    header.setUint16(32, blockAlign, Endian.little); // 块对齐
    header.setUint16(34, bitsPerSample, Endian.little); // 位深度
    
    // data子块
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little); // 数据大小
    
    // 合并文件头和PCM数据
    final wavData = Uint8List(44 + dataSize);
    wavData.setRange(0, 44, header.buffer.asUint8List());
    wavData.setRange(44, 44 + dataSize, pcmData);
    
    Logger.voice('WAV文件头创建完成，总大小: ${wavData.length}字节');
    return wavData;
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
  
  /// 是否正在录制
  bool get isRecording {
    return _recorder?.isRecording ?? false;
  }
  
  /// 获取当前录制格式
  String get currentFormat => _currentFormat;
  
  /// 释放资源
  Future<void> dispose() async {
    try {
      if (_recorder != null) {
        await _recorder!.closeRecorder();
        _recorder = null;
      }
    } catch (e) {
      Logger.warning('释放录制器资源时出错: $e');
    }
  }
}