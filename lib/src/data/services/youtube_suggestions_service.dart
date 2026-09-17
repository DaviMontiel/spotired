import 'dart:isolate';

import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Sugerencias de canciones para una playlist.
///
/// YouTube retiro `relatedToVideoId` de su API oficial, asi que la fuente es
/// `youtube_explode_dart`, que lee los videos relacionados de la propia pagina
/// del video. No hay endpoint publico que recomiende sobre una lista entera:
/// lo que se hace es coger unas cuantas canciones de la playlist como semilla
/// y mezclar sus relacionados.
final youtubeSuggestionsService = YoutubeSuggestionsService();

class YoutubeSuggestionsService {

  /// Canciones de la playlist que se usan como semilla. Cada una cuesta dos
  /// peticiones de red, asi que conviene no pasarse.
  static const int _maxSeeds = 3;

  static const int _defaultLimit = 12;

  /// Sugerencias ya calculadas, por id de playlist. Evita repetir la red cada
  /// vez que se entra en la lista.
  final Map<int, List<VideoSong>> _cache = <int, List<VideoSong>>{};

  List<VideoSong>? cachedFor(int playlistId) => _cache[playlistId];

  void clearCache(int playlistId) => _cache.remove(playlistId);

  /// Devuelve canciones sugeridas que NO estan ya en la playlist.
  ///
  /// Lanza excepcion si ninguna semilla dio resultado, con el detalle de cada
  /// intento: quien llama necesita poder distinguir "no hay sugerencias" de
  /// "ha fallado la red".
  Future<List<VideoSong>> forPlaylist({
    required int playlistId,
    required List<String> videoIds,
    int limit = _defaultLimit,
  }) async {
    if (videoIds.isEmpty) return <VideoSong>[];

    final List<String> seeds = _pickSeeds(videoIds);
    final Set<String> exclude = videoIds.toSet();

    final List<Map<String, dynamic>> raw = await Isolate.run(
      () => _fetchSuggestions(seeds, exclude, limit),
    );

    final List<VideoSong> suggestions = raw.map(VideoSong.fromExportMap).toList();
    _cache[playlistId] = suggestions;

    return suggestions;
  }

  /// Pide a YouTube los datos completos de una sugerencia.
  ///
  /// La lista de relacionados no trae duracion fiable (y a veces ninguna), y
  /// sin duracion la barra de progreso del reproductor queda inutilizada. Es
  /// el mismo paso que da la busqueda antes de reproducir un resultado.
  Future<VideoSong> complete(VideoSong suggestion) async {
    final Map<String, dynamic> raw = await Isolate.run(
      () => _fetchVideoDetails(suggestion.url),
    );

    return VideoSong.fromExportMap(raw);
  }

  /// Semillas al azar para que "actualizar" de resultados distintos.
  List<String> _pickSeeds(List<String> videoIds) {
    final List<String> shuffled = List<String>.from(videoIds)..shuffle();
    return shuffled.take(_maxSeeds).toList();
  }
}

/// Se ejecuta en un isolate aparte: son varias peticiones de red y parseo de
/// HTML, y bloquearia la UI.
Future<List<Map<String, dynamic>>> _fetchSuggestions(
  List<String> seedVideoIds,
  Set<String> excludeVideoIds,
  int limit,
) async {
  final YoutubeExplode yt = YoutubeExplode();
  final Map<String, Map<String, dynamic>> collected = <String, Map<String, dynamic>>{};
  final List<String> failures = <String>[];

  try {
    for (final String seedVideoId in seedVideoIds) {
      if (collected.length >= limit) break;

      try {
        final Video seed = await yt.videos.get(seedVideoId);
        final RelatedVideosList? related = await yt.videos.getRelatedVideos(seed);

        if (related == null) {
          failures.add('$seedVideoId: sin videos relacionados');
          continue;
        }

        for (final Video video in related) {
          if (collected.length >= limit) break;

          final String? videoId = _videoIdOf(video);
          if (videoId == null) continue;
          if (excludeVideoIds.contains(videoId)) continue;
          if (collected.containsKey(videoId)) continue;

          collected[videoId] = VideoSong(
            url: videoId,
            title: video.title,
            author: video.author,
            // Mismo formato que usa el resto de la app: '<id>/0.jpg', que
            // `construyeVideoThumbnail` convierte en la URL completa.
            thumbnail: '$videoId/0.jpg',
            // Los directos no traen duracion.
            duration: video.duration?.inSeconds ?? 0,
          ).toExportMap();
        }
      } catch (ex) {
        failures.add('$seedVideoId: $ex');
      }
    }
  } finally {
    yt.close();
  }

  if (collected.isEmpty && failures.isNotEmpty) {
    throw Exception(
      'No se pudieron obtener sugerencias. Intentos: ${failures.join(' | ')}',
    );
  }

  return collected.values.toList();
}

Future<Map<String, dynamic>> _fetchVideoDetails(String videoId) async {
  final YoutubeExplode yt = YoutubeExplode();

  try {
    final Video video = await yt.videos.get(videoId);

    return VideoSong(
      url: videoId,
      title: video.title,
      author: video.author,
      thumbnail: '$videoId/0.jpg',
      duration: video.duration?.inSeconds ?? 0,
    ).toExportMap();
  } finally {
    yt.close();
  }
}

/// Extrae el id del video de su URL, con el mismo criterio que ya usa el resto
/// de la app (`AddVideoPage`), donde `VideoSong.url` guarda el id pelado.
String? _videoIdOf(Video video) {
  final List<String> parts = video.url.split('v=');
  if (parts.length < 2) return null;

  final String id = parts[1].split('&').first.trim();
  return id.isEmpty ? null : id;
}
