import 'dart:io';

import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/pages/data/constants.dart';
import 'package:spotired/src/pages/data/enums/navigation_pages.enum.dart';
import 'package:spotired/src/pages/data/providers/navitation_provider.dart';
import 'package:spotired/src/shared/widgets/download_progress_icon.dart';
import 'package:spotired/src/shared/widgets/modal_bottom_menu.dart';

class PlaylistPage extends StatefulWidget {
  final int playlistId;

  const PlaylistPage({
    super.key,
    required this.playlistId,
  });

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {

  late final Playlist _playlist;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _goBackKey = GlobalKey();
  final GlobalKey _playBtnKey = GlobalKey();
  double _goBackButtonTop = 0;
  double _playBtnButtonTop = 0;
  bool _showStickyPlayButton = false;


  void _scrollListener() {
    final double scrollPosition = _scrollController.position.pixels;
    double stickyThreshold = _goBackButtonTop - _playBtnButtonTop;

    if (scrollPosition + stickyThreshold + 2 >= 0 != _showStickyPlayButton) {
      setState(() {
        _showStickyPlayButton = scrollPosition + stickyThreshold + 2 >= 0;
      });
    }
  }

  @override
  void initState() {
    _playlist = playlistController.playlists[widget.playlistId]!;
    _scrollController.addListener(_scrollListener);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_goBackKey.currentContext != null) {
        final RenderBox goBackRenderBox = _goBackKey.currentContext!.findRenderObject() as RenderBox;
        _goBackButtonTop = goBackRenderBox.localToGlobal(Offset.zero).dy;
      }

      if (_playBtnKey.currentContext != null) {
        final RenderBox playBtnRenderBox = _playBtnKey.currentContext!.findRenderObject() as RenderBox;
        _playBtnButtonTop = playBtnRenderBox.localToGlobal(Offset.zero).dy;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
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
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: playlistController,
              builder: (BuildContext context, Widget? child) {
                return ListenableBuilder(
                  listenable: videoController,
                  builder: (BuildContext context, Widget? child) {
                    double downloadedVideos = playlistController.getDownloadedVideosOfPlaylistCount(_playlist.id);

                    return ValueListenableBuilder<VideoSong?>(
                      valueListenable: videoController.currentVideo,
                      builder: (context, value, child) {
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: _playlist.videos.length + 1,
                          itemBuilder: (context, index) {
                        
                            // HEADER
                            if (index == 0) {
                              String? cachedImage;

                              if (_playlist.videos.isNotEmpty) {
                                // VIDEO-SONG
                                final videoSong = videoController.getVideoByUrl(_playlist.videos[0])!;

                                // IMG
                                cachedImage = videoController.getVideoImageFromUrl(videoSong.url);
                                if (cachedImage == null) {
                                  videoController.loadImageFromVideoUrl(videoSong.url);
                                }
                              }

                              return Column(
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
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: -48,
                                              bottom: -48,
                                              left: -105,
                                              child: cachedImage == null
                                                ? const SizedBox()
                                                : Image.file(File.fromUri(Uri.file(cachedImage))),
                                            ),
                                          ],
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

                                        if (_playlist.videos.isNotEmpty)
                                        ...[
                                          Positioned(
                                            left: 0,
                                            bottom: 0,
                                            top: 0,
                                            child: GestureDetector(
                                              onTap: _onClickDownloadBtn,
                                              child: DownloadProgressIcon(
                                                progress: !_playlist.downloadVideos
                                                  ? 0
                                                  : downloadedVideos / _playlist.videos.length,
                                                size: 35,
                                                primaryColor: Colors.red,
                                                secondaryColor: const Color.fromRGBO(175, 175, 175, 1),
                                              ),
                                            ),
                                          ),
                          
                                          if (!_showStickyPlayButton)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            top: 0,
                                            child: GestureDetector(
                                              onTap: _onClickPlayBtn,
                                              child: Container(
                                                key: _playBtnKey,
                                                width: 50,
                                                height: 50,
                                                decoration: const BoxDecoration(
                                                  color: Constants.primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.play_arrow, color: Colors.black, size: 35),
                                              ),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                        
                                  const SizedBox(height: 15),
                                ],
                              );
                            }
                
                            // VIDEO-SONG
                            final videoSong = videoController.getVideoByUrl(_playlist.videos[index - 1])!;
                
                            // IMG
                            final cachedImage = videoController.getVideoImageFromUrl(videoSong.url);
                            if (cachedImage == null) {
                              videoController.loadImageFromVideoUrl(videoSong.url);
                            }
                
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == _playlist.videos.length ? 130 : 20.0,
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
                                                        left: -19.4,
                                                        child: cachedImage == null
                                                          ? const SizedBox()
                                                          : Image.file(File.fromUri(Uri.file(cachedImage))),
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
                                                      Row(
                                                        children: [
                                                          if (_playlist.downloadVideos || videoSong.downloaded)
                                                          Builder(
                                                            builder: (context) {
                                                              double? downloadProgress = videoController.downloadVideosProgress[videoSong.url];
                                                              downloadProgress ??= 0;

                                                              return Row(
                                                                children: [
                                                                  DownloadProgressIcon(
                                                                    progress: videoSong.downloaded
                                                                      ? 1
                                                                      : downloadProgress / 100,
                                                                    size: 15,
                                                                    primaryColor: Colors.red,
                                                                    secondaryColor: const Color.fromRGBO(175, 175, 175, 1),
                                                                  ),

                                                                  const SizedBox( width: 5 ),
                                                                ],
                                                              );
                                                            },
                                                          ),

                                                          Expanded(
                                                            child: Text(
                                                              videoSong.author,
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color: Color.fromRGBO(255, 255, 255, 0.7),
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ],
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
                                      onTap: () => _onClickVideoSongMenu(videoSong),
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
                              ),
                            );
                          },
                        );
                      }
                    );
                  }
                );
              }
            ),
        
            // GO BACK BTN
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 5,
              child: GestureDetector(
                onTap: _goBack,
                child: Container(
                  key: _goBackKey,
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
        
            if (_showStickyPlayButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              right: 20,
              child: GestureDetector(
                onTap: _onClickPlayBtn,
                child: Container(
                  width: 50,
                  height: 50,
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
    );
  }

  void _goBack() {
    navigationProvider.goToNavigationRootPage();
  }

  void _onClickAddSongs() {
    navigationProvider.changeNavigationPage(NavigationPagesEnum.search);
  }

  void _onClickDownloadBtn() {
    // DOWNLOAD
    if (!_playlist.downloadVideos) {
      playlistController.downloadPlaylist(_playlist.id);
      return;
    }

    // SHOW DELETE DOWNLOADS
    ModalBottomMenu().stopDownloadPlaylist(context, playlistId: _playlist.id);
  }

  void _onClickPlayBtn() {
    playlistController.setCurrentPlaylist(widget.playlistId);
    videoController.playNextRandomVideo();
  }

  void _onClickVideoSongMenu(VideoSong videoSong) {
    ModalBottomMenu().videoSongMenu(context, widget.playlistId, videoSong);
  }

  void _selectSong(VideoSong video) {
    playlistController.setCurrentPlaylist(widget.playlistId);
    videoController.startVideoAudio(video.url, selected: true);
  }
}