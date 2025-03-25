import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/audio_controller.dart';

class AudioPlayerScreen extends StatelessWidget {
  const AudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reproductor de Audio")),
      body: ListenableBuilder(
        listenable: audioController,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                audioController.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Barra de progreso
              Slider(
                value: audioController.position.inSeconds.toDouble(),
                min: 0.0,
                max: audioController.duration.inSeconds.toDouble(),
                onChanged: (value) {
                  if (!audioController.player.playing) return;
          
                  audioController.seek(Duration(seconds: value.toInt()));
                },
              ),
          
              // Controles de reproducción
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(audioController.isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 50,
                    onPressed: () {
                      audioController.togglePlayPause();
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
