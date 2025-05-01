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
  Map<int, Playlist> _playlists = {};
  Map<int, Playlist> get playlists => _playlists;
  Map<int, Playlist> get allowedPlaylists {
    return Map.fromEntries(
      _playlists.entries.where((entry) => entry.value.delete == false),
    );
  }

  // STATUS
  int? _currentPlaylistPlayingId;
  int? get currentPlaylistPlayingId => _currentPlaylistPlayingId;

  init() async {
    // GET SAVED PLAYLISTS
    String? playlistsString = await dataService.get(SharePreferenceValues.playlists);
    if (playlistsString == null) return;

    // Decodificar el JSON a una lista de mapas
    final decodedList = jsonDecode(playlistsString);

    // Convertir los mapas en objetos Playlist
    Map<int, Playlist> playlists = {};
    decodedList.forEach((key, value) {
      playlists[int.parse(key)] = Playlist.fromMap(value);
    });

    _playlists = playlists;
  }

  Playlist? findPlaylistByName(String name) {
    for (final entry in playlists.entries) {
      if (entry.value.name == name) return entry.value;
    }

    return null;
  }

  List<Playlist> getPlaylistsOfVideoSong(String url) {
    List<Playlist> playlists = [];
    for (final entry in this.playlists.entries) {
      if (entry.value.videos.contains(url)) {
        playlists.add(entry.value);
      }
    }

    return playlists;
  }

  void renamePlaylist(int id, String newName) async {
    Playlist? playlist = playlists[id];
    if (playlist == null) return;

    playlist.name = newName;

    notifyListeners();
    savePlaylists();
  }

  Future<int?> addPlaylist(String name) async {
    final int playlistId = playlists.values.isNotEmpty
      ? playlists.values.last.id + 1
      : 0;

    _playlists.addAll({
      playlistId: Playlist(id: playlistId, name: name, videos: [])
    });
    notifyListeners();

    savePlaylists();
    return playlistId;
  }

  Future<void> removePlaylist(int playlistid, { bool setDelete = true }) async {
    // GET PLAYLIST
    Playlist? playlist = playlists[playlistid];
    if (playlist == null) return;

    // SET 'DELETE' TO TRUE
    if (setDelete) {
      playlist.delete = true;
      await savePlaylists();
    }

    // REMOVE VIDEO-SONGS
    final videosCopy = List<String>.from(_playlists[playlistid]!.videos);
    for (final videoUrl in videosCopy) {
      removeVideoOfPlaylist(playlistid, videoUrl);
      await videoController.removePlaylistOfVideoSong(videoUrl, playlistid);
    }

    // REMOVE PLAYLIST
    _playlists.remove(playlistid);

    // NOTIFY
    notifyListeners();

    // SAVE
    savePlaylists();
  }

  void addVideoToPlaylist(int playlistid, VideoSong video) {
    // GET PLAYLIST
    final playlist = _playlists[playlistid]!;

    // FIND VIDEO-SONG
    VideoSong? existingVideo = videoController.getVideoByUrl(video.url);

    // CREATE VIDEO-SONG
    if (existingVideo == null) {
      existingVideo = video;
      videoController.addVideoSong(video);
    }

    // ADD
    existingVideo.playlists.add(playlistid);
    playlist.videos.add(existingVideo.url);

    // DOWNLOAD
    if (playlist.downloadVideos) {
      if (!video.downloaded) {
        videoController.downloadVideoSong(video);
      }
    }

    notifyListeners();

    videoController.saveVideoSongs();
    savePlaylists();
  }

  Future<void> removeVideoOfPlaylist(int playlistid, String url) async {
    // GET PLAYLIST
    final playlist = _playlists[playlistid]!;

    // REMOVE
    await videoController.removePlaylistOfVideoSong(url, playlistid);
    playlist.videos.remove(url);

    notifyListeners();

    savePlaylists();
  }

  Future<void> savePlaylists() async {
    final jsonString = jsonEncode(
      playlists.map((key, value) => MapEntry(key.toString(), value.toMap()))
    );
    await dataService.set(SharePreferenceValues.playlists, jsonString);
  }

  void setCurrentPlaylist(int? id) {
    _currentPlaylistPlayingId = id;
    if (id != null) {
      dataService.setInt(SharePreferenceValues.currentPlaylistId, id);
    } else {
      dataService.clear(SharePreferenceValues.currentPlaylistId);
    }
  }

  Future<void> fetchYouTubePlaylistWithoutAPIKey(String playlistYtId) async {
    final yt = YT.YoutubeExplode();
    
    try {
      final playlist = await yt.playlists.get(playlistYtId);
      final videos = yt.playlists.getVideos(playlistYtId);

      List<VideoSong> videoList = await videos.map((video) {
        // print('--- AUTHOR: ${video.author}');
        // print('--- URL: ${video.url.split('v=')[1]}');
        // print('--- THUMBNAIL: ${videoController.getVideoThumbnailFromYTUrl(video.url).split('vi/')[1]}');
        // print('--- DURATION: ${video.duration!.inSeconds}');
        // print('-------------------');
        return VideoSong(
          title: video.title,
          author: video.author,
          url: video.url.split('v=')[1],
          thumbnail: videoController.getVideoThumbnailFromYTUrl(video.url).split('vi/')[1],
          duration: video.duration!.inSeconds,
        );
      }).toList();

      final playlistId = await addPlaylist('YT: ${playlist.title}');

      // ADD SONGs
      for (var videoSong in videoList) {
        addVideoToPlaylist(playlistId!, videoSong);
      }
    } catch (e) {
      print('Error al obtener la playlist: $e');
    } finally {
      yt.close();
    }
  }

  Future<void> removePlaylists() async {
    for (final playlist in _playlists.values) {
      if (!playlist.delete) continue;

      playlistController.removePlaylist(playlist.id, setDelete: false);
    }
  }

  Future<void> downloadPlaylists() async {
    for (final playlist in _playlists.values) {
      if (!playlist.downloadVideos || playlist.delete) continue;

      playlistController.downloadPlaylist(playlist.id);
    }
  }

  Future<void> downloadPlaylist(int playlistId) async {
    Playlist playlist = _playlists[playlistId]!;

    double downloadedVideos = playlistController.getDownloadedVideosOfPlaylistCount(playlist.id);
    if (playlist.downloadVideos && playlist.videos.length == downloadedVideos) return;

    playlist.downloadVideos = true;
    notifyListeners();
    savePlaylists();

    for (int f=0; f<playlist.videos.length; f++) {
      // GET VIDEO-SONG
      VideoSong videoSong = videoController.getVideoByUrl(playlist.videos[f])!;
      if (videoSong.downloaded) continue;

      // DOWNLOAD
      videoController.downloadVideoSong(videoSong);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  bool containsDownloadedPlaylistWithVideo(String videoId) {
    return allowedPlaylists.values.any((playlist) {
      if (playlist.downloadVideos == true && playlist.videos.contains(videoId)) {
        return true;
      }

      return false;
    });
  }

  Future<void> disablePlaylistAutoDownloads(int playlistId) async {
    // GET
    Playlist? playlist = playlists[playlistId];
    if (playlist == null) return;

    // EDIT
    playlist.downloadVideos = false;

    notifyListeners();

    // SAVE
    await savePlaylists();
  }

  Future<void> removeDownloadedSongsFromPlaylist(int playlistId, { bool setDelete = true }) async {
    // GET
    Playlist? playlist = playlists[playlistId];
    if (playlist == null) return;

    if (setDelete) {
      playlist.deleteAudios = true;
      await savePlaylists();
    }

    if (!playlist.deleteAudios) return;

    for (var f=0; f<playlist.videos.length; f++) {
      // GET VIDEO-SONG
      VideoSong videoSong = videoController.getVideoByUrl(playlist.videos[f])!;
      bool somePlaylistHasVideoSongWithDownloads = playlistController.containsDownloadedPlaylistWithVideo(videoSong.url);
      if (!(
        videoSong.downloaded &&
        !somePlaylistHasVideoSongWithDownloads
      )) continue;

      // REMOVE AUDIO
      await videoController.removeVideoSongAudio(videoSong.url);
    }

    playlist.deleteAudios = false;
    await savePlaylists();
  }

  double getDownloadedVideosOfPlaylistCount(int playlistId) {
    // GET PLAYLIST
    Playlist? playlist = _playlists[playlistId];
    if (playlist == null) return -1;

    double count = 0;

    for (int f=0; f<playlist.videos.length; f++) {
      VideoSong videoSong = videoController.getVideoByUrl(playlist.videos[f])!;
      if (videoSong.downloaded) {
        count += 1;
      }
    }

    return count;
  }
}
