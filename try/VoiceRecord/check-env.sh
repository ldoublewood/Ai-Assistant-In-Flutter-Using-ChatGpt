#!/bin/bash

# 环境检查脚本

echo "=== 安卓开发环境检查 ==="
echo ""

# 检查Java
echo "1. 检查 Java 版本:"
if command -v java &> /dev/null; then
    java -version
    echo "✓ Java 已安装"
else
    echo "✗ 未找到 Java，请安装 JDK 8 或更高版本"
fi
echo ""

# 检查Gradle
echo "2. 检查 Gradle:"
if command -v gradle &> /dev/null; then
    gradle --version | head -3
    echo "✓ Gradle 已安装"
else
    echo "✗ 未找到 Gradle"
    echo "  安装方法: sudo apt install gradle (Ubuntu/Debian)"
    echo "  或从 https://gradle.org/releases/ 下载"
fi
echo ""

# 检查Android SDK
echo "3. 检查 Android SDK:"
if [ -n "$ANDROID_HOME" ]; then
    echo "ANDROID_HOME = $ANDROID_HOME"
    if [ -d "$ANDROID_HOME" ]; then
        echo "✓ Android SDK 目录存在"
        if [ -f "$ANDROID_HOME/platform-tools/adb" ]; then
            echo "✓ ADB 工具可用"
        else
            echo "✗ 未找到 ADB 工具"
        fi
    else
        echo "✗ Android SDK 目录不存在"
    fi
else
    echo "✗ 未设置 ANDROID_HOME 环境变量"
    echo "  请设置: export ANDROID_HOME=/path/to/android/sdk"
fi
echo ""

# 检查ADB
echo "4. 检查 ADB 连接:"
if command -v adb &> /dev/null; then
    echo "ADB 版本:"
    adb version | head -1
    echo ""
    echo "连接的设备:"
    adb devices
    echo "✓ ADB 可用"
else
    echo "✗ 未找到 ADB 命令"
    echo "  请将 Android SDK platform-tools 添加到 PATH"
fi
echo ""

echo "=== 检查完成 ==="
echo ""
echo "如果所有项目都显示 ✓，则可以开始构建项目"
echo "否则请根据提示安装缺失的组件"