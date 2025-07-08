import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/data/constants.dart';
import 'package:spotired/src/pages/pages/library/add_video_page.dart';
import 'package:spotired/src/pages/pages/library/create_playlist_page.dart';
import 'package:spotired/src/pages/pages/library/import_playlist_page.dart';

class ModalBottomMenu {

  addPlaylistMenu(BuildContext context) {
    final List<dynamic> btns = [
      {
        'icon': Icons.music_note_outlined,
        'text': 'Lista',
        'description': 'Crea una lista con canciones o vídeos',
        'event': () => _openPage(context, const CreatePlaylistPage()),
      },
      {
        'icon': Icons.sim_card_download_outlined,
        'text': 'Importar lista manual',
        'description': 'Agrega una playlist con los datos exportados.',
        'event': () => _showPastePlaylistDialog(context),
      },
      {
        'icon': Icons.slow_motion_video_outlined,
        'text': 'Importar lista de Youtube',
        'description': 'Agrega una playlist desde un enlace de YouTube',
        'event': () => _openPage(context, const ImportPlaylistPage()),
      },
    ];

    return showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: const Color.fromRGBO(31, 31, 31, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Color.fromRGBO(99, 99, 99, 1),
                ),
              ),

              const SizedBox(height: 15),

              // OPTIONS
              ..._showOptions(btns),
            ],
          ),
        );
      },
    );
  }

  stopDownloadPlaylist(BuildContext context, { required int playlistId }) {
    final List<dynamic> btns = [
      {
        'icon': Icons.arrow_circle_down_sharp,
        'text': 'Deshabilitar descargas automáticas',
        'event': () => _disablePlaylistAutoDownloads(context, playlistId),
      },
      {
        'icon': Icons.music_off_outlined,
        'text': 'Eliminar canciones descargadas',
        'event': () => _removeDownloadedSongsFromPlaylist(context, playlistId),
      },
    ];

    return showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: const Color.fromRGBO(31, 31, 31, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Color.fromRGBO(99, 99, 99, 1),
                ),
              ),

              const SizedBox(height: 15),

              // OPTIONS
              ..._showOptions(btns),
            ],
          ),
        );
      },
    );
  }

  playlistMenu(BuildContext context, int playlistid) {
    final List<dynamic> btns = [
      {
        'icon': Icons.edit_note_rounded,
        'text': 'Cambiar nombre',
        'event': () => _changePlaylistName(context, playlistid),
      },
      {
        'icon': Icons.copy_rounded,
        'text': 'Exportar',
        'event': () => _exportPlaylist(context, playlistid),
      },
      {
        'icon': Icons.close,
        'text': 'Eliminar playlist',
        'event': () => _removePlaylist(context, playlistid),
      },
    ];

    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(31, 31, 31, 1),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    Expanded(
                      child: Container(
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
                        
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // PLAYLIST TITLE
                                  Text(
                                    playlistController.playlists[playlistid]!.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Constants.tertiaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
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

              const SizedBox( height: 15 ),

              Container(
                height: 2,
                width: double.infinity,
                color: const Color.fromRGBO(49, 49, 49, 1),
              ),

              // OPTIONS
              ..._showOptions(btns),
            ],
          ),
        );
      },
    );
  }

  videoSongMenu(BuildContext context, int? playlistid, VideoSong videoSong) {
    final List<dynamic> btns = [
      {
        'icon': Icons.add_circle_outline,
        'text': 'Añadir a la lista',
        'event': () => _addToPlaylists(context, videoSong.url),
      },
      if (playlistid != null)
      {
        'icon': Icons.format_list_bulleted_add,
        'text': 'Agregar a la cola',
        'event': () => addVideoToQueue(context, videoSong.url),
      },
      if (playlistid != null)
      {
        'icon': Icons.close,
        'text': 'Eliminar de la playlist',
        'event': () => _removeUrlOfPlaylist(context, playlistid, videoSong.url),
      },
    ];

    // VIDEO-SONG IMG
    String? cachedImage = videoController.getVideoImageFromUrl(videoSong.url);

    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(31, 31, 31, 1),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                                      top: -12,
                                      bottom: -12,
                                      left: -15,
                                      right: -15,
                                      child: cachedImage == null
                                        ? Image.network(videoSong.thumbnail, fit: BoxFit.scaleDown)
                                        : Image.file(File.fromUri(Uri.file(cachedImage)), fit: BoxFit.scaleDown),
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
        
              const SizedBox( height: 15 ),
        
              Container(
                height: 2,
                width: double.infinity,
                color: const Color.fromRGBO(49, 49, 49, 1),
              ),
        
              // OPTIONS
              ..._showOptions(btns),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _showOptions(List<dynamic> btns) {
    return [
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          btns[f]['text'],
                          style: const TextStyle(
                            color: Constants.tertiaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (btns[f]['description'] != null)
                          Text(
                            btns[f]['description'],
                            style: const TextStyle(
                              color: Color.fromRGBO(125, 125, 125, 1),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
    ];
  }

  void _openPage(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
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

  _removePlaylist(BuildContext context, int playlistid) {
    playlistController.removePlaylist(playlistid);
    Navigator.pop(context);
  }

  _exportPlaylist(BuildContext context, int playlistid) {
    Navigator.pop(context);

    Playlist playlist = playlistController.playlists[playlistid]!;
    List<VideoSong> videoSongs = videoController.getVideosFromPlaylistId(playlistid);
    String data = jsonEncode({
      'playlist': playlist.toMap(),
      'videos': videoSongs.map((v) => v.toMap()).toList(),
    });

    // TO BASE64
    String base64EncodedData = base64Encode(utf8.encode(data));

    // SAVE
    Clipboard.setData(ClipboardData(text: base64EncodedData));

    // SHOW MSG
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text("Playlist copiada ✅"),
        ),
      ),
    );
  }

  _changePlaylistName(BuildContext context, int playlistid) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CreatePlaylistPage(playlistId: playlistid),
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

  _removeUrlOfPlaylist(BuildContext context, int playlistid, String url) {
    playlistController.removeVideoOfPlaylist(playlistid, url);
    Navigator.pop(context);
  }

  addVideoToQueue(BuildContext context, String url) {
    videoController.addVideoToQueue(url);
    Navigator.pop(context);
  }

  _addToPlaylists(BuildContext context, String url) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AddVideoPage(videoSongUrl: url)),
    );
  }

  _disablePlaylistAutoDownloads(BuildContext context, int playlistId) async {
    Navigator.pop(context);
    await playlistController.disablePlaylistAutoDownloads(playlistId);
  }

  _removeDownloadedSongsFromPlaylist(BuildContext context, int playlistId) async {
    Navigator.pop(context);
    await playlistController.disablePlaylistAutoDownloads(playlistId);
    await playlistController.removeDownloadedSongsFromPlaylist(playlistId);
  }

  void _showPastePlaylistDialog(BuildContext context) {
    Navigator.pop(context);

    final focusNode = FocusNode();
    final tfController = TextEditingController();

    focusNode.requestFocus();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color.fromRGBO(31, 31, 31, 1),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pega aquí el enlace de la playlist copiada:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tfController,
                focusNode: focusNode,
                style: const TextStyle(
                  color: Color.fromRGBO(191, 191, 191, 1),
                ),
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintText: 'Pegar aqui',
                  labelStyle: const TextStyle(
                    color: Color.fromRGBO(191, 191, 191, 1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(191, 191, 191, 1),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(191, 191, 191, 1),
                      width: 2,
                    ),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(191, 191, 191, 1),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _importPlaylist(context, tfController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 12
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Importar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _importPlaylist(BuildContext context, String data) {
    Navigator.pop(context);

    // TO BASE64
    String jsonStr = utf8.decode(base64Decode(data));

    // TO MAP
    Map<String, dynamic> dataMap = jsonDecode(jsonStr);

    // PLAYLIST
    Playlist playlist = Playlist.fromMap(dataMap['playlist']);
    playlist.downloadVideos = false;

    List<VideoSong> videoSongs = (dataMap['videos'] as List)
      .map((v) => VideoSong.fromMap(v))
      .toList();

    // SAVE
    playlistController.importPlaylist(playlist);
    videoController.importVideoSongs(playlist.id, videoSongs);
  }
}