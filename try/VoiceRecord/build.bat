@echo off
REM 安卓录音演示应用构建脚本 (Windows)

echo 开始构建安卓录音演示应用...

REM 检查是否安装了gradle
gradle --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到 gradle 命令
    echo 请安装 Gradle 或使用 Android Studio 构建项目
    echo.
    echo 安装方法：
    echo 1. 下载并解压 Gradle: https://gradle.org/releases/
    echo 2. 将 Gradle bin 目录添加到 PATH 环境变量
    echo 3. 或使用 Android Studio 打开项目进行构建
    pause
    exit /b 1
)

REM 检查是否设置了ANDROID_HOME
if "%ANDROID_HOME%"=="" (
    echo 警告: 未设置 ANDROID_HOME 环境变量
    echo 请设置 ANDROID_HOME 指向 Android SDK 目录
    echo 例如: set ANDROID_HOME=C:\Users\YourName\AppData\Local\Android\Sdk
    echo.
)

REM 创建local.properties文件
if not exist "local.properties" (
    if not "%ANDROID_HOME%"=="" (
        echo sdk.dir=%ANDROID_HOME% > local.properties
        echo 已创建 local.properties 文件
    ) else (
        echo 请手动创建 local.properties 文件并设置 sdk.dir
        echo 例如: echo sdk.dir=C:\path\to\android\sdk > local.properties
        pause
        exit /b 1
    )
)

REM 清理之前的构建
echo 清理之前的构建...
gradle clean

REM 构建项目
echo 开始构建...
gradle assembleDebug

if %errorlevel% equ 0 (
    echo.
    echo 构建成功！
    echo APK 文件位置: app\build\outputs\apk\debug\app-debug.apk
    echo.
    echo 安装到设备: adb install app\build\outputs\apk\debug\app-debug.apk
) else (
    echo.
    echo 构建失败，请检查错误信息
    echo.
    echo 常见解决方法：
    echo 1. 确保安装了正确版本的 Android SDK
    echo 2. 检查网络连接（需要下载依赖）
    echo 3. 使用 Android Studio 打开项目进行构建
)

pause