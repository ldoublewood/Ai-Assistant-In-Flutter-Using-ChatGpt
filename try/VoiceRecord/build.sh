#!/bin/bash

# 安卓录音演示应用构建脚本

echo "开始构建安卓录音演示应用..."

# 检查是否安装了gradle
if ! command -v gradle &> /dev/null; then
    echo "错误: 未找到 gradle 命令"
    echo "请安装 Gradle 或使用 Android Studio 构建项目"
    echo ""
    echo "安装方法："
    echo "1. 使用包管理器: sudo apt install gradle (Ubuntu/Debian)"
    echo "2. 或下载并解压 Gradle: https://gradle.org/releases/"
    echo "3. 或使用 Android Studio 打开项目进行构建"
    exit 1
fi

# 检查是否设置了ANDROID_HOME
if [ -z "$ANDROID_HOME" ]; then
    echo "警告: 未设置 ANDROID_HOME 环境变量"
    echo "请设置 ANDROID_HOME 指向 Android SDK 目录"
    echo "例如: export ANDROID_HOME=/home/user/Android/Sdk"
    echo ""
fi

# 创建local.properties文件
if [ ! -f "local.properties" ]; then
    if [ -n "$ANDROID_HOME" ]; then
        echo "sdk.dir=$ANDROID_HOME" > local.properties
        echo "已创建 local.properties 文件"
    else
        echo "请手动创建 local.properties 文件并设置 sdk.dir"
        echo "例如: echo 'sdk.dir=/path/to/android/sdk' > local.properties"
        exit 1
    fi
fi

# 清理之前的构建
echo "清理之前的构建..."
gradle clean

# 构建项目
echo "开始构建..."
gradle assembleDebug

if [ $? -eq 0 ]; then
    echo ""
    echo "构建成功！"
    echo "APK 文件位置: app/build/outputs/apk/debug/app-debug.apk"
    echo ""
    echo "安装到设备: adb install app/build/outputs/apk/debug/app-debug.apk"
else
    echo ""
    echo "构建失败，请检查错误信息"
    echo ""
    echo "常见解决方法："
    echo "1. 确保安装了正确版本的 Android SDK"
    echo "2. 检查网络连接（需要下载依赖）"
    echo "3. 使用 Android Studio 打开项目进行构建"
fi