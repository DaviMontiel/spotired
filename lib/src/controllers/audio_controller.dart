import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final audioController = AudioController();

class AudioController with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  String _title = "Cargando...";
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  String get title => _title;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;

  AudioPlayer get player => _player;


  Future<void> loadAudio(String videoUrl) async {
    final yt = YoutubeExplode();
    final video = await yt.videos.get(videoUrl);
    _title = video.title;

    final manifest = await yt.videos.streamsClient.getManifest(videoUrl);
    final audioStream = manifest.audioOnly.withHighestBitrate();
    
    await _player.setUrl(audioStream.url.toString());

    _duration = _player.duration ?? Duration.zero;
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.setVolume(1);
      _player.play();
    }

    notifyListeners();
  }

  void seek(Duration newPosition) {
    _player.seek(newPosition);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
