import 'dart:io';

import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/video/enums/video_song_status.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  /// Ruta que entra deslizandose desde abajo.
  static Route<void> route() {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const PlayerPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {

  /// Segundo que el dedo esta arrastrando en la barra. Mientras se arrastra,
  /// manda este valor y no el del reproductor, o la barra daria tirones.
  double? _dragSecond;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<VideoSong?>(
        valueListenable: videoController.currentVideo,
        builder: (context, videoSong, child) {
          if (videoSong == null) return const SizedBox.shrink();

          return ValueListenableBuilder<Color>(
            valueListenable: videoController.currentVideoColor,
            builder: (context, videoColor, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.75, 1],
                    colors: [
                      _backdropColor(videoColor),
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _header(),

                        Expanded(
                          child: Center(
                            child: _artwork(videoSong),
                          ),
                        ),

                        const SizedBox(height: 30),

                        _titleAndAuthor(videoSong),

                        const SizedBox(height: 20),

                        _timeline(videoSong),

                        const SizedBox(height: 10),

                        _controls(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(right: 15, top: 10, bottom: 10),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          const Expanded(
            child: Text(
              'Reproduciendo ahora',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),

          // Equilibra el ancho del icono para que el titulo quede centrado.
          const SizedBox(width: 47),
        ],
      ),
    );
  }

  Widget _artwork(VideoSong videoSong) {
    final String? cachedImage = videoController.getVideoImageFromUrl(videoSong.url);
    if (cachedImage == null) {
      videoController.loadImageFromVideoUrl(videoSong.url);
    }

    return GestureDetector(
      onTap: () => _openOnYoutube(videoSong.url),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color.fromRGBO(35, 35, 35, 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: cachedImage != null
              ? Image.file(
                  File.fromUri(Uri.file(cachedImage)),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Image.network(
                  videoController.construyeVideoThumbnail(videoSong.thumbnail),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.expand();
                  },
                ),
          ),
        ),
      ),
    );
  }

  void _openOnYoutube(String videoId) {
    launchUrl(
      Uri.parse('https://www.youtube.com/watch?v=$videoId'),
      mode: LaunchMode.externalApplication,
    );
  }

  Widget _titleAndAuthor(VideoSong videoSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            videoSong.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: double.infinity,
          child: Text(
            videoSong.author,
            style: const TextStyle(
              color: Color.fromRGBO(255, 255, 255, 0.7),
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _timeline(VideoSong videoSong) {
    final int duration = videoSong.duration;
    final bool seekable = duration > 0;

    return ValueListenableBuilder<int>(
      valueListenable: videoController.currentPosition,
      builder: (context, position, child) {
        final double maxSeconds = seekable ? duration.toDouble() : 1;
        final double currentSeconds = _dragSecond ??
          position.toDouble().clamp(0, maxSeconds);

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: Colors.white,
                inactiveTrackColor: const Color.fromRGBO(255, 255, 255, 0.3),
                thumbColor: Colors.white,
                overlayColor: const Color.fromRGBO(255, 255, 255, 0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                min: 0,
                max: maxSeconds,
                value: currentSeconds,
                onChanged: !seekable
                  ? null
                  : (value) => setState(() => _dragSecond = value),
                onChangeEnd: !seekable
                  ? null
                  : (value) {
                      final bool wasPlaying =
                        videoController.videoSongStatus.value == VideoSongStatus.playing;

                      videoController.changeCurrentVideoSongPosition(
                        value.round(),
                        play: wasPlaying,
                      );

                      setState(() => _dragSecond = null);
                    },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(currentSeconds.round()),
                    style: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    seekable ? _formatTime(duration) : '--:--',
                    style: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconButton(
          icon: Icons.skip_previous_rounded,
          size: 45,
          onTap: videoController.playPreviousVideo,
        ),

        ValueListenableBuilder<VideoSongStatus>(
          valueListenable: videoController.videoSongStatus,
          builder: (context, videoSongStatus, child) {
            final bool isLoading = videoSongStatus == VideoSongStatus.loading;

            return GestureDetector(
              onTap: isLoading ? null : videoController.togglePlayPause,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                // El circulo blanco se mantiene mientras carga para que el
                // boton no cambie de tamano ni baile.
                child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Icon(
                      videoSongStatus == VideoSongStatus.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                      color: Colors.black,
                      size: 38,
                    ),
              ),
            );
          },
        ),

        StreamBuilder<Object?>(
          stream: videoController.audioPlayer.sequenceStateStream,
          builder: (context, snapshot) {
            return _iconButton(
              icon: Icons.skip_next_rounded,
              size: 45,
              enabled: videoController.hasNextVideo,
              onTap: videoController.playNextVideo,
            );
          },
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          color: enabled
            ? Colors.white
            : const Color.fromRGBO(255, 255, 255, 0.3),
          size: size,
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;

    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Oscurece los colores muy claros para que el texto blanco siga siendo
  /// legible sobre la parte alta del degradado.
  Color _backdropColor(Color color) {
    final double luminance =
      (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    if (luminance <= 0.55) return color;

    final double factor = 0.55 / luminance;

    return Color.fromARGB(
      255,
      (color.red * factor).round().clamp(0, 255).toInt(),
      (color.green * factor).round().clamp(0, 255).toInt(),
      (color.blue * factor).round().clamp(0, 255).toInt(),
    );
  }
}
