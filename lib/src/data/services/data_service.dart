import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';

final dataService = DataService();

class DataService {
  Future<void> set(SharePreferenceValues key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.value, data);
  }

  Future<String?> get(SharePreferenceValues key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key.value);
  }
}