import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/data/services/data_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final videoController = VideoController();

class VideoController with ChangeNotifier {

  // DATA
  Map<String, VideoSong> _videos = {};

  // STATUS
  final ValueNotifier<VideoSong?> currentVideo = ValueNotifier<VideoSong?>(null);
  final AudioPlayer audioPlayer = AudioPlayer();


  init() async {
    // GET SAVED VIDEOS
    String? playlistsString = await dataService.get(SharePreferenceValues.videos);
    if (playlistsString == null) return;

    // Decodificar el JSON a una lista de mapas
    final decodedJson = jsonDecode(playlistsString);

    // Convertir los mapas en objetos Playlist
    Map<String, VideoSong> videos = {};
    decodedJson.forEach((key, value) {
      videos[key] = VideoSong.fromMap(value);
    });

    _videos = videos;
  }

  VideoSong? getVideoByUrl(String url) {
    return _videos[url];
  }

  void addVideoSong(VideoSong video) {
    _videos[video.url] = video;
    notifyListeners();

    saveVideoSong();
  }

  void saveVideoSong() async {
    final jsonString = jsonEncode(
      _videos.map((key, value) => MapEntry(key, value.toMap()))
    );
    await dataService.set(SharePreferenceValues.videos, jsonString);
  }

  String getVideoThumbnail(String url) {
    // Extraer el ID del video de la URL
    RegExp regExp = RegExp(r'v=([a-zA-Z0-9_-]+)');
    Match? match = regExp.firstMatch(url);

    if (match != null) {
      // Si se encuentra un ID, devolver la URL de la miniatura
      String videoId = match.group(1)!;
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    } else {
      // Si no se encuentra un ID, retornar una URL de miniatura predeterminada
      return 'https://img.youtube.com/vi/default_thumbnail.jpg';
    }
  }

  void startVideoAudio(String videoUrl) async {
    currentVideo.value = getVideoByUrl(videoUrl);

    // STOP AUDIO
    audioPlayer.stop();

    final yt = YoutubeExplode();
    // final video = await yt.videos.get(videoUrl);

    final manifest = await yt.videos.streamsClient.getManifest('https://www.youtube.com/watch?v=$videoUrl');
    final audioStream = manifest.audioOnly.withHighestBitrate();

    await audioPlayer.setUrl(audioStream.url.toString());

    audioPlayer.play();
    yt.close();
  }
}