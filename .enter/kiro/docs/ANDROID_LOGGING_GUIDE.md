# Android 日志查看指南

## 问题描述
Flutter项目中的日志在Android logcat中不显示的解决方案。

## 解决方案

### 1. 使用新的日志工具类
项目已经创建了统一的日志工具类 `lib/utils/logger.dart`，它会同时输出到：
- Flutter开发者工具
- Android logcat
- 控制台

### 2. 查看日志的方法

#### 方法1：Android Studio Logcat
1. 在Android Studio中打开项目
2. 连接Android设备或启动模拟器
3. 运行应用：`flutter run`
4. 在底部工具栏点击 "Logcat"
5. 在过滤器中输入：`AiAssistant` 或 `Voice` 或 `Network`

#### 方法2：命令行 adb logcat
```bash
# 查看所有应用日志
adb logcat | grep AiAssistant

# 查看语音相关日志
adb logcat | grep Voice

# 查看网络相关日志  
adb logcat | grep Network

# 实时查看日志（推荐）
adb logcat -s "flutter:*" | grep -E "(AiAssistant|Voice|Network)"
```

#### 方法3：VS Code Debug Console
1. 在VS Code中打开项目
2. 按F5或运行调试
3. 在Debug Console中查看日志输出

### 3. 测试日志功能
应用中已添加日志测试功能：
1. 打开应用
2. 进入"语音识别测试"界面
3. 点击"测试日志输出"按钮
4. 检查logcat是否有输出

### 4. 常见问题排查

#### 问题1：logcat中没有任何输出
解决方案：
```bash
# 重启adb服务
adb kill-server
adb start-server

# 检查设备连接
adb devices

# 清除logcat缓存
adb logcat -c
```

#### 问题2：日志级别过滤
确保日志级别设置正确：
```bash
# 设置日志级别为详细
adb shell setprop log.tag.flutter VERBOSE
adb shell setprop persist.log.tag V

# 或者使用之前的命令
adb shell settings put global logcat_level 0
```

#### 问题3：应用包名过滤
如果需要按包名过滤：
```bash
# 获取应用包名
adb shell pm list packages | grep ai

# 按包名过滤日志
adb logcat --pid=$(adb shell pidof com.example.ai_assistant)
```

### 5. 日志标签说明
- `[AiAssistant][INFO]` - 一般信息日志
- `[AiAssistant][DEBUG]` - 调试日志
- `[AiAssistant][WARNING]` - 警告日志
- `[AiAssistant][ERROR]` - 错误日志
- `[Voice]` - 语音识别相关日志
- `[Network]` - 网络请求相关日志
- `[Config]` - 配置更新相关日志

### 6. 验证修复
运行以下命令验证日志是否正常工作：
```bash
# 启动应用并实时查看日志
flutter run & adb logcat | grep -E "(AiAssistant|Voice|Network)"
```

如果看到类似以下输出，说明日志配置成功：
```
[AiAssistant][INFO] 应用启动完成
[Voice] 语音识别初始化成功
[Config] 语音识别模式设置为: 远程
```