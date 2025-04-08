import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/pages/data/constants.dart';
import 'package:spotired/src/pages/pages/library/create_playlist_page.dart';

class ModalBottomMenu {

  playlistMenu(BuildContext context, int playlistIndex) {
    final List<dynamic> btns = [
      {
        'icon': Icons.edit_note_rounded,
        'text': 'Cambiar nombre',
        'event': () => _changePlaylistName(context, playlistIndex),
      },
      {
        'icon': Icons.close,
        'text': 'Eliminar playlist',
        'event': () => _removePlaylist(context, playlistIndex),
      },
    ];
    final int modalHeight = 116 + 65 * btns.length;

    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(31, 31, 31, 1),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(top: 10),
          height: modalHeight.toDouble(),
          width: double.infinity,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Color.fromRGBO(99, 99, 99, 1),
                ),
              ),

              const SizedBox( height: 15 ),

              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  children: [
                    Container(
                      height: 70,
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(5)),
                              color: Color.fromRGBO(35, 35, 35, 1),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.folder_outlined,
                                size: 35,
                                color: Color.fromRGBO(125, 125, 125, 1),
                              ),
                            ),
                          ),

                          const SizedBox( width: 15 ),

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
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox( height: 15 ),

              Container(
                height: 2,
                width: double.infinity,
                color: const Color.fromRGBO(49, 49, 49, 1),
              ),

              for (int f=0; f<btns.length; f++)
                GestureDetector(
                  onTap: () => btns[f]['event'](),
                  child: Container(
                    color: Colors.transparent,
                    // height: 65,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 15, bottom: 15, right: 20),
                      child: Row(
                        children: [
                          Icon(
                            btns[f]['icon'],
                            size: 35,
                            color: const Color.fromRGBO(180, 180, 180, 1),
                          ),

                          const SizedBox( width: 15 ),

                          Text(
                            btns[f]['text'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Constants.tertiaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  videoSongMenu(BuildContext context, int playlistIndex, VideoSong videoSong) {
    final List<dynamic> btns = [
      {
        'icon': Icons.close,
        'text': 'Eliminar de la playlist',
        'event': () => _removeUrlOfPlaylist(context, playlistIndex, videoSong.url),
      },
    ];
    final int modalHeight = 116 + 65 * btns.length;

    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(31, 31, 31, 1),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(top: 10),
          height: modalHeight.toDouble(),
          width: double.infinity,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Color.fromRGBO(99, 99, 99, 1),
                ),
              ),
        
              const SizedBox( height: 15 ),
        
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 70,
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              // SONG IMG
                              Container(
                                width: 100,
                                height: 100,
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
                            
                              const SizedBox( width: 15 ),
                            
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // PLAYLIST TITLE
                                    Text(
                                      videoSong.title,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                      style: const TextStyle(
                                        color: Constants.tertiaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        
              const SizedBox( height: 15 ),
        
              Container(
                height: 2,
                width: double.infinity,
                color: const Color.fromRGBO(49, 49, 49, 1),
              ),
        
              for (int f=0; f<btns.length; f++)
                GestureDetector(
                  onTap: () => btns[f]['event'](),
                  child: Container(
                    color: Colors.transparent,
                    // height: 65,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 15, bottom: 15, right: 20),
                      child: Row(
                        children: [
                          Icon(
                            btns[f]['icon'],
                            size: 35,
                            color: const Color.fromRGBO(180, 180, 180, 1),
                          ),
        
                          const SizedBox( width: 15 ),
        
                          Text(
                            btns[f]['text'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Constants.tertiaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  _removePlaylist(BuildContext context, int playlistIndex) {
    playlistController.removePlaylist(playlistIndex);
    Navigator.pop(context);
  }

  _changePlaylistName(BuildContext context, int playlistIndex) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CreatePlaylistPage(playlistIndex: playlistIndex),
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
    // Navigator.pop(context);
  }

  _removeUrlOfPlaylist(BuildContext context, int playlistIndex, String url) {
    playlistController.removeVideoOfPlaylist(playlistIndex, url);
    Navigator.pop(context);
  }
}