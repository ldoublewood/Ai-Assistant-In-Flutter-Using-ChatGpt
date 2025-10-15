# 快速开始指南

## 🚀 5分钟快速上手

### 1. 环境准备
确保你已经安装了以下工具：
- Flutter SDK (>=3.4.3)
- Android Studio 或 VS Code
- Android/iOS 开发环境

### 2. 获取项目
```bash
git clone <repository-url>
cd ai_assistant
```

### 3. 安装依赖
```bash
flutter pub get
```

### 4. 配置API密钥
编辑 `lib/helper/global.dart` 文件：
```dart
String apiKey = '你的Google-Gemini-API密钥';
```

**获取API密钥：**
1. 访问 [Google AI Studio](https://aistudio.google.com/app/apikey)
2. 登录Google账号
3. 创建新的API密钥
4. 复制密钥到上述文件中

### 5. 运行应用
```bash
flutter run
```

## 📱 基本使用

### 文字对话
1. 在底部输入框输入问题
2. 点击发送按钮（蓝色圆形按钮）
3. 等待AI回复

### 语音输入
1. **长按**麦克风按钮开始录音
2. 说出你的问题
3. **松开**按钮结束录音
4. 系统自动识别语音并发送

### 主题切换
- 点击右上角的主题按钮切换明暗模式

## 🎤 语音功能设置

### Android权限
应用会自动请求麦克风权限，首次使用时允许即可。

### iOS权限配置
如果你要在iOS上运行，需要在 `ios/Runner/Info.plist` 中添加：
```xml
<key>NSMicrophoneUsageDescription</key>
<string>此应用需要麦克风权限以支持语音输入功能</string>
```

## 🔧 常见问题

### Q: API密钥无效怎么办？
A: 请确保：
1. API密钥正确复制，没有多余的空格
2. API密钥已启用Gemini服务
3. 网络连接正常

### Q: 语音识别不工作？
A: 请检查：
1. 是否授予了麦克风权限
2. 设备麦克风是否正常工作
3. 网络连接是否稳定

### Q: 编译错误怎么办？
A: 尝试以下步骤：
1. `flutter clean`
2. `flutter pub get`
3. `flutter run`

### Q: Markdown不显示？
A: 确保AI回复包含有效的Markdown格式，应用会自动渲染。

## 📝 Markdown支持示例

AI可以返回以下格式的内容：

**粗体文字**
```dart
// 代码块
void main() {
  print('Hello World');
}
```

> 这是引用块

- 列表项1
- 列表项2

## 🛠️ 开发模式

### 调试模式运行
```bash
flutter run --debug
```

### 构建APK
```bash
flutter build apk --debug
```

### 代码分析
```bash
flutter analyze
```

## 📞 获取帮助

如果遇到问题：
1. 查看 [README.md](README.md) 详细文档
2. 检查 [CHANGELOG.md](CHANGELOG.md) 了解最新变更
3. 查看项目Issues页面
4. 提交新的Issue描述问题

## 🎯 下一步

- 尝试不同类型的问题测试AI回复
- 体验语音输入功能
- 探索Markdown格式的丰富显示效果
- 根据需要自定义界面主题