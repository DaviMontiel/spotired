import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/data/services/data_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as YT;

final playlistController = PlaylistController();

class PlaylistController with ChangeNotifier {
  // DATA
  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  // STATUS
  int _currentPlaylistPlaying = -1;
  int get currentPlaylistPlaying => _currentPlaylistPlaying;

  init() async {
    // GET SAVED PLAYLISTS
    String? playlistsString = await dataService.get(SharePreferenceValues.playlists);
    if (playlistsString == null) return;

    // Decodificar el JSON a una lista de mapas
    List<dynamic> decodedList = jsonDecode(playlistsString);

    // Convertir los mapas en objetos Playlist
    List<Playlist> playlists = decodedList.map((item) {
      return Playlist(
        name: item['name'],
        videos: List<String>.from(item['videos']),
      );
    }).toList();

    _playlists = playlists;
  }

  Playlist? findPlaylistByName(String name) {
    for (int f = 0; f < playlists.length; f++) {
      if (playlists[f].name == name) return _playlists[f];
    }

    return null;
  }

  void renamePlaylist(int index, String newName) async {
    Playlist playlist = playlists[index];

    playlist.name = newName;

    notifyListeners();
    savePlaylists();
  }

  Future<int?> addPlaylist(String name) async {
    final playlist = findPlaylistByName(name);
    if (playlist != null) return null;

    _playlists.add(Playlist(name: name, videos: []));
    notifyListeners();

    savePlaylists();
    return _playlists.length -1;
  }

  void removePlaylist(int playlistIndex) {
    // REMOVE
    _playlists.removeAt(playlistIndex);

    // NOTIFY
    notifyListeners();

    // SAVE
    savePlaylists();
  }

  void addVideoToPlaylist(int playlistIndex, VideoSong video) {
    // GET PLAYLIST
    final playlist = _playlists[playlistIndex];

    // FIND VIDEO-SONG
    VideoSong? existingVideo = videoController.getVideoByUrl(video.url);

    // CREATE VIDEO-SONG
    if (existingVideo == null) {
      existingVideo = video;
      videoController.addVideoSong(video);
      playlist.videos.add(existingVideo.url);
    }

    notifyListeners();

    savePlaylists();
  }

  void savePlaylists() async {
    final jsonString = jsonEncode(playlists.map((p) => p.toMap()).toList());
    await dataService.set(SharePreferenceValues.playlists, jsonString);
  }

  void setCurrentPlaylist(int index) {
    _currentPlaylistPlaying = index;
  }

  Future<void> fetchYouTubePlaylistWithoutAPIKey(String playlistId) async {
    final yt = YT.YoutubeExplode();
    
    try {
      final playlist = await yt.playlists.get(playlistId);
      final videos = yt.playlists.getVideos(playlistId);

      List<VideoSong> videoList = await videos.map((video) {
        return VideoSong(
          title: video.title,
          author: video.author,
          url: video.url.split('v=')[1],
          thumbnail: videoController.getVideoThumbnailFromYTUrl(video.url).split('vi/')[1],
          duration: video.duration!.inSeconds,
        );
      }).toList();

      final playlistIndex = await addPlaylist('YT: ${playlist.title}');

      // ADD SONGs
      for (var videoSong in videoList) {
        addVideoToPlaylist(playlistIndex!, videoSong);
      }
    } catch (e) {
      print('Error al obtener la playlist: $e');
    } finally {
      yt.close();
    }
  }
}
