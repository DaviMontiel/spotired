import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/data/models/playlist/playlist.dart';
import 'package:spotired/src/pages/data/constants.dart';

class CreatePlaylistPage extends StatefulWidget {
  final int? playlistId;

  const CreatePlaylistPage({
    super.key,
    this.playlistId,
  });

  @override
  State<CreatePlaylistPage> createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends State<CreatePlaylistPage> {
  Playlist? _playlistToEdit;

  final _focusNode = FocusNode();
  final _tfController = TextEditingController();

  bool _isEditingPlaylist = false;

  @override
  void initState() {
    // SET PLAYLIST TEXT
    if (widget.playlistId != null) {
      _playlistToEdit = playlistController.playlists[widget.playlistId!];
      _tfController.text = _playlistToEdit!.name;
    } else {
      _tfController.text = 'Mi lista n.º 25';
    }

    super.initState();

    // SET TF FOCUS WITH SELECTION
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
      _tfController.selection =
          TextSelection(baseOffset: 0, extentOffset: _tfController.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey, Colors.black],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _playlistToEdit != null
                  ? 'Cambiale el título a tu lista'
                  : 'Ponle un título a tu lista',
              style: const TextStyle(
                color: Constants.tertiaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    focusNode: _focusNode,
                    controller: _tfController,
                    textCapitalization: TextCapitalization.words,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Constants.tertiaryColor),
                      ),
                      contentPadding: EdgeInsets.only(bottom: -8),
                    ),
                    style: const TextStyle(
                      color: Constants.tertiaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
                    "Cancelar",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _onClickSaveBtn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _playlistToEdit != null ? 'Cambiar' : 'Crear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onClickSaveBtn() {
    if (_isEditingPlaylist) return;
    _isEditingPlaylist = true;

    // CHECK TITLE
    String playlistTitle =
        _tfController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (playlistTitle.isEmpty) return;

    if (_playlistToEdit == null) {
      _createPlaylist(playlistTitle);
    } else {
      _editPlayList(playlistTitle);
    }
  }

  void _editPlayList(String playlistTitle) {
    // RENAME PLAYLIST
    playlistController.renamePlaylist(widget.playlistId!, playlistTitle);

    // GO BACK
    Navigator.pop(context);
  }

  void _createPlaylist(String playlistTitle) {
    // CREATE PLAYLIST
    playlistController.addPlaylist(playlistTitle);

    // GO BACK
    Navigator.pop(context);
  }
}
