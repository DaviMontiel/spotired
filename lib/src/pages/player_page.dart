import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotired/audio-player-screen.dart';
import 'package:spotired/src/controllers/audio_controller.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';

class PlayerPage extends StatefulWidget {
  final Playlist playlist;

  const PlayerPage({super.key, required this.playlist});

  @override
  _PlayerPlayerState createState() => _PlayerPlayerState();
}

class _PlayerPlayerState extends State<PlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: ListView.builder(
        itemCount: widget.playlist.videos.length,
        itemBuilder: (context, index) {
          final video = widget.playlist.videos[index];
          // return ListTile(
          //   leading: Image.network(video['thumbnail'] ?? ''),
          //   title: Text(video['title'] ?? ''),
          //   onTap: () {
          //     audioController.loadAudio(video['url']!);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const AudioPlayerScreen()),
          //     );
          //   },
          // );
        },
      ),
    );
  }
}
