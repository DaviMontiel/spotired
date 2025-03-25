import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/pages/player_page.dart';

class PlaylistPage extends StatelessWidget {

  String _playlistName = '';

  PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Playlists")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Crear Playlist"),
                  content: TextField(
                    onChanged: (value) {
                      _playlistName = value;
                    },
                    decoration: const InputDecoration(hintText: "Nombre de la Playlist"),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Crear la playlist
                        playlistController.addPlaylist(_playlistName);
                        Navigator.pop(context);
                      },
                      child: const Text("Crear"),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Crear Playlist'),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: playlistController,
              builder: (BuildContext context, Widget? child) {
                return ListView.builder(
                  itemCount: playlistController.playlists.length + 30,
                  itemBuilder: (context, index) {
                    // final playlist = playlistController.playlists[index];
                    final playlist = playlistController.playlists[0];
                    return ListTile(
                      title: Text(playlist.name),
                      onTap: () {
                        // Navegar a la pantalla de la playlist
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerPage(playlist: playlist),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
