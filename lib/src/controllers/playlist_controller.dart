import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';
import 'package:spotired/src/data/services/data_service.dart';

final playlistController = PlaylistController();

class PlaylistController with ChangeNotifier {
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  init() async {
    // GET SAVED PLAYLISTS
    String? playlistsString = await dataService.get(SharePreferenceValues.playlists);
    if (playlistsString == null) return;

    // Decodificar el JSON a una lista de mapas
    List<dynamic> decodedList = jsonDecode(playlistsString);

    // Convertir los mapas en objetos Playlist
    List<Playlist> playlists = decodedList.map((item) {
      return Playlist(
        img: item['img'],
        name: item['name'],
        size: item['size'],
        videos: [],
      );
    }).toList();

    _playlists = playlists;
  }

  Playlist? findPlaylistByName(String name) {
    for (int f=0; f<playlists.length; f++) {
      if (playlists[f].name == name) return _playlists[f];
    }

    return null;
  }

  void addPlaylist(String name) async {
    final playlist = findPlaylistByName(name);
    if (playlist != null) return;

    _playlists.add(Playlist(name: name, videos: []));
    notifyListeners();

    savePlaylists();
  }

  void removePlaylist(int playlistIndex) {
    // REMOVE
    _playlists.removeAt(playlistIndex);

    // NOTIFY
    notifyListeners();

    // SAVE
    savePlaylists();
  }

  void addVideoToPlaylist(String playlistName, Map<String, String> video) {
    // final playlist = _playlists.firstWhere((pl) => pl.name == playlistName);
    final playlist = _playlists[0];
    // playlist.videos.add(video);
    notifyListeners();

    savePlaylists();
  }

  void savePlaylists() async {
    final jsonString = jsonEncode(playlists.map((p) => p.toMap()).toList());
    await dataService.set(SharePreferenceValues.playlists, jsonString);
  }
}
