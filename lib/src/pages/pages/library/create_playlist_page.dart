import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/pages/data/constants.dart';


class CreatePlaylistPage extends StatefulWidget {
  const CreatePlaylistPage({super.key});

  @override
  State<CreatePlaylistPage> createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends State<CreatePlaylistPage> {

  final _focusNode = FocusNode();
  final _tfController = TextEditingController();

  bool _isCreatingPlaylist = false;


  @override
  void initState() {
    _tfController.text = 'Mi lista n.º 25';

    super.initState();

    // SET TF FOCUS WITH SELECTION
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
      _tfController.selection = TextSelection(baseOffset: 0, extentOffset: _tfController.text.length);
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
            const Text(
              "Ponle un título a tu lista",
              style: TextStyle(
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
                  onPressed: _createPlaylist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Crear',
                    style: TextStyle(
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

  void _createPlaylist() {
    if (_isCreatingPlaylist) return;
    _isCreatingPlaylist = true;

    // CHECK TITLE
    String playlistTitle = _tfController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (playlistTitle.isEmpty) return;

    // CREATE PLAYLIST
    playlistController.addPlaylist(playlistTitle);

    // GO BACK
    Navigator.pop(context);
  }
}