import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class Pref {
  static late Box _box;

  static Future<void> initialize() async {
    //for initializing hive to use app directory
    // Hive.defaultDirectory = (await getApplicationDocumentsDirectory()).path;
    // _box = Hive.box(name: 'myData');

    await Hive.initFlutter();
    _box = await Hive.openBox('myData');
  }

  static bool get showOnboarding =>
      _box.get('showOnboarding', defaultValue: true);
  static set showOnboarding(bool v) => _box.put('showOnboarding', v);

  // Normal Way - Get
  // how to call
  // showOnboarding()

  // static bool showOnboarding() {
  //   return _box.get('showOnboarding', defaultValue: true);
  // }

  // Normal Way - Set
  // how to call
  // showOnboarding(false)

  // static bool showOnboarding(bool v) {
  //   _box.put('showOnboarding', v);
  // }

  //for storing theme data
  static bool get isDarkMode => _box.get('isDarkMode') ?? false;
  static set isDarkMode(bool v) => _box.put('isDarkMode', v);

  static ThemeMode get defaultTheme {
    final data = _box.get('isDarkMode');
    log('data: $data');
    if (data == null) return ThemeMode.system;
    if (data == true) return ThemeMode.dark;
    return ThemeMode.light;
  }

  // 通用的 get/set 方法
  static bool? getBool(String key) => _box.get(key);
  static Future<void> setBool(String key, bool value) async => await _box.put(key, value);
  
  static String? getString(String key) => _box.get(key);
  static Future<void> setString(String key, String value) async => await _box.put(key, value);
  
  static int? getInt(String key) => _box.get(key);
  static Future<void> setInt(String key, int value) async => await _box.put(key, value);
  
  static double? getDouble(String key) => _box.get(key);
  static Future<void> setDouble(String key, double value) async => await _box.put(key, value);
}
