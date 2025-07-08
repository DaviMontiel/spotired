import 'dart:io';

import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/access_controller.dart';
import 'package:spotired/src/controllers/app_controller.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/data/constants.dart';
import 'package:spotired/src/pages/data/providers/navitation_provider.dart';
import 'package:spotired/src/pages/pages/library/playlist_page.dart';
import 'package:spotired/src/shared/widgets/download_progress_icon.dart';
import 'package:spotired/src/shared/widgets/modal_bottom_menu.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/video_controller.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: ListenableBuilder(
          listenable: playlistController,
          builder: (BuildContext context, Widget? child) {
            return SafeArea(
                child: Column(
              children: [
                _header(),
                playlistController.allowedPlaylists.isEmpty
                    ? _createPlaylistBody()
                    : _showPlaylistsBody(),
              ],
            ));
          }),
    );
  }

  Widget _header() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 18, 18, 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 3,
            spreadRadius: -3,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.only(left: 20, top: 50, right: 20, bottom: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 5),

                    Container(
                      width: 33,
                      height: 33,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(247, 114, 161, 1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        accessController.accessKey.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    // TOP
                    const Text(
                      'Tu biblioteca',
                      style: TextStyle(
                        color: Constants.tertiaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: appController.haveUpdate,
                      builder: (context, haveUpdate, child) {
                        if (!haveUpdate) return const SizedBox();

                        return GestureDetector(
                          onTap: _onClickUpdateBtn,
                          child: const Icon(
                            Icons.file_download_rounded,
                            color: Colors.green,
                            size: 35,
                          ),
                        );
                      }
                    ),

                    const SizedBox( width: 10 ),

                    GestureDetector(
                      onTap: _showAddBtnOptions,
                      child: const Icon(
                        Icons.add,
                        color: Constants.tertiaryColor,
                        size: 40,
                      ),
                    ),
                  ],
                )
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 8, bottom: 8),
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(42, 42, 42, 1),
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: const Text(
                    'Listas',
                    style: TextStyle(
                      fontSize: 13,
                      color: Constants.tertiaryColor,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _createPlaylistBody() {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: const Center(
          child: Text(
            'Vamos a empezar a crear tu lista de reproducción',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Constants.tertiaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _showPlaylistsBody() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListenableBuilder(
          listenable: videoController,
          builder: (BuildContext context, Widget? child) {
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: playlistController.allowedPlaylists.length,
              itemBuilder: (context, playlistIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _playlistRow(playlistController.allowedPlaylists.values.elementAt(
                    playlistController.allowedPlaylists.length -playlistIndex -1
                  )),
                );
              },
            );
          }
        ),
      ),
    );
  }

  Widget _playlistRow(Playlist playlist) {
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

    String? cachedImage;
    VideoSong? firstVideoSong = playlist.videos.isNotEmpty
      ? videoController.getVideoByUrl(playlist.videos.first)
      : null;
    if (firstVideoSong != null) {
      // IMG
      cachedImage = videoController.getVideoImageFromUrl(firstVideoSong.url);

      if (cachedImage == null) {
        videoController.loadImageFromVideoUrl(firstVideoSong.url);
      }
    }

    double downloadedVideos = playlistController.getDownloadedVideosOfPlaylistCount(playlist.id);

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
            _showPlaylistOptions(playlist.id);
          },
          onTap: () {
            _openPlaylist(playlist.id);
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
                                right: -12.5,
                                child: cachedImage == null
                                  ? const SizedBox()
                                  : Image.file(File.fromUri(Uri.file(cachedImage)), fit: BoxFit.scaleDown),
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
                        Row(
                          children: [
                            if (playlist.downloadVideos)
                            Builder(
                              builder: (context) {
                                return Row(
                                  children: [
                                    DownloadProgressIcon(
                                      progress: !playlist.downloadVideos
                                        ? 0
                                        : downloadedVideos / playlist.videos.length,
                                      size: 15,
                                      primaryColor: Colors.red,
                                      secondaryColor: const Color.fromRGBO(175, 175, 175, 1),
                                    ),

                                    const SizedBox( width: 5 ),
                                  ],
                                );
                              },
                            ),

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
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _openPlaylist(int playlistId) {
    navigationProvider.changeCurrentPage(context, PlaylistPage(playlistId: playlistId));
  }

  void _onClickUpdateBtn() {
    launchUrl(
      Uri.parse(appController.appSettings!.apkUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  void _showAddBtnOptions() {
    ModalBottomMenu().addPlaylistMenu(context);
  }

  void _showPlaylistOptions(int playlistId) {
    ModalBottomMenu().playlistMenu(context, playlistId);
  }
}
