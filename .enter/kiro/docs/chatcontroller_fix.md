# ChatController 依赖注入修复

## 问题描述
应用中出现 "ChatController not found" 错误，原因是 ChatController 的实例化和获取方式不一致：
- 在 `chatbot_feature.dart` 中通过直接实例化创建：`final _c = ChatController();`
- 在其他文件中通过 GetX 依赖注入获取：`Get.find<ChatController>()`

这导致 GetX 无法找到已注册的 ChatController 实例。

## 解决方案
统一使用 GetX 的依赖注入系统管理 ChatController：

### 1. 在应用启动时注册 ChatController
**文件：** `lib/main.dart`

**修改前：**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Pref.initialize();
  AppWrite.init();
  // ...
  runApp(const MyApp());
}
```

**修改后：**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Pref.initialize();
  AppWrite.init();
  
  // 注册 ChatController 到 GetX 依赖注入系统
  Get.put(ChatController());
  
  // ...
  runApp(const MyApp());
}
```

### 2. 统一使用 Get.find() 获取实例
**文件：** `lib/screen/feature/chatbot_feature.dart`

**修改前：**
```dart
class _ChatBotFeatureState extends State<ChatBotFeature> {
  final _c = ChatController();
  // ...
}
```

**修改后：**
```dart
class _ChatBotFeatureState extends State<ChatBotFeature> {
  final _c = Get.find<ChatController>();
  // ...
}
```

## 修改的好处
1. **一致性**：所有地方都使用相同的方式获取 ChatController 实例
2. **单例模式**：确保整个应用中只有一个 ChatController 实例
3. **状态共享**：不同页面可以共享同一个 ChatController 的状态
4. **内存优化**：避免创建多个不必要的 ChatController 实例

## 技术原理
- `Get.put()` 将 ChatController 注册到 GetX 的依赖注入容器中
- `Get.find()` 从容器中获取已注册的实例
- 这确保了应用中所有地方使用的都是同一个 ChatController 实例

## 影响的文件
- `lib/main.dart` - 添加了 ChatController 的注册
- `lib/screen/feature/chatbot_feature.dart` - 修改了实例获取方式
- `lib/screen/voice_settings_screen.dart` - 已经使用 Get.find()，无需修改
- `lib/screen/voice_test_screen.dart` - 已经使用 Get.find()，无需修改

修复完成后，应用中的 ChatController 将通过统一的依赖注入系统管理，解决了 "ChatController not found" 的错误。