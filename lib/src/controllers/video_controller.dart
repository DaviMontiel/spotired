import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';
import 'package:spotired/src/data/models/video/enums/video_song_status.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/data/services/data_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart' as MiPlayList;
import 'package:http/http.dart' as http;

final videoController = VideoController();

class VideoController with ChangeNotifier {

  // DATA
  Map<String, VideoSong> _videos = {};

  // STATUS
  final Map<String, String> _videosImages = {};
  final Map<String, double?> downloadVideosProgress = {};
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

  String? getVideoImageFromUrl(String url) {
    return _videosImages[url];
  }

  Future<File?> getVideoImageFileFromUrl(String url) async {
    String storageImageName = 'video-image-$url.jpg';

    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/$storageImageName';
    final storageImageFile = File(localPath);
    final exists = await storageImageFile.exists();
    if (!exists) return null;

    return storageImageFile;
  }

  void addVideoSong(VideoSong video) {
    if (_videos.containsKey(video.url)) return;

    _videos[video.url] = video;
    loadImageFromVideoUrl(video.url);
    notifyListeners();

    saveVideoSongs();
  }

  Future<void> saveVideoSongs() async {
    final jsonString = jsonEncode(
      _videos.map((key, value) => MapEntry(key, value.toMap()))
    );
    await dataService.set(SharePreferenceValues.videos, jsonString);
  }

