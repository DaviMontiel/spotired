import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/pages/data/constants.dart';
import 'package:spotired/src/pages/pages/library/create_playlist_page.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as YT;

class AddVideoPage extends StatefulWidget {

  final YT.Video ytVideo;

  final String url;

  AddVideoPage({
    super.key,
    required this.ytVideo,
  }): url = ytVideo.url.split('v=')[1];

  @override
  State<AddVideoPage> createState() => _AddVideoPageState();
}

class _AddVideoPageState extends State<AddVideoPage> {

  Map<int, bool> initPlaylistHasVideoSong = {};
  Set<int> playlistsChanges = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, left: 5, right: 5),
          child: Column(
            children: [
              
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
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

                  const Text(
                    'Añadir a la lista',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 50),
                ],
              ),

              const SizedBox(height: 25),

              // CREATE PLAYLIST BTN
              ElevatedButton(
                onPressed: _onClickCreatePlaylistBtn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Nueva lista',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // PLAYLISTS
              ListenableBuilder(
                listenable: playlistController,
                builder: (BuildContext context, Widget? child) {
                  return _showPlaylistsBody();
                }
              ),

              Container(
                color: const Color.fromARGB(255, 18, 18, 18),
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _onClickDoneBtn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Hecho',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() => Navigator.pop(context);

  void _onClickCreatePlaylistBtn() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CreatePlaylistPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 100),
        reverseTransitionDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  Widget _showPlaylistsBody() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.builder(
          itemCount: playlistController.playlists.length,
          itemBuilder: (context, playlistIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _playlistRow(playlistController.playlists.values.elementAt(
                playlistController.playlists.length -playlistIndex -1
              )),
            );
          },
        ),
      ),
    );
  }

  Widget _playlistRow(Playlist playlist) {
    bool playlistHasVideoSong = false;
    VideoSong? videoSong = videoController.getVideoByUrl(widget.url);
    if (videoSong != null && videoSong.playlists.contains(playlist.id)) {
      playlistHasVideoSong = true;
    }

    initPlaylistHasVideoSong.addAll({playlist.id: playlistHasVideoSong});

    double scale = 1;

    void pressingSlale(setState) {
      setState(() {
        scale = 0.95;
      });
    }

    void normalScale(setState) {
      setState(() {
        scale = 1;
      });
    }

    return StatefulBuilder(builder: (context, setState) {
      return Listener(
        onPointerUp: (event) => normalScale(setState),
        child: GestureDetector(
          onLongPressDown: (details) {
            pressingSlale(setState);
          },
          onTapDown: (details) {
            pressingSlale(setState);
          },
          onTapUp: (details) {
            normalScale(setState);
          },
          onLongPress: () {
            normalScale(setState);
          },
          onTap: () {
            if (playlistsChanges.contains(playlist.id)) {
              playlistsChanges.remove(playlist.id);
            } else {
              playlistsChanges.add(playlist.id);
            }
            playlistHasVideoSong = !playlistHasVideoSong;
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 100),
            scale: scale,
            child: Container(
              height: 70,
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 100,
                          height: double.infinity,
                          color: const Color.fromRGBO(35, 35, 35, 1),
                          child: Center(
                            child: playlist.videos.isEmpty
                              ? const Icon(
                                  Icons.folder_outlined,
                                  size: 35,
                                  color: Color.fromRGBO(125, 125, 125, 1),
                                )
                              : Stack(
                                  children: [
                                    Positioned(
                                      top: -12,
                                      bottom: -12,
                                      right: -12,
                                      // left: 0,
                                      child: Image.network(
                                        videoController.construyeVideoThumbnail(videoController.getVideoByUrl(playlist.videos[0])!.thumbnail),
                                        fit: BoxFit.scaleDown,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PLAYLIST TITLE
                              Text(
                                playlist.name,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Constants.tertiaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          
                              const SizedBox(height: 2),
                          
                              // SIZE
                              Text(
                                'Lista • ${playlist.videos.length} canciones',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Constants.tertiaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    playlistHasVideoSong
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                    color: Constants.primaryColor,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _onClickDoneBtn() {
    initPlaylistHasVideoSong;
    for (var playlistId in playlistsChanges) {
      final isOnTheList = initPlaylistHasVideoSong[playlistId]!;

      if (isOnTheList) {
        playlistController.removeVideoOfPlaylist(playlistId, widget.url);
      } else {
        _saveVideoToPlaylist(playlistId);
      }
    }

    // GO BACK
    Navigator.pop(context);
  }

  void _saveVideoToPlaylist(int playlistId) async {
    VideoSong video = VideoSong(
      url: widget.ytVideo.url.split('v=')[1],
      title: widget.ytVideo.title,
      author: widget.ytVideo.author,
      thumbnail: videoController.getVideoThumbnailFromYTUrl(widget.ytVideo.url).split('vi/')[1],
      duration: widget.ytVideo.duration!.inSeconds,
    );

    // ADD SONG
    playlistController.addVideoToPlaylist(playlistId, video);
  }
}