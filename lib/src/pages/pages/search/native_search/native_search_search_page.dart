import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/data/constants.dart';
import 'package:spotired/src/pages/data/providers/navitation_provider.dart';
import 'package:http/http.dart' as http;
import 'package:spotired/src/shared/widgets/modal_bottom_menu.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class NativeSearchSearchPage extends StatefulWidget {
  const NativeSearchSearchPage({super.key});

  @override
  State<NativeSearchSearchPage> createState() => _NativeSearchSearchPageState();
}

class _NativeSearchSearchPageState extends State<NativeSearchSearchPage> {

  // UI
  final _tfController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  // SEARCH
  Timer? _debounce;
  final List<VideoSong> _videos = [];
  String? _nextPageToken;
  bool _isLoading = false;
  bool _localSearch = false;
  final List<VideoSong> _localVideos = [];

  // ACTIVE RESULTS
  List<VideoSong> get _results => _localSearch ? _localVideos : _videos;

  // STATUS
  bool _isLoadingSong = false;
  String? _textError;

  static const _debounceMs = 500;
  static const _pageSize = 15;

  @override
  void initState() {
    super.initState();

    // SET TF FOCUS WITH SELECTION
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
      _tfController.selection =
          TextSelection(baseOffset: 0, extentOffset: _tfController.text.length);
    });

    // TF LISTENER
    _tfController.addListener(_onQueryChanged);

    // INFINITE SCROLL EVENT
    _scrollController.addListener(() {
      final thresholdReached = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200;
      if (
        thresholdReached &&
        !_localSearch &&
        !_isLoading &&
        _nextPageToken != null &&
        _tfController.text.trim().isNotEmpty)
      {
        _search(_tfController.text.trim(), append: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(42, 42, 42, 1),
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(),

            _searchScopeToggle(),

            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _focusNode.unfocus();
                },
                child: Container(
                  color: const Color.fromARGB(255, 18, 18, 18),
                  child: ValueListenableBuilder<VideoSong?>(
                    valueListenable: videoController.currentVideo,
                    builder: (context, value, child) {
                      if (_textError != null) {
                        return Text(
                          _textError!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      }

                      if (_results.isEmpty && !_isLoading && _tfController.text.trim().isNotEmpty) {
                        return _emptyState();
                      }

                      return NotificationListener<ScrollNotification>(
                        onNotification: (_) {
                          _focusNode.unfocus();
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _results.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _results.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 25),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Constants.primaryColor),
                                  ),
                                ),
                              );
                            }
                            final video = _results[index];
                            return _videoTile(video);
                          },
                        ),
                      );
                    }
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoTile(VideoSong videoSong) {
    return Column(
      children: [
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  child: _thumbnail(videoSong)
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
      ],
    );
  }

  _searchBar() {
    return Container(
      color: const Color.fromRGBO(42, 42, 42, 1),
      padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 40),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 35,
            ),
          ),

          const SizedBox( width: 10 ),

          Expanded(
            child: TextField(
              controller: _tfController,
              focusNode: _focusNode,
              style: const TextStyle(
                color: Constants.primaryColor,
              ),
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.never,
                hintText: _localSearch
                  ? 'Buscar en tus canciones'
                  : '¿Qué te apetece escuchar?',
                hintStyle: const TextStyle(
                  color: Color.fromRGBO(191, 191, 191, 1),
                  fontWeight: FontWeight.normal,
                ),
                labelStyle: TextStyle(color: Color.fromRGBO(191, 191, 191, 1)),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchScopeToggle() {
    return Container(
      color: const Color.fromRGBO(42, 42, 42, 1),
      padding: const EdgeInsets.only(left: 55, right: 20, bottom: 12),
      child: Row(
        children: [
          _scopeChip(
            label: 'YouTube',
            isSelected: !_localSearch,
            onTap: () => _changeScope(false),
          ),

          const SizedBox( width: 10 ),

          _scopeChip(
            label: 'Tus canciones',
            isSelected: _localSearch,
            onTap: () => _changeScope(true),
          ),
        ],
      ),
    );
  }

  Widget _scopeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 14, top: 7, bottom: 7),
        decoration: BoxDecoration(
          color: isSelected
            ? Constants.primaryColor
            : const Color.fromRGBO(70, 70, 70, 1),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
              ? Colors.white
              : const Color.fromRGBO(220, 220, 220, 1),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 40),
      child: Text(
        _localSearch
          ? 'Ninguna de tus canciones coincide con la búsqueda.'
          : 'Sin resultados.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: Color.fromRGBO(255, 255, 255, 0.7),
        ),
      ),
    );
  }

  /// Los resultados de YouTube traen la URL completa de la miniatura; las
  /// canciones guardadas solo el fragmento, y normalmente ya la tienen
  /// cacheada en disco.
  Widget _thumbnail(VideoSong videoSong) {
    if (!_localSearch) return Image.network(videoSong.thumbnail);

    final String? cachedImage = videoController.getVideoImageFromUrl(videoSong.url);
    if (cachedImage == null) {
      videoController.loadImageFromVideoUrl(videoSong.url);
      return Image.network(videoController.construyeVideoThumbnail(videoSong.thumbnail));
    }

    return Image.file(File.fromUri(Uri.file(cachedImage)));
  }

  void _changeScope(bool localSearch) {
    if (_localSearch == localSearch) return;

    setState(() {
      _localSearch = localSearch;
      _textError = null;
    });

    _runSearch(_tfController.text.trim());
  }

  @override
  void dispose() {
    _tfController.removeListener(_onQueryChanged);
    _tfController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _goBack() {
    navigationProvider.goToNavigationRootPage();
  }

  void _onQueryChanged() {
    _debounce?.cancel();

    // La busqueda local es un filtro en memoria: no necesita debounce.
    if (_localSearch) {
      _runSearch(_tfController.text.trim());
      return;
    }

    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      _runSearch(_tfController.text.trim());
    });
  }

  void _runSearch(String query) {
    if (_localSearch) {
      setState(() {
        _localVideos
          ..clear()
          ..addAll(videoController.searchLocalVideoSongs(query));
      });
      return;
    }

    if (query.isNotEmpty) {
      _search(query, append: false);
      return;
    }

    setState(() {
      _videos.clear();
      _nextPageToken = null;
    });
  }

  Future<void> _search(String query, {required bool append}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final key = Constants.youtubeApiKey;
    final pageToken = append && _nextPageToken != null ? '&pageToken=$_nextPageToken' : '';
    final url = 'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=$_pageSize&q=${Uri.encodeQueryComponent(query)}&key=$key$pageToken';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newVideos = (data['items'] as List)
            .map((i) => VideoSong.fromYoutubeSearchJson(i as Map<String, dynamic>))
            .toList();

        setState(() {
          if (append) {
            _videos.addAll(newVideos);
          } else {
            _videos
              ..clear()
              ..addAll(newVideos);
          }
          _nextPageToken = data['nextPageToken'] as String?;
        });
      } else {
        setState(() {
          _textError = 'YouTube API error: ${res.body}';
        });

        debugPrint('YouTube API error: ${res.body}');
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _selectSong(VideoSong video) async {
    FocusScope.of(context).unfocus();

    if (_isLoadingSong) return;
    _isLoadingSong = true;

    if (videoController.currentVideo.value?.url == video.url) {
      videoController.changeCurrentVideoSongPosition(0, play: true);
      _isLoadingSong = false;
      return;
    }

    if (_localSearch) {
      videoController.startVideoAudio(video.url);
      _isLoadingSong = false;
      return;
    }

    // GET YT VIDEO
    final ytVideo = await YoutubeExplode().videos.get(video.url);

    // CREATE VIDEO-SONG
    VideoSong videoSong = VideoSong(
      url: video.url,
      title: ytVideo.title,
      author: ytVideo.author,
      thumbnail: videoController.getVideoThumbnailFromYTUrl(ytVideo.url).split('vi/')[1],
      duration: ytVideo.duration!.inSeconds,
    );

    // SAVE
    await videoController.saveOneTimeVideoSong(videoSong);

    // START
    videoController.startVideoAudio(
      videoSong.url,
      prepareNextVideo: false,
    );

    _isLoadingSong = false;
  }

  void _onClickVideoSongMenu(VideoSong videoSong) {
    _focusNode.unfocus();

    ModalBottomMenu().videoSongMenu(context, null, videoSong);
  }
}