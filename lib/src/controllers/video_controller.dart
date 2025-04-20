import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';
import 'package:spotired/src/data/models/video/enums/video_song_status.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/data/services/data_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart' as MiPlayList;

final videoController = VideoController();

class VideoController with ChangeNotifier {

  // DATA
  Map<String, VideoSong> _videos = {};

  // STATUS
  ConcatenatingAudioSource playlistSource = ConcatenatingAudioSource(children: []);
  List<String> _pendingVideos = [];
  final ValueNotifier<VideoSong?> currentVideo = ValueNotifier<VideoSong?>(null);
  final ValueNotifier<Color> currentVideoColor = ValueNotifier<Color>(Colors.black);
  final ValueNotifier<int> currentPosition = ValueNotifier<int>(0);
  final ValueNotifier<VideoSongStatus> videoSongStatus = ValueNotifier<VideoSongStatus>(VideoSongStatus.stopped);
  final AudioPlayer audioPlayer = AudioPlayer();
  String videoToPrepare = '';
  bool isChangingSong = false;
  late int _lastAudioPlayerIndex;
  bool _normalSecuence = true;
  bool _error = true;

  StreamSubscription<PlayerState>? _audioPlayerSubscription;
  StreamSubscription<SequenceState?>? _sequenceStateStream;
  StreamSubscription<int?>? _currentIndexStream;


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

