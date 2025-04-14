import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/access_controller.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/pages/data/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as YT;

class ImportPlaylistPage extends StatefulWidget {
  const ImportPlaylistPage({super.key});

  @override
  State<ImportPlaylistPage> createState() => _ImportPlaylistPageState();
}

class _ImportPlaylistPageState extends State<ImportPlaylistPage> {

  // DATA
  YT.Playlist? playlist;

  // STATUS
  final _focusNode = FocusNode();
  final _tfController = TextEditingController();
  bool _isInProcess = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: SafeArea(
        child: Column(
          children: [

            Container(
              color: const Color.fromARGB(255, 18, 18, 18),
              padding: const EdgeInsets.only(left: 5),
              alignment: Alignment.topLeft,
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

            Expanded(
              child: ListView.builder(
                itemCount: [0].length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [

                      // PAINT
                      SizedBox(
                        height: 160,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 100,
                              right: 0,
                              child: _showCircle(
                                color: const Color.fromRGBO(90, 90, 90, 1),
                                icon: const Icon(
                                  Icons.add,
                                  size: 85
                                )
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 100,
                              child: _showCircle(
                                color: const Color.fromRGBO(247, 114, 161, 1),
                                text: accessController.accessKey.name.substring(0, 1)
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Importar listas de ',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextSpan(
                                    text: 'Youtube',
                                    style: TextStyle(color: Constants.primaryColor),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox( height: 20 ),

                            const Text(
                              'Agrega tus listas de reproducción de YouTube a Spotired y disfruta de tu música sin interrupciones. ¡Importa y escucha todo desde un solo lugar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox( height: 20 ),

                            Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                text: 'Para transferir tus listas de reproducción desde otras plataformas a YouTube, recomendamos utilizar ',
                                style: const TextStyle(
                                  color: Color.fromRGBO(191, 191, 191, 1),
                                  fontSize: 12
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Tune My Music',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchUrl(
                                          Uri.parse('https://www.tunemymusic.com/'),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                  ),
                                  const TextSpan(
                                    text: '. Esta herramienta te permitirá convertir fácilmente tus listas a YouTube. Una vez que tus listas estén públicas y visibles de manera publica en YouTube, podrás agregarlas a Spotired y disfrutarlas sin problemas.',
                                    style: TextStyle(
                                      color: Color.fromRGBO(191, 191, 191, 1),
                                      fontSize: 12
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox( height: 40 ),

                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              height: playlist == null ? 0 : 100,
                              width: double.infinity,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: playlist == null ? 0 : 1,
                                child: Stack(
                                  children: [
                                    Container(
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
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // PLAYLIST TITLE
                                                Text(
                                                  playlist == null
                                                    ? ''
                                                    : 'YT: ${playlist!.title}',
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
                                                  playlist == null
                                                    ? ''
                                                    : 'Lista • ${playlist!.videoCount} canciones',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Constants.tertiaryColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            TextField(
                              controller: _tfController,
                              focusNode: _focusNode,
                              readOnly: playlist != null,
                              style: const TextStyle(
                                color: Color.fromRGBO(191, 191, 191, 1),
                              ),
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                                hintText: 'https://',
                                labelStyle: const TextStyle(color: Color.fromRGBO(191, 191, 191, 1)),
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

                            const SizedBox( height: 20 ),

                            ElevatedButton(
                              onPressed: playlist == null
                                ? _onClickContinueBtn
                                : _onClickSaveBtn,
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
                              child: _isInProcess
                                ? const SizedBox(
                                    height: 26,
                                    width: 26,
                                    child: CircularProgressIndicator(
                                      color: Colors.red,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                  playlist == null
                                    ? 'Continuar'
                                    : 'Guardar',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ),

                            const SizedBox( height: 20 ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showCircle({ String? text, Icon? icon, required Color color }) {
    return Container(
      width: 130,
      height: 130,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromARGB(255, 18, 18, 18),
          width: 4,
        ),
      ),
      child: text != null
        ? Text(
            text,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          )
        : icon
    );
  }

  void _onClickContinueBtn() async {
    _focusNode.unfocus();
    if (_isInProcess || _tfController.text.trim().isEmpty) return;

    _isInProcess = true;
    playlist = null;
    setState(() {});

    // GET PLAYLIST
    final yt = YT.YoutubeExplode();
    try {
      final playlistYtId = _tfController.text.split('list=')[1];
      final playlist = await yt.playlists.get(playlistYtId);
      if (playlist.author.isNotEmpty) this.playlist = playlist;
      yt.close();
    } catch(ex) {}

    _isInProcess = false;
    setState(() {});
  }

  void _onClickSaveBtn() async {
    _focusNode.unfocus();
    if (_isInProcess || _tfController.text.trim().isEmpty) return;

    _isInProcess = true;
    setState(() {});

    await playlistController.fetchYouTubePlaylistWithoutAPIKey(_tfController.text);

    _goBack();
  }

  void _goBack() {
    if (mounted) Navigator.pop(context);
  }
}