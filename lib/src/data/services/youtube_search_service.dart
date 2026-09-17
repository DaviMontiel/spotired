import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Busqueda de canciones en YouTube.
///
/// NO usa la YouTube Data API. Aquella exige una API key (que ademas viajaba
/// empaquetada dentro del APK y es extraible) y tiene una cuota diaria de
/// 10.000 unidades: cada busqueda cuesta 100, o sea unas 100 busquedas al dia
/// entre TODOS los usuarios juntos.
///
/// `youtube_explode_dart` lee los resultados de la propia web de YouTube: sin
/// clave y sin cuota. Es la misma libreria que ya resuelve el audio y las
/// sugerencias.
final youtubeSearchService = YoutubeSearchService();

class YoutubeSearchService {

  /// Se mantiene viva durante toda la sesion a proposito: la paginacion
  /// (`nextPage`) depende del cliente que creo la lista, asi que no se puede
  /// cerrar entre busquedas.
  final YoutubeExplode _yt = YoutubeExplode();

  VideoSearchList? _currentPage;

  /// Puede quedar mas resultados por cargar.
  bool get hasMore => _currentPage != null;

  /// Primera pagina de resultados para [query].
  Future<List<VideoSong>> search(String query) async {
    _currentPage = await _yt.search.search(query);

    return _toVideoSongs(_currentPage);
  }

  /// Siguiente pagina de la ultima busqueda. Lista vacia si ya no queda nada.
  Future<List<VideoSong>> nextPage() async {
    final VideoSearchList? current = _currentPage;
    if (current == null) return <VideoSong>[];

    _currentPage = await current.nextPage();

    return _toVideoSongs(_currentPage);
  }

  /// Olvida la busqueda en curso.
  void reset() {
    _currentPage = null;
  }

  List<VideoSong> _toVideoSongs(VideoSearchList? page) {
    if (page == null) return <VideoSong>[];

    final List<VideoSong> videoSongs = <VideoSong>[];

    for (final Video video in page) {
      final String? videoId = _videoIdOf(video);
      if (videoId == null) continue;

      videoSongs.add(VideoSong(
        url: videoId,
        title: video.title,
        author: video.author,
        // Mismo formato corto que usa el resto de la app: '<id>/0.jpg'.
        thumbnail: '$videoId/0.jpg',
        // Los directos no traen duracion.
        duration: video.duration?.inSeconds ?? 0,
      ));
    }

    return videoSongs;
  }
}

/// Extrae el id del video de su URL, con el mismo criterio que el resto de la
/// app, donde `VideoSong.url` guarda el id pelado.
String? _videoIdOf(Video video) {
  final List<String> parts = video.url.split('v=');
  if (parts.length < 2) return null;

  final String id = parts[1].split('&').first.trim();
  return id.isEmpty ? null : id;
}
