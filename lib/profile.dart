import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile {
  static final name = ValueNotifier<String?>(null);

  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getString('profile_name');
    name.value = (n == null || n.trim().isEmpty) ? null : n.trim();
  }

  static Future<void> setName(String n) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('profile_name', n.trim());
    name.value = n.trim();
  }
}
