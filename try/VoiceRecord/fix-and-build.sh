#!/bin/bash

# 快速修复和构建脚本

echo "=== 安卓录音应用快速修复和构建 ==="
echo ""

# 检查并创建local.properties
if [ ! -f "local.properties" ]; then
    if [ -n "$ANDROID_HOME" ]; then
        echo "sdk.dir=$ANDROID_HOME" > local.properties
        echo "✓ 已创建 local.properties"
    else
        echo "请设置 ANDROID_HOME 环境变量或手动创建 local.properties"
        echo "例如: export ANDROID_HOME=/path/to/android/sdk"
        exit 1
    fi
fi

# 清理构建缓存
echo "清理构建缓存..."
if [ -d "build" ]; then
    rm -rf build
fi
if [ -d "app/build" ]; then
    rm -rf app/build
fi
if [ -d ".gradle" ]; then
    rm -rf .gradle
fi

# 检查gradle
if ! command -v gradle &> /dev/null; then
    echo "错误: 未找到 gradle 命令"
    echo "请安装 Gradle 或使用 Android Studio"
    exit 1
fi

# 构建项目
echo "开始构建..."
gradle clean
gradle assembleDebug

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 构建成功！"
    echo "APK 位置: app/build/outputs/apk/debug/app-debug.apk"
    echo ""
    
    # 检查是否有连接的设备
    if command -v adb &> /dev/null; then
        echo "检查连接的设备..."
        adb devices -l
        echo ""
        echo "安装命令: adb install app/build/outputs/apk/debug/app-debug.apk"
    fi
else
    echo ""
    echo "❌ 构建失败"
    echo "请检查错误信息或使用 Android Studio 构建"
fi