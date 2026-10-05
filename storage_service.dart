import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String attendanceKey = 'worker_pay_attendance';
  static const String settingsKey = 'worker_pay_settings';

  Future<void> saveAttendance(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(attendanceKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>> loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(attendanceKey);

    if (data == null || data.isEmpty) {
      return {};
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(settingsKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(settingsKey);

    if (data == null || data.isEmpty) {
      return {};
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (_) {
      return {};
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(attendanceKey);
    await prefs.remove(settingsKey);
  }
}
