import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/pages/data/constants.dart';
import 'package:spotired/src/pages/data/enums/navigation_pages.enum.dart';
import 'package:spotired/src/pages/data/providers/navitation_provider.dart';

class PlaylistPage extends StatefulWidget {
  final int playlistIndex;

  const PlaylistPage({
    super.key,
    required this.playlistIndex,
  });

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {

  late final Playlist _playlist;

  @override
  void initState() {
    _playlist = playlistController.playlists[widget.playlistIndex];
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 110, 110, 110),
              Colors.black.withOpacity(0.9),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // CONTENT
              ListView(
                children: [
                  Column(
                    children: [
                  
                      const SizedBox( height: 25 ),
                      
                      Container(
                        width: 250,
                        height: 250,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          color: Color.fromRGBO(35, 35, 35, 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              spreadRadius: 0.5,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.music_note_outlined,
                            size: 90,
                            color: Color.fromRGBO(125, 125, 125, 1),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PLAYLIST NAME
                        Text(
                          _playlist.name,
                          style: const TextStyle(
                            color: Constants.tertiaryColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox( height: 15 ),

                        Center(
                          child: OutlinedButton(
                            onPressed: _onClickAddSongs,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Constants.tertiaryColor,
                              side: const BorderSide(color: Constants.tertiaryColor),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Agregar canciones",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),

                        const SizedBox( height: 15 ),

                        // SONGS
                        if (_playlist.videos.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Canciones',
                              style: TextStyle(
                                color: Constants.tertiaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox( height: 15 ),

                            for (int f=0; f<_playlist.videos.length; f++)
                            GestureDetector(
                              onTap: () => _selectSong(videoController.getVideoByUrl(_playlist.videos[f])!),
                              child: Container(
                                color: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    videoController.getVideoByUrl(_playlist.videos[f])!.title,
                                    style: const TextStyle(
                                      color: Constants.tertiaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),

              Positioned(
                top: 12,
                left: 5,
                child: GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.transparent,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ),
    );
  }

  void _goBack() {
    navigationProvider.goToNavigationRootPage();
  }

  void _onClickAddSongs() {
    navigationProvider.changeNavigationPage(NavigationPagesEnum.search);
  }

  void _selectSong(VideoSong video) {
    videoController.startVideoAudio(video.url);
  }
}