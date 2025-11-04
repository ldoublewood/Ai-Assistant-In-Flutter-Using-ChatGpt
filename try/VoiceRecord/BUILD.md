# 构建说明

## 环境准备

1. **安装 Android Studio**
   - 下载并安装最新版本的 Android Studio
   - 确保安装了 Android SDK (API 21 或更高版本)

2. **配置环境**
   - 设置 ANDROID_HOME 环境变量指向 Android SDK 目录
   - 将 Android SDK 的 platform-tools 添加到 PATH

## 构建步骤

### 方法一：使用 Android Studio（推荐）

1. 打开 Android Studio
2. 选择 "Open an existing Android Studio project"
3. 选择 `try/VoiceRecord` 目录
4. 等待项目同步完成
5. 点击 "Build" -> "Build Bundle(s) / APK(s)" -> "Build APK(s)"
6. 生成的 APK 文件位于 `app/build/outputs/apk/debug/` 目录

### 方法二：使用命令行

由于 Gradle Wrapper 文件较大，这里提供了简化的构建脚本：

1. **Linux/Mac 系统**：
   ```bash
   # 给脚本执行权限
   chmod +x build.sh
   
   # 运行构建脚本
   ./build.sh
   ```

2. **Windows 系统**：
   ```cmd
   # 运行构建脚本
   build.bat
   ```

3. **手动使用 Gradle**：
   ```bash
   # 确保已安装 Gradle 和设置 ANDROID_HOME
   gradle assembleDebug
   ```

## 安装到设备

### 使用 Android Studio
1. 连接安卓设备并启用开发者选项和USB调试
2. 在 Android Studio 中点击 "Run" 按钮
3. 选择目标设备

### 使用命令行
```bash
# 手动安装 APK
adb install app/build/outputs/apk/debug/app-debug.apk
```

## 测试验证

1. 启动应用后，会自动请求录音权限
2. 点击"允许"授予权限
3. 点击"开始录音"测试录音功能
4. 点击"播放录音"测试播放功能

## 常见问题

1. **权限被拒绝**：在设备设置中手动授予应用录音权限
2. **无法录音**：确保设备有麦克风硬件
3. **构建失败**：检查 Android SDK 版本和网络连接

## 文件说明

- `MainActivity.java`：主要的录音逻辑实现
- `activity_main.xml`：用户界面布局
- `AndroidManifest.xml`：应用权限和配置
- `build.gradle`：构建配置文件