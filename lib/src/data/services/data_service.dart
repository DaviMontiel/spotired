import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';

final dataService = DataService();

class DataService {
  Future<void> set(SharePreferenceValues key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.value, data);
  }

  Future<void> setInt(SharePreferenceValues key, int data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key.value, data);
  }

  Future<void> setBool(SharePreferenceValues key, bool data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key.value, data);
  }

  Future<void> setStringList(SharePreferenceValues key, List<String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key.value, data);
  }

  Future<void> setCustom(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  Future<String?> get(SharePreferenceValues key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key.value);
  }

  Future<int?> getInt(SharePreferenceValues key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key.value);
  }

  Future<bool?> getBool(SharePreferenceValues key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key.value);
  }

  Future<List<String>?> getStringList(SharePreferenceValues key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key.value);
  }


  Future<String?> getCustom(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<bool?> clear(SharePreferenceValues key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key.value);
  }

  Future<bool?> clearCustom(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }
}