import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'apis/app_write.dart';
import 'controller/chat_controller.dart';
import 'helper/global.dart';
import 'helper/pref.dart';
import 'screen/splash_screen.dart';
import 'screen/voice_settings_screen.dart';
import 'screen/ai_provider_settings_screen.dart';
import 'screen/conversation_history_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init hive
  await Pref.initialize();

  // for app write initialization
  AppWrite.init();

  // 注册 ChatController 到 GetX 依赖注入系统
  Get.put(ChatController());

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,

      themeMode: Pref.defaultTheme,

      // 路由配置
      getPages: [
        GetPage(
          name: '/voice-settings',
          page: () => const VoiceSettingsScreen(),
        ),
        GetPage(
          name: '/ai-provider-settings',
          page: () => const AIProviderSettingsScreen(),
        ),
        GetPage(
          name: '/conversation-history',
          page: () => const ConversationHistoryScreen(),
        ),
      ],

      //dark
      darkTheme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          appBarTheme: const AppBarTheme(
            elevation: 1,
            centerTitle: true,
            titleTextStyle:
                TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          )),

      //light
      theme: ThemeData(
          useMaterial3: false,
          appBarTheme: const AppBarTheme(
            elevation: 1,
            centerTitle: true,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.blue),
            titleTextStyle: TextStyle(
                color: Colors.blue, fontSize: 20, fontWeight: FontWeight.w500),
          )),

      //
      home: const SplashScreen(),
    );
  }
}

extension AppTheme on ThemeData {
  //light text color
  Color get lightTextColor =>
      brightness == Brightness.dark ? Colors.white70 : Colors.black54;

  //button color
  Color get buttonColor =>
      brightness == Brightness.dark ? Colors.cyan.withValues(alpha: 0.5) : Colors.blue;
}
