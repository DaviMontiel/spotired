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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
              
                  // Playlist Cover
                  Center(
                    child: Container(
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
                  ),
              
                  const SizedBox(height: 20),
              
                  // PLAY LIST NAME
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _playlist.name,
                      style: const TextStyle(
                        color: Constants.tertiaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 15),
              
                  // ADD SONG, PLAY
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      children: [
                        Center(
                          child: OutlinedButton(
                            onPressed: _onClickAddSongs,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Constants.tertiaryColor,
                              side: const BorderSide(color: Constants.tertiaryColor),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Agregar canciones", style: TextStyle(fontSize: 18)),
                          ),
                        ),
              
                        Positioned(
                          right: 0,
                          bottom: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: _onClickPlayBtn,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Constants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.black, size: 35),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              
                  const SizedBox(height: 15),
              
                  // SONGs LIST
                  if (_playlist.videos.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ValueListenableBuilder<VideoSong?>(
                          valueListenable: videoController.currentVideo,
                          builder: (context, value, child) {
                            return ListView.builder(
                              itemCount: _playlist.videos.length,
                              itemBuilder: (context, index) {
                                final videoSong = videoController.getVideoByUrl(_playlist.videos[index]);
                                if (videoSong == null) return const SizedBox.shrink();
              
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == _playlist.videos.length - 1 ? 130.0 : 20.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // LEFT
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _selectSong(videoSong),
                                          child: Container(
                                            color: Colors.transparent,
                                            child: Row(
                                              children: [
                                                // SONG IMG
                                                Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: const BoxDecoration(
                                                    borderRadius: BorderRadius.all(Radius.circular(5)),
                                                    color: Color.fromRGBO(35, 35, 35, 1),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(5),
                                                    child: Stack(
                                                      children: [
                                                        Positioned(
                                                          top: -8,
                                                          bottom: -8,
                                                          child: Image.network(videoController.construyeVideoThumbnail(videoSong.thumbnail)),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
              
                                                const SizedBox(width: 13),
              
                                                // SONG TITLE
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(right: 10),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          videoSong.title,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.bold,
                                                            color: videoSong.url == videoController.currentVideo.value?.url
                                                              ? Constants.primaryColor
                                                              : Colors.white,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                        Text(
                                                          videoSong.author,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            color: Color.fromRGBO(255, 255, 255, 0.7),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                                                  
                                      // RIGHT
                                      GestureDetector(
                                        onTap: () => {},
                                        child: const Padding(
                                          padding: EdgeInsets.only(right: 5),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.more_horiz_sharp,
                                                color: Color.fromRGBO(255, 255, 255, 0.7),
                                                size: 25,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
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
        ),
      ),
    );
  }

  void _goBack() {
    navigationProvider.goToNavigationRootPage();
  }

  void _onClickAddSongs() {
    // playlistController.fetchYouTubePlaylistWithoutAPIKey('PLzz5LregW-aYt4MCKTSD5M-tjUuCuTIfV');
    navigationProvider.changeNavigationPage(NavigationPagesEnum.search);
  }

  void _onClickPlayBtn() {
    playlistController.setCurrentPlaylist(widget.playlistIndex);
    videoController.playNextRandomVideo();
  }

  void _selectSong(VideoSong video) {
    playlistController.setCurrentPlaylist(widget.playlistIndex);
    videoController.startVideoAudio(video.url, selected: true);
  }
}