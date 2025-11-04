# 安卓录音功能演示应用

这是一个最基本的安卓录音功能演示应用，用于验证安卓设备的录音功能。

## 功能特性

- **基本录音功能**：使用 MediaRecorder 进行音频录制
- **音频播放**：使用 MediaPlayer 播放录制的音频
- **权限管理**：自动请求录音和存储权限
- **简洁界面**：提供开始录音、播放录音、停止操作的按钮
- **状态显示**：实时显示当前操作状态

## 技术实现

### 核心类和方法

1. **MediaRecorder**：用于音频录制
   - `setAudioSource()`：设置音频源为麦克风
   - `setOutputFormat()`：设置输出格式为 3GP
   - `setAudioEncoder()`：设置音频编码器为 AMR_NB

2. **MediaPlayer**：用于音频播放
   - `setDataSource()`：设置音频文件路径
   - `prepare()`：准备播放
   - `start()`：开始播放

3. **权限管理**：
   - `RECORD_AUDIO`：录音权限
   - `WRITE_EXTERNAL_STORAGE`：存储权限

### 文件结构

```
VoiceRecord/
├── app/
│   ├── build.gradle                    # 应用级构建配置
│   └── src/main/
│       ├── AndroidManifest.xml        # 应用清单文件
│       ├── java/com/example/voicerecord/
│       │   └── MainActivity.java      # 主活动类
│       └── res/
│           ├── layout/
│           │   └── activity_main.xml  # 主界面布局
│           ├── values/
│           │   ├── colors.xml         # 颜色资源
│           │   ├── strings.xml        # 字符串资源
│           │   └── themes.xml         # 主题样式
│           └── xml/
│               ├── backup_rules.xml   # 备份规则
│               └── data_extraction_rules.xml
├── build.gradle                       # 项目级构建配置
├── settings.gradle                    # 项目设置
└── gradle.properties                  # Gradle 属性配置
```

## 构建和运行

1. **环境要求**：
   - Android Studio
   - Android SDK (API 21+)
   - Java 8+

2. **构建步骤**：
   ```bash
   cd try/VoiceRecord
   ./gradlew assembleDebug
   ```

3. **安装到设备**：
   ```bash
   ./gradlew installDebug
   ```

## 使用说明

1. **启动应用**：安装后点击应用图标启动
2. **授权权限**：首次使用时会请求录音和存储权限，请点击"允许"
3. **开始录音**：点击"开始录音"按钮开始录制音频
4. **停止录音**：点击"停止录音"按钮结束录制
5. **播放录音**：点击"播放录音"按钮播放刚才录制的音频
6. **停止播放**：点击"停止"按钮停止播放

## 注意事项

- 录音文件保存在应用的私有目录中（`/Android/data/com.example.voicerecord/files/Music/VoiceRecord/`）
- 音频格式为 3GP，编码器为 AMR_NB
- 需要在真实设备上测试，模拟器可能无法正常录音
- 确保设备有麦克风硬件支持

## 故障排除

### 构建问题

1. **缺少图标错误**：已使用矢量图标替代，无需额外图片文件
2. **Gradle Wrapper 错误**：使用 `./fix-and-build.sh` 脚本或 Android Studio
3. **权限错误**：确保脚本有执行权限 `chmod +x *.sh`

### 快速构建

```bash
# 一键修复和构建
chmod +x fix-and-build.sh
./fix-and-build.sh
```

## 测试验证

此应用可以用来验证：
- 设备麦克风是否正常工作
- 录音权限是否正确获取
- 音频录制和播放功能是否正常
- 文件存储是否成功

适合作为录音功能的基础测试工具使用。