  Future<void> removePlaylistOfVideoSong(String url, int playlistId) async {
    VideoSong? videoSong = getVideoByUrl(url);
    if (videoSong == null) return;

    // QUIT DOWNLOADS COUNT
    bool otherPlaylistHasVideoWithDownloadActivated = false;
    for (var videoPlaylistId in videoSong.playlists) {
      MiPlayList.Playlist playlist = playlistController.playlists[videoPlaylistId]!;

      if (playlist.id != playlistId && playlist.downloadVideos) {
        otherPlaylistHasVideoWithDownloadActivated = true;
      }
    }
    if (!otherPlaylistHasVideoWithDownloadActivated) {
      downloadVideosProgress.remove(videoSong.url);
    }

    if (videoSong.playlists.isNotEmpty) {
      playlistController.savePlaylists();
    }

    // REMOVE PLAYLIST OF VIDEO-SONG
    videoSong.playlists.remove(playlistId);

    // REMOVE VIDEO-SONG
    final VideoSong? savedVideoSong = await _getSavedCurrentVideo();
    if (videoSong.playlists.isEmpty) {
      if (savedVideoSong?.url != url) {
        await removeVideoSong(videoSong.url);
      }
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
      int? startSecond,
      bool prepareNextVideo = true
    }
  ) async {
    // CHECK IF WE ARE STARTING A DIFFERENT VIDEO
    final lastVideoSong = await _getSavedCurrentVideo();
    if (lastVideoSong != null && lastVideoSong.url != videoUrl) {
      await dataService.clear(SharePreferenceValues.currentVideoSecond);
    }

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

    currentPosition.value = startSecond ?? 0;
    videoSongStatus.value = VideoSongStatus.loading;

    // GET AUDIO SOURCE OF VIDEO-SONG
    final audioSource = await _getAudioSourceFromVideoSong(videoSong);
    if (audioSource == null) return;

    if (videoToPrepare != videoUrl) return;
    currentVideo.value = videoSong;

    // Si es la primera canción, configuramos el reproductor
    playlistSource.add(audioSource);
    await audioPlayer.setAudioSource(playlistSource, preload: false);

    //* PREPARE LISTENERS
    // AUDIO STATUS LISTENER
    _audioPlayerSubscription = audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
        videoSongStatus.value = VideoSongStatus.playing;
      } else if (videoSongStatus.value == VideoSongStatus.playing) {
        videoSongStatus.value = VideoSongStatus.stopped;
      }
    });

    _currentIndexStream = audioPlayer.currentIndexStream.listen((index) {
      if (index == null) return;

      ProgressiveAudioSource nextAudioSource = playlistSource.children[index] as ProgressiveAudioSource;

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

    audioPlayer.positionStream.listen((pos) async {
      if (isChangingSong) {
        currentPosition.value = 0;
        return;
      }
      currentPosition.value = pos.inSeconds;

      // SAVE CURRENT SECOND
      await dataService.setInt(SharePreferenceValues.currentVideoSecond, pos.inSeconds);
    });

    isChangingSong = false;

    // SET SECOND TO AUDIO
    if (startSecond != null) {
      await audioPlayer.seek(Duration(seconds: startSecond));
    }

    if (!play) videoSongStatus.value = VideoSongStatus.paused;
    if (play && currentVideo.value?.url == videoSong.url) audioPlayer.play();
  }

  void togglePlayPause() {
    if (videoSongStatus.value == VideoSongStatus.playing) {
      audioPlayer.pause();
    } else if (videoSongStatus.value == VideoSongStatus.paused && _error) {
      startVideoAudio(currentVideo.value!.url, selected: _normalSecuence);
    } else {
      audioPlayer.play();
    }

    notifyListeners();
  }

  void changeCurrentVideoSongPosition(int second, { bool play = false }) {
    audioPlayer.seek(Duration(seconds: second));

    if (play) {
      audioPlayer.play();
    } else {
      audioPlayer.pause();
    }
  }

  Future<void> saveOneTimeVideoSong(VideoSong videoSong) async {
    // REMOVE LAST SAVED
    VideoSong? savedVideoSong = await _getSavedCurrentVideo();
    if (savedVideoSong != null) {
      final videoSong = getVideoByUrl(savedVideoSong.url);

      if (videoSong!.playlists.isEmpty) {
        await removeVideoSong(videoSong.url);
      }
    }

    // ADD
    addVideoSong(videoSong);
    playlistController.setCurrentPlaylist(null);
  }

  Future<void> removeVideoSong(String videoSongUrl) async {
    try {
      await _removeFileImg(videoSongUrl);
      await removeVideoSongAudio(videoSongUrl);
      _videos.remove(videoSongUrl);
      _videosImages.remove(videoSongUrl);

      if (_pendingVideos.contains(videoSongUrl)) {
        _pendingVideos.remove(videoSongUrl);
        await dataService.setStringList(SharePreferenceValues.pendingVideos, [..._pendingVideos]);
      }

      int? indexToRemove;
      for (int i = 0; i < playlistSource.children.length; i++) {
        final source = playlistSource.children[i];
        if (source is ProgressiveAudioSource) {
          if (source.tag.id == videoSongUrl) {
            indexToRemove = i;
            break;
          }
        } else if (source is UriAudioSource) {
          if (source.tag.id == videoSongUrl) {
            indexToRemove = i;
            break;
          }
        }
      }

      if (indexToRemove != null) {
        await playlistSource.removeAt(indexToRemove);

        final currentIndex = audioPlayer.currentIndex ?? 0;
        if (indexToRemove > currentIndex) {
          _prepareNextVideo(_normalSecuence, exclude: videoSongUrl);
        }
      }
    } catch (e) {
      print('Error al eliminar video: $e');
    }
  }

  Future<File?> loadImageFromVideoUrl(String videoUrl) async {
    // GET VIDEO-SONG
    final video = _videos[videoUrl];
    if (video == null) return null;

    notifyToCurrentVideo() {
      if (videoUrl == currentVideo.value?.url ) {
        currentVideo.value = currentVideo.value!.copy();
      }
    }

    // GET FROM STORAGE
    final storageImageFile = await getVideoImageFileFromUrl(videoUrl);
    if (storageImageFile != null) {
      _videosImages[videoUrl] = storageImageFile.path;

      notifyToCurrentVideo();
      notifyListeners();

      return storageImageFile;
    }

    // DOWNLOAD
    try {
      final thumbnailUrl = construyeVideoThumbnail(video.thumbnail);
      final response = await http.get(Uri.parse(thumbnailUrl));
      if (response.statusCode != 200) throw Exception('Failed to download image');

      // SAVE
      File file = await saveImageToFile(response.bodyBytes, videoUrl);
      _videosImages[videoUrl] = file.path;

      notifyToCurrentVideo();
      notifyListeners();

      return file;
    } catch (e) {
      print('Error converting image to base64: $e');
    }

    return null;
  }

  getListFromColor(Color color) {
    return [ color.red, color.green, color.blue ];
  }

  Future<void> removeVideoSongAudio(String videoSongUrl) async {
    // GET VIDEO-SONG
    VideoSong? videoSong = getVideoByUrl(videoSongUrl);
    if (videoSong == null) return;

    // REMOVE AUDIO
    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/audio-${videoSong.url}.mp3';
    final audioFile = File(localPath);

    // DELETE IF EXISTS
    if (await audioFile.exists()) {
      await audioFile.delete();
    }
    await dataService.clearCustom('video-audio-$videoSongUrl');

    videoSong.downloaded = false;
    await saveVideoSongs();

    notifyListeners();
  }

  String? _getRandomVideo() {
    if (_pendingVideos.isEmpty) {
      MiPlayList.Playlist playlist = playlistController.playlists[playlistController.currentPlaylistPlayingId]!;
      _pendingVideos = List.from(playlist.videos);

      // SAVE PENDING-VIDEOS
      _pendingVideos.shuffle();
      dataService.setStringList(SharePreferenceValues.pendingVideos, [..._pendingVideos]);
    }

    if (_pendingVideos.isEmpty) return null;

    return _pendingVideos.removeLast();
  }

  _prepareNextVideo(bool secuential, { String? exclude }) {
    if (secuential) {
      _prepareNextSecuentialVideo(excludeUrl: exclude);
    } else {
      _prepareNextRandomVideo();
    }
  }

  void _prepareNextSecuentialVideo({ String? excludeUrl }) {
    // GET THE CURRENT PLAYLIST
    MiPlayList.Playlist? playlist = playlistController.playlists[playlistController.currentPlaylistPlayingId];
    if (playlist == null) return;

    // GET THE CURRENT VIDEO URL
    String? currentVideoUrl = currentVideo.value?.url;
    if (currentVideoUrl == null) return;

    // FIND THE INDEX OF THE CURRENT VIDEO IN THE PLAYLIST
    int currentIndex = playlist.videos.indexOf(currentVideoUrl);

    // DETERMINE THE INDEX OF THE NEXT VIDEO (IF LAST, GO BACK TO FIRST)
    int nextIndex = (currentIndex + 1) % playlist.videos.length;

    // GET THE NEXT VIDEO URL
    String nextVideoUrl = playlist.videos.where((item) => item != excludeUrl).toList()[nextIndex];

    // ADD NEXT VIDEO
    _addVideoSongToPlaylist(getVideoByUrl(nextVideoUrl)!);
  }

  _prepareNextRandomVideo() {
    String? nextVideoUrl = _getRandomVideo();
    VideoSong? videoSong = getVideoByUrl(nextVideoUrl!);
    if (videoSong == null) return;

    // ADD NEXT VIDEO
    _addVideoSongToPlaylist(videoSong);
  }

  void playNextRandomVideo() {
    _pendingVideos = [];
    String? nextVideoUrl = _getRandomVideo();
    if (nextVideoUrl != null) {
      startVideoAudio(nextVideoUrl);
    }
  }

  Future<void> downloadVideoSong(VideoSong videoSong) async {
    String? audioUrl;
    bool exit = false;

    while (!exit) {
      try {
        if (downloadVideosProgress[videoSong.url] != null) return;

        // GET VIDEO-URL
        audioUrl ??= await _getFinalUrlByYTUrl(videoSong.url);
        if (audioUrl == null) return;
        if (videoSong.downloaded) return;

        // GET DIR TO SAVE
        final dir = await getApplicationDocumentsDirectory();
        final localPath = '${dir.path}/audio-${videoSong.url}.mp3';
        final audioFile = File(localPath);

        // GET FILE SIZE
        int downloadedLength = 0;
        if (await audioFile.exists()) {
          downloadedLength = await audioFile.length();
        }

        // INIT PROGRESS
        downloadVideosProgress[videoSong.url] = (downloadedLength.toDouble());
        notifyListeners();

        // Configurar solicitud con Range header si hay datos
        final request = http.Request('GET', Uri.parse(audioUrl));
        request.headers['Range'] = 'bytes=$downloadedLength-';

        final response = await request.send();
        if (response.statusCode != 200 && response.statusCode != 206) {
          throw Exception('Error en la respuesta del servidor: ${response.statusCode}');
        }

        // GET TOTAL
        int? totalBytes;
        if (response.headers.containsKey('content-range')) {
          final contentRange = response.headers['content-range'];
          final totalMatch = RegExp(r'/(\d+)$').firstMatch(contentRange ?? '');
          if (totalMatch != null) {
            totalBytes = int.parse(totalMatch.group(1)!);
          }
        } else {
          totalBytes = response.contentLength != null ? response.contentLength! + downloadedLength : null;
        }

        final fileStream = audioFile.openWrite(mode: FileMode.append);
        int receivedBytes = downloadedLength;

        late StreamSubscription<List<int>> subscription;
        final completer = Completer<void>();

        subscription = response.stream.listen(
          (List<int> chunk) async {
            bool somePlaylistHasVideoSongWithDownloads = playlistController.containsDownloadedPlaylistWithVideo(videoSong.url);
            if (
              !somePlaylistHasVideoSongWithDownloads ||
              getVideoByUrl(videoSong.url) == null ||
              !downloadVideosProgress.containsKey(videoSong.url)
            ) {
              downloadVideosProgress.remove(videoSong.url);
              await subscription.cancel();
              await fileStream.close();
              completer.completeError(Exception('Descarga cancelada'));
              exit = true;
              return;
            }

            fileStream.add(chunk);
            receivedBytes += chunk.length;

            if (totalBytes != null) {
              double progress = (receivedBytes / totalBytes) * 100;
              downloadVideosProgress[videoSong.url] = progress;
            }
            notifyListeners();
          },
          onDone: () async {
            await fileStream.close();
            await dataService.setCustom('video-audio-${videoSong.url}', audioFile.path);
            videoController.downloadVideosProgress.remove(videoSong.url);
            _videos[videoSong.url]!.downloaded = true;

            saveVideoSongs();
            notifyListeners();
            completer.complete();
          },
          onError: (e) async {
            await subscription.cancel();
            await fileStream.close();
            completer.completeError(e);
          },
          cancelOnError: true,
        );

        await completer.future;
        exit = true;
      } catch (e) {
        downloadVideosProgress.remove(videoSong.url);
        await Future.delayed(const Duration(seconds: 3)); // Espera antes de reintentar
      }
    }
  }

  Future<AudioSource?> _getAudioSourceFromVideoSong(VideoSong videoSong) async {
    try {
      // Buscar ruta local del audio guardado
      String? savedPath = await dataService.getCustom('video-audio-${videoSong.url}');

      // CONFIGURE audio_player WITH AudioSource.uri
      File? cachedImage = await loadImageFromVideoUrl(videoSong.url);

      if (savedPath != null) {
        // Usar archivo local
        return AudioSource.uri(
          Uri.file(savedPath),
          tag: MediaItem(
            id: videoSong.url,
            title: videoSong.title,
            artist: videoSong.author,
            artUri: cachedImage != null
              ? Uri.file(cachedImage.path)
              : null,
          ),
        );
      }

      // USE YT STREAM
      String? audioUrl = await _getFinalUrlByYTUrl(videoSong.url);
      if (audioUrl == null) return null;

      final audioSource = AudioSource.uri(
        Uri.parse(audioUrl),
        tag: MediaItem(
          id: videoSong.url,
          title: videoSong.title,
          artist: videoSong.author,
          artUri: cachedImage != null
            ? Uri.file(cachedImage.path)
            : null,
        ),
      );

      return audioSource;
    } catch (ex) {
      videoSongStatus.value = VideoSongStatus.paused;
      _error = true;
      return null;
    }
  }

  Future<File> saveImageToFile(Uint8List imageData, String videoUrl) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/video-image-$videoUrl.jpg');
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(imageData);
    return file;
  }

  Future<void> _removeFileImg(String videoSongUrl) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/video-image-$videoSongUrl.jpg');
    if (await file.exists()) {
      await file.delete();
    }
  }

  _addVideoSongToPlaylist(VideoSong videoSong) async {
    final audioSource = await _getAudioSourceFromVideoSong(videoSong);
    if (audioSource == null) return;

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
    final savedVideoSecond = await dataService.getInt(SharePreferenceValues.currentVideoSecond);
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
        startSecond: savedVideoSecond,
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

      await _saveCurrentVideo(video);
      await _updatePalette();
    });
  }

  Future<void> _saveCurrentVideo(VideoSong videoSong) async {
    final str = json.encode(videoSong.toMap());
    await dataService.set(SharePreferenceValues.currentVideo, str);
  }

  Future<void> _updatePalette() async {
    try {
      // GET IMG
      final savedImage = getVideoImageFromUrl(currentVideo.value!.url);

      // CREATE IMAGE PROVIDER
      final ImageProvider imageProvider = savedImage == null
        ? NetworkImage(construyeVideoThumbnail(currentVideo.value!.thumbnail))
        : FileImage(File.fromUri(Uri.file(savedImage)));

      // WAIT UNTIL IMAGE IS LOADED OR FAILS
      final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
      final Completer<void> completer = Completer<void>();

      stream.addListener(
        ImageStreamListener(
          (ImageInfo info, bool _) {
            completer.complete();
          },
          onError: (dynamic error, StackTrace? stackTrace) {
            completer.completeError(error, stackTrace);
          },
        ),
      );

      await completer.future;

      // GET COLOR
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(200, 100),
      );
      final color = paletteGenerator.dominantColor?.color ?? Colors.grey;

      // SET COLOR
      currentVideoColor.value = color;

      // SAVE COLOR
      await dataService.set(
        SharePreferenceValues.currentVideoColor,
        '${color.red}-${color.green}-${color.blue}',
      );
    } catch (e) {}
  }

  @override
  void dispose() {
     audioPlayer.dispose();
     super.dispose();
  }
}