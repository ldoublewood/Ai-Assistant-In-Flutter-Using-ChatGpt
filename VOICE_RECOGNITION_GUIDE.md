# 语音识别功能使用指南

## 概述

本项目已将语音识别功能从本地识别改为远程API调用方式，基于 [SenseVoice-Api](https://github.com/HG-ha/SenseVoice-Api) 项目提供的语音识别服务。

## 功能特性

### ✅ 已实现功能
- 远程语音识别服务集成
- 本地语音识别功能屏蔽（通过开关控制）
- 语音识别配置管理
- 服务器连接状态检测
- 多语言支持（中文、英语、日语、韩语、粤语等）
- 语音设置界面
- 配置持久化存储

### 🔧 技术实现

#### 1. API接口适配
- 创建了符合SenseVoice-Api规范的OpenAPI接口定义
- 支持 `/asr` 端点进行语音识别
- 支持 `/health` 端点进行健康检查

#### 2. 服务架构
```
VoiceService (统一接口)
├── RemoteVoiceService (远程识别)
├── VoiceConfig (配置管理)
└── 本地识别 (已屏蔽)
```

#### 3. 新增文件
- `lib/services/remote_voice_service.dart` - 远程语音识别服务
- `lib/services/voice_config.dart` - 语音配置管理
- `lib/screen/voice_settings_screen.dart` - 语音设置界面
- `api/ai-assistant-server/speech-to-text.yaml` - API接口定义

## 使用方法

### 1. 启动SenseVoice服务

首先需要启动SenseVoice-Api服务：

```bash
# 克隆SenseVoice-Api项目
git clone https://github.com/HG-ha/SenseVoice-Api.git
cd SenseVoice-Api

# 按照项目说明启动服务（默认端口9880）
# 具体启动方法请参考SenseVoice-Api项目文档
```

### 2. 配置应用

1. 打开应用，进入聊天界面
2. 点击右上角的语音设置按钮（🎤⚙️图标）
3. 在设置界面中：
   - 启用"使用远程语音识别"开关
   - 设置服务器地址（默认：`http://localhost:9880`）
   - 选择识别语言（默认：自动检测）
   - 点击"测试连接"验证服务器状态
   - 保存设置

### 3. 使用语音输入

1. 在聊天界面，长按麦克风按钮开始录音
2. 说话完成后松开按钮
3. 系统会将录音发送到远程服务器进行识别
4. 识别结果会自动填入输入框

## 配置说明

### 服务器地址配置
- 本地开发：`http://localhost:9880`
- 远程服务器：`https://your-domain.com`

### 支持的语言
- `auto` - 自动检测
- `zh` - 中文
- `en` - 英语
- `ja` - 日语
- `ko` - 韩语
- `yue` - 粤语

### 音频格式支持
- WAV
- MP3
- FLAC
- M4A
- 其他常见音频格式

## 故障排除

### 1. 无法连接到服务器
- 检查SenseVoice-Api服务是否正在运行
- 验证服务器地址是否正确
- 确认网络连接正常
- 检查防火墙设置

### 2. 识别结果不准确
- 确保录音环境安静
- 说话清晰，语速适中
- 选择正确的识别语言
- 检查音频质量

### 3. 权限问题
- 确保应用已获得麦克风权限
- 在系统设置中检查权限状态

## 开发说明

### 本地语音识别屏蔽
本地语音识别功能已通过配置开关屏蔽：
- `VoiceConfig.useRemoteVoice` 控制使用远程还是本地识别
- 当设置为本地识别时，会提示用户启用远程识别
- 保留了 `speech_to_text` 依赖用于录音功能

### 扩展开发
如需添加新的语音识别服务：
1. 在 `RemoteVoiceService` 中添加新的API适配
2. 在 `VoiceConfig` 中添加相应配置选项
3. 更新设置界面以支持新的配置

### API接口扩展
当前API接口基于SenseVoice-Api规范，如需支持其他服务：
1. 修改 `api/ai-assistant-server/speech-to-text.yaml`
2. 更新 `RemoteVoiceService` 中的请求格式
3. 适配响应数据结构

## 注意事项

1. **音频文件大小限制**：建议不超过30MB
2. **网络延迟**：远程识别会有网络延迟，请耐心等待
3. **服务器稳定性**：确保SenseVoice服务稳定运行
4. **隐私安全**：音频数据会发送到远程服务器，请注意隐私保护

## 更新日志

### v1.0.0 (当前版本)
- ✅ 集成SenseVoice-Api远程语音识别
- ✅ 屏蔽本地语音识别功能
- ✅ 添加语音设置界面
- ✅ 实现配置管理和持久化
- ✅ 支持多语言识别
- ✅ 添加服务器连接检测

### 计划功能
- 🔄 支持更多音频格式
- 🔄 添加音频预处理功能
- 🔄 支持实时语音识别
- 🔄 添加语音识别历史记录