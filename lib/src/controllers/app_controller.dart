import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spotired/src/data/models/app/app_settings.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';
import 'package:spotired/src/data/services/data_service.dart';

final appController = AppController();

class AppController {

  // DATA
  final _url = 'https://drive.google.com/uc?export=download&id=1yy9d7hbfmHjbLeP0tJBJhFRRXOG_WTyF';
  AppSettings? appSettings;

  // STATUS
  ValueNotifier<bool> haveUpdate = ValueNotifier<bool>(false);


  init() async {
    // GET SAVED ACCESS-KEY
    final jsonAppSettings = await dataService.get(SharePreferenceValues.appSettings);

    // GENERATE ACCESS-KEY
    if (jsonAppSettings != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonAppSettings);
      appSettings = AppSettings.fromJson(jsonMap);

      _changeListeners(appSettings!);
    }
  }

  void load() async {
    // GET APP-SETTINGS
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode != 200) return;

    // RESPONSE TO OBJ
    final dynamic responseMap = json.decode(response.body);
    appSettings = AppSettings.fromJson(responseMap);

    _changeListeners(appSettings!);

    // SAVE
    await _saveAppSettings(appSettings!);
  }

  void _changeListeners(AppSettings appSettings) async {
    // HAVE UPDATE
    final packageInfo = await PackageInfo.fromPlatform();
    if (appSettings.currentVersion != packageInfo.version) {
      haveUpdate.value = true;
    }
  }

  Future<void> _saveAppSettings(AppSettings appSettings) async {
    final strData = json.encode(appSettings.toJson());
    await dataService.set(SharePreferenceValues.appSettings, strData);
  }
}