    // CURRENT-VIDEO
    _prepareCurrentVideo();
  }

  VideoSong? getVideoByUrl(String url) {
    return _videos[url];
  }

  void addVideoSong(VideoSong video) {
    if (_videos.containsKey(video.url)) return;

    _videos[video.url] = video;
    notifyListeners();

    saveVideoSongs();
  }

  void saveVideoSongs() async {
    final jsonString = jsonEncode(
      _videos.map((key, value) => MapEntry(key, value.toMap()))
    );
    await dataService.set(SharePreferenceValues.videos, jsonString);
  }

  Future<void> removePlaylistOfVideoSong(String url, int playlistId) async {
    VideoSong? videoSong = getVideoByUrl(url);
    if (videoSong == null) return;

    // REMOVE PLAYLIST OF VIDEO-SONG
    videoSong.playlists.remove(playlistId);

    // REMOVE VIDEO-SONG
    final VideoSong? savedVideoSong = await _getSavedCurrentVideo();
    if (videoSong.playlists.isEmpty && savedVideoSong?.url != url) {
      _videos.remove(videoSong.url);
    }

    saveVideoSongs();
  }

  String getVideoThumbnailFromYTUrl(String url) {
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

  String construyeVideoThumbnail(String file) {
    return 'https://img.youtube.com/vi/$file';
  }

  Future<void> startVideoAudio(
    String videoUrl,
    {
      bool selected = false,
      bool play = true,
      bool prepareNextVideo = true
    }
  ) async {
    _sequenceStateStream?.cancel();
    _audioPlayerSubscription?.cancel();
    _currentIndexStream?.cancel();
    playlistSource.clear();
    playlistSource = ConcatenatingAudioSource(children: []);
    videoToPrepare = videoUrl;
    _lastAudioPlayerIndex = -1;
    _normalSecuence = selected;
    _error = false;

    await dataService.setBool(SharePreferenceValues.savedIsPlaylistSequential, selected);

    // STOP AUDIO
    audioPlayer.stop();
    isChangingSong = true;

    // GET VIDEO-SONG
    currentVideo.value = getVideoByUrl(videoUrl);
    final videoSong = currentVideo.value!;

    videoSongStatus.value = VideoSongStatus.loading;

    // GET AUDIO SOURCE OF VIDEO-SONG
    final audioSource = await _getAudioSourceFromVideoSong(videoSong);

    if (videoToPrepare != videoUrl) return;
    currentVideo.value = videoSong;

    // Si es la primera canción, configuramos el reproductor
    playlistSource.add(audioSource);
    await audioPlayer.setAudioSource(playlistSource);

    //* PREPARE LISTENERS
    // AUDIO STATUS LISTENER
    _audioPlayerSubscription = audioPlayer.playerStateStream.listen((state) {
      if (state.playing && hasFinishedCurrentVideoSong()) {
        videoSongStatus.value = VideoSongStatus.stopped;
      } else
      if (state.playing) {
        videoSongStatus.value = VideoSongStatus.playing;
      } else if (videoSongStatus.value == VideoSongStatus.playing) {
        videoSongStatus.value = VideoSongStatus.stopped;
      }
    });

    _currentIndexStream = audioPlayer.currentIndexStream.listen((index) {
      ProgressiveAudioSource nextAudioSource = playlistSource.children[index!] as ProgressiveAudioSource;

      // GET VIDEO-SONG
      currentVideo.value = getVideoByUrl(nextAudioSource.tag.id);

      // SAVE PENDING-VIDEOS
      dataService.setStringList(SharePreferenceValues.pendingVideos, [..._pendingVideos]);

      if (prepareNextVideo && _lastAudioPlayerIndex < index ) {
        _lastAudioPlayerIndex = index;
        // PREPARE NEXT VIDEO
        _prepareNextVideo(selected);
      }
    });

    audioPlayer.positionStream.listen((pos) {
      if (isChangingSong) {
        currentPosition.value = 0;
        return;
      }
      currentPosition.value = pos.inSeconds;
    });

    isChangingSong = false;
    if (!play) videoSongStatus.value = VideoSongStatus.paused;
    if (play && currentVideo.value?.url == videoSong.url) audioPlayer.play();
  }

  void togglePlayPause() {
    if (videoSongStatus.value == VideoSongStatus.playing) {
      audioPlayer.pause();
    } else if (hasFinishedCurrentVideoSong()) {
      audioPlayer.seek(const Duration(seconds: 0));
    } else if (videoSongStatus.value == VideoSongStatus.paused && _error) {
      startVideoAudio(currentVideo.value!.url, selected: _normalSecuence);
    } else {
      audioPlayer.play();
    }

    notifyListeners();
  }

  bool hasFinishedCurrentVideoSong() {
    return currentPosition.value + 3 >= currentVideo.value!.duration;
  }

  Future<void> saveOneTimeVideoSong(VideoSong videoSong) async {
    // REMOVE LAST SAVED
    VideoSong? savedVideoSong = await _getSavedCurrentVideo();
    if (savedVideoSong != null) {
      final videoSong = getVideoByUrl(savedVideoSong.url);

      if (videoSong!.playlists.isEmpty) {
        _videos.remove(videoSong.url);
      }
    }

    // ADD
    addVideoSong(videoSong);
    playlistController.setCurrentPlaylist(null);
  }

  String? _getRandomVideo() {
    if (_pendingVideos.isEmpty) {
      MiPlayList.Playlist playlist = playlistController.playlists[playlistController.currentPlaylistPlayingId]!;
      _pendingVideos = List.from(playlist.videos);

      // SAVE PENDING-VIDEOS
      dataService.setStringList(SharePreferenceValues.pendingVideos, [..._pendingVideos]);
    }

    if (_pendingVideos.isEmpty) return null;

    _pendingVideos.shuffle();
    return _pendingVideos.removeLast();
  }

  _prepareNextVideo(bool secuential) {
    if (secuential) {
      _prepareNextSecuentialVideo();
    } else {
      _prepareNextRandomVideo();
    }
  }

  void _prepareNextSecuentialVideo() {
    // GET THE CURRENT PLAYLIST
    MiPlayList.Playlist playlist = playlistController.playlists[playlistController.currentPlaylistPlayingId]!;

    // GET THE CURRENT VIDEO URL
    String? currentVideoUrl = currentVideo.value?.url;
    if (currentVideoUrl == null) return;

    // FIND THE INDEX OF THE CURRENT VIDEO IN THE PLAYLIST
    int currentIndex = playlist.videos.indexOf(currentVideoUrl);

    // DETERMINE THE INDEX OF THE NEXT VIDEO (IF LAST, GO BACK TO FIRST)
    int nextIndex = (currentIndex + 1) % playlist.videos.length;

    // GET THE NEXT VIDEO URL
    String nextVideoUrl = playlist.videos[nextIndex];

    // ADD NEXT VIDEO
    _addVideoSongToPlaylist(getVideoByUrl(nextVideoUrl)!);
  }

  _prepareNextRandomVideo() {
    String? nextVideoUrl = _getRandomVideo();

    // ADD NEXT VIDEO
    _addVideoSongToPlaylist(getVideoByUrl(nextVideoUrl!)!);
  }

  void playNextRandomVideo() {
    _pendingVideos = [];
    String? nextVideoUrl = _getRandomVideo();
    if (nextVideoUrl != null) {
      startVideoAudio(nextVideoUrl);
    }
  }

  _getAudioSourceFromVideoSong(VideoSong videoSong) async {
    String? audioUrl;
    try {
      audioUrl = await _getFinalUrlByYTUrl(videoSong.url);
      if (audioUrl == null) return;
    } catch (ex) {
      videoSongStatus.value = VideoSongStatus.paused;
      _error = true;
      print(ex);
    }

    // CONFIGURE audio_player WITH AudioSource.uri
    final audioSource = AudioSource.uri(
      Uri.parse(audioUrl!),
      tag: MediaItem(
        id: videoSong.url,
        title: videoSong.title,
        artist: videoSong.author,
      ),
    );

    return audioSource;
  }

  _addVideoSongToPlaylist(VideoSong videoSong) async {
    final audioSource = await _getAudioSourceFromVideoSong(videoSong);

    while (isChangingSong) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Agregar el audio a la playlist
    playlistSource.add(audioSource);
  }

  Future<String?> _getFinalUrlByYTUrl(String videoUrl) async {
    return await Isolate.run(() async {
      final YoutubeExplode yt = YoutubeExplode();
      try {
        // GET YT VIDEO MANIFEST
        final manifest = await yt.videos.streams.getManifest(videoUrl, ytClients: [ YoutubeApiClient.androidVr ]);
        final audioStream = manifest.audioOnly.withHighestBitrate();
        final audioUrl = audioStream.url.toString();

        return audioUrl;
      } finally {
        yt.close();
      }
    });
  }

  Future<void> _prepareCurrentVideo() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // GET SAVED CURRENT-VIDEO
    final savedVideoColor = await dataService.get(SharePreferenceValues.currentVideoColor);
    final savedPlaylistId = await dataService.getInt(SharePreferenceValues.currentPlaylistId);
    final savedIsPlaylistSequential = await dataService.getBool(SharePreferenceValues.savedIsPlaylistSequential);
    final savedVideoSong = await _getSavedCurrentVideo();

    // PREPARE PLAYLIST
    if (savedPlaylistId != null) {
      playlistController.setCurrentPlaylist(savedPlaylistId);

      if (savedIsPlaylistSequential == false) {
        final savedPendingVideos = await dataService.getStringList(SharePreferenceValues.pendingVideos);
        _pendingVideos = savedPendingVideos ?? [];
      }
    }

    // SET SAVED VIDEO COLOR
    if (savedVideoColor != null) {
      List<String> splitedColor = savedVideoColor.split('-');
      int r = int.parse(splitedColor[0]);
      int g = int.parse(splitedColor[1]);
      int b = int.parse(splitedColor[2]);
      Color color = Color.fromRGBO(r, g, b, 1);

      currentVideoColor.value = color;
    }

    // START VIDEO
    if (savedVideoSong != null) {
      startVideoAudio(
        savedVideoSong.url,
        play: false,
        selected: savedIsPlaylistSequential!,
        prepareNextVideo: savedPlaylistId != null,
      );
    }

    _loadCurrentVideoListener();
  }

  Future<VideoSong?> _getSavedCurrentVideo() async {
    // GET STR
    final str = await dataService.get(SharePreferenceValues.currentVideo);
    if (str == null) return null;

    // TO OBJ
    final Map<String, dynamic> jsonMap = json.decode(str);
    final videoSong = VideoSong.fromMap(jsonMap);

    return videoSong;
  }

  void _loadCurrentVideoListener() {
    currentVideo.addListener(() async {
      final video = currentVideo.value;
      if (video == null) return;

      print('--- ${video.title}');

      await _saveCurrentVideo(video);
      await _updatePalette();
    });
  }

  Future<void> _saveCurrentVideo(VideoSong videoSong) async {
    final str = json.encode(videoSong.toMap());
    await dataService.set(SharePreferenceValues.currentVideo, str);
  }

  Future<void> _updatePalette() async {
    // GET COLOR
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(
      NetworkImage(construyeVideoThumbnail(currentVideo.value!.thumbnail)),
      size: const Size(200, 100),
    );

    // SET COLOR
    final color = paletteGenerator.dominantColor?.color ?? Colors.grey;
    currentVideoColor.value = color;

    // SAVE COLOR
    await dataService.set(SharePreferenceValues.currentVideoColor, '${color.red}-${color.green}-${color.blue}');
  }

  @override
  void dispose() {
     audioPlayer.dispose();
     super.dispose();
  }
}