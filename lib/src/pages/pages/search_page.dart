import 'package:flutter/material.dart';
import 'package:spotired/src/pages/data/constants.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final WebViewController _controller;
  bool _isShowingVideo = false;
  String _videoUrl = '';

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onUrlChange: (change) {
            if (change.url!.startsWith('https://m.youtube.com/watch')) {
              setState(() {
                _videoUrl = change.url!;
                _isShowingVideo = true;
              });
            } else {
              _isShowingVideo = false;
              setState(() {});
            }
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
              Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse('https://www.youtube.com/'));

    _controller = controller;
  }

  String getVideoThumbnail(String url) {
    // Extraer el ID del video de la URL
    RegExp regExp = RegExp(r'v=([a-zA-Z0-9_-]+)');
    Match? match = regExp.firstMatch(url);

    if (match != null) {
      // Si se encuentra un ID, devolver la URL de la miniatura
      String videoId = match.group(1)!;
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    } else {
      // Si no se encuentra un ID, retornar una URL de miniatura predeterminada
      return 'https://img.youtube.com/vi/default_thumbnail.jpg';
    }
  }

  void _saveVideoToPlaylist() async {
    // final video = await YoutubeExplode().videos.get(_videoUrl);
    // playlistController.addVideoToPlaylist('play', {
    //   'url': _videoUrl,
    //   'title': video.title,
    //   'thumbnail': getVideoThumbnail(_videoUrl),
    // });
    setState(() {
      _isShowingVideo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            WebViewWidget(
              controller: _controller,
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              right: _isShowingVideo ? 10 : -140,
              bottom: 130,
              child: ElevatedButton(
                onPressed: () {
                  // SAVE IN PLAYLIST
                  _saveVideoToPlaylist();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 12
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        )
      ),
    );
  }
}
