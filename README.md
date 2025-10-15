# AI 智能助手

一个极简的AI智能对话应用，基于Flutter开发，支持Markdown格式显示和语音输入功能。

## 功能特性

- ✨ **极简设计**: 专注于AI对话功能，界面简洁易用
- 📝 **Markdown支持**: AI回复支持Markdown格式，包括代码块、列表、粗体等
- 🎤 **语音输入**: 支持语音转文字输入，长按语音按钮即可使用
- 🌙 **深色模式**: 支持明暗主题切换
- 🤖 **智能对话**: 基于Google Gemini AI，提供智能、准确的回答

## 技术栈

- **Flutter**: 跨平台移动应用开发框架
- **GetX**: 状态管理和路由管理
- **Google Gemini AI**: AI对话引擎
- **flutter_markdown**: Markdown渲染支持
- **speech_to_text**: 语音识别功能
- **Hive**: 本地数据存储

## 安装和运行

### 前置要求
- Flutter SDK (>=3.4.3)
- Dart SDK
- Android Studio / VS Code
- Android/iOS 开发环境

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd ai_assistant
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **配置API密钥**
   
   在 `lib/helper/global.dart` 文件中配置你的Google Gemini API密钥：
   ```dart
   String apiKey = 'your-gemini-api-key-here';
   ```
   
   获取API密钥：[Google AI Studio](https://aistudio.google.com/app/apikey)

4. **运行应用**
   ```bash
   flutter run
   ```

## 语音功能配置

### Android权限
应用已自动配置麦克风权限，首次使用语音功能时会请求权限。

### iOS权限
需要在 `ios/Runner/Info.plist` 中添加麦克风权限说明：
```xml
<key>NSMicrophoneUsageDescription</key>
<string>此应用需要麦克风权限以支持语音输入功能</string>
```

## 语音服务部署

应用支持远程语音识别服务，API接口文档位于 `api/ai-assistant-server/` 目录。

### 服务器要求
- 支持音频文件上传和处理
- 实现语音转文字API接口
- 支持中文语音识别

### 配置服务器地址
在 `lib/services/voice_service.dart` 中修改服务器地址：
```dart
static const String _baseUrl = 'https://your-server-url.com/api';
```

## 项目结构

```
lib/
├── apis/           # API接口层
├── controller/     # 控制器层
├── helper/         # 工具类
├── model/          # 数据模型
├── screen/         # 页面
├── services/       # 服务层
├── widget/         # 组件
└── main.dart       # 应用入口

api/
└── ai-assistant-server/  # 语音服务API文档
```

## 主要改进

相比原版本，本版本进行了以下改进：

1. **功能精简**: 移除了图片生成和翻译功能，专注于AI对话
2. **界面优化**: 重新设计了聊天界面，支持更好的消息展示
3. **Markdown支持**: AI回复支持丰富的Markdown格式
4. **语音输入**: 新增语音转文字输入功能
5. **中文优化**: 全面支持中文界面和交互

## 使用说明

1. **文字输入**: 在底部输入框中输入问题，点击发送按钮
2. **语音输入**: 长按麦克风按钮进行语音输入，松开后自动识别
3. **主题切换**: 点击右上角的主题按钮切换明暗模式
4. **Markdown**: AI回复自动支持Markdown格式渲染

## 开发和贡献

欢迎提交Issue和Pull Request来改进这个项目。

### 开发环境设置
```bash
# 检查Flutter环境
flutter doctor

# 运行测试
flutter test

# 构建APK
flutter build apk
```

## 许可证

本项目基于原项目进行改造，请遵循相应的开源许可证。
