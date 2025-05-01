import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
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
    // REMOVE PLAYLISTS
    playlistsFunctions();

    // DOWNLOAD PLAYLISTS
    _downloadPlaylists();

    // GET APP-SETTINGS
    http.Response? response;
    try {
      response = await http.get(Uri.parse(_url));
    } catch (ex) {}

    if (response?.statusCode != 200) return;

    // RESPONSE TO OBJ
    final dynamic responseMap = json.decode(response!.body);
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

  Future<void> playlistsFunctions() async {
    playlistController.removePlaylists();
    
    for (var playlist in playlistController.allowedPlaylists.values) {
      if (!playlist.deleteAudios) continue;

      // DELETE AUDIOS
      await playlistController.removeDownloadedSongsFromPlaylist(playlist.id);
    }
  }

  Future<void> _downloadPlaylists() async {
    playlistController.downloadPlaylists();
  }
}