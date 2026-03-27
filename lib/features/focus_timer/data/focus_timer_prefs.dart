import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class FocusTimerPrefs {
  static const _key = 'focus_timer_state_v1';

  static Future<Map<String, dynamic>?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> save(Map<String, dynamic> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(data));
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
