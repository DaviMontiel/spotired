import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/pages/data/constants.dart';
import 'package:spotired/src/pages/pages/library/create_playlist_page.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AddVideoPage extends StatefulWidget {

  final Video ytVideo;

  const AddVideoPage({
    super.key,
    required this.ytVideo,
  });

  @override
  State<AddVideoPage> createState() => _AddVideoPageState();
}

class _AddVideoPageState extends State<AddVideoPage> {
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
                  backgroundColor: Constants.primaryColor,
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
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: playlistController.playlists.length,
          itemBuilder: (context, playlistIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _playlistRow(playlistIndex),
            );
          },
        ),
      ),
    );
  }

  Widget _playlistRow(int playlistIndex) {
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
            _saveVideoToPlaylist(playlistIndex);
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 100),
            scale: scale,
            child: Container(
              height: 70,
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: double.infinity,
                    color: const Color.fromRGBO(35, 35, 35, 1),
                    child: const Center(
                      child: Icon(
                        Icons.folder_outlined,
                        size: 35,
                        color: Color.fromRGBO(125, 125, 125, 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PLAYLIST TITLE
                      Text(
                        playlistController.playlists[playlistIndex].name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Constants.tertiaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // SIZE
                      Text(
                        'Lista • ${playlistController.playlists[playlistIndex].videos.length} canciones',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Constants.tertiaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _saveVideoToPlaylist(int playlistIndex) async {
    VideoSong video = VideoSong(
      url: widget.ytVideo.url.split('v=')[1],
      title: widget.ytVideo.title,
      author: widget.ytVideo.author,
      thumbnail: videoController.getVideoThumbnailFromYTUrl(widget.ytVideo.url).split('vi/')[1],
      duration: widget.ytVideo.duration!.inSeconds,
    );

    // ADD SONG
    playlistController.addVideoToPlaylist(playlistIndex, video);

    // GO BACK
    Navigator.pop(context, true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio agregado a la playlist.'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(20, 40, 20, 130),
      ),
    );
  }
}