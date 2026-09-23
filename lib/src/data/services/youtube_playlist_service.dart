import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spotired/src/data/constants.dart';
import 'package:spotired/src/data/models/video/video_song.dart';

/// Lee las canciones de una lista de YouTube con la API oficial.
///
/// Es el plan B de `youtube_explode_dart`, cuyo parser de listas devuelve la
/// pagina sin videos cuando YouTube cambia el HTML (que es lo que pasa ahora).
///
/// Sobre la cuota: `playlistItems.list` y `videos.list` cuestan 1 unidad por
/// llamada y salen del cupo de 10.000 diarias. Importar una lista de 300
/// canciones gasta 12. No tiene nada que ver con `search.list`, que esta
/// limitada a 100 llamadas al dia en total y por eso se quito de la busqueda.
final youtubePlaylistService = YoutubePlaylistService();

class YoutubePlaylistService {

  /// Maximo que admite la API por pagina.
  static const int _pageSize = 50;

  /// Tope de seguridad: 2000 canciones.
  static const int _maxPages = 40;

  /// Canciones de la lista [playlistId], con su duracion.
  Future<List<VideoSong>> fetchVideos(String playlistId) async {
    final String? apiKey = Constants.youtubeApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Falta YOUTUBE_API_KEY en el .env: sin ella no se pueden importar listas.',
      );
    }

    final List<VideoSong> videos = <VideoSong>[];
    String? pageToken;
    int pages = 0;

    do {
      final Uri url = Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {
        'part': 'snippet',
        'playlistId': playlistId,
        'maxResults': '$_pageSize',
        'key': apiKey,
        if (pageToken != null) 'pageToken': pageToken,
      });

      final http.Response response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('playlistItems.list respondió ${response.statusCode}: ${response.body}');
      }

      final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> items = data['items'] as List<dynamic>? ?? <dynamic>[];

      for (final dynamic item in items) {
        final VideoSong? videoSong = _toVideoSong(item);
        if (videoSong != null) videos.add(videoSong);
      }

      pageToken = data['nextPageToken'] as String?;
      pages++;
    } while (pageToken != null && pages < _maxPages);

    await _fillDurations(videos, apiKey);

    return videos;
  }

  VideoSong? _toVideoSong(dynamic item) {
    try {
      final Map<String, dynamic> snippet =
        (item as Map<String, dynamic>)['snippet'] as Map<String, dynamic>;

      final String? videoId =
        (snippet['resourceId'] as Map<String, dynamic>?)?['videoId'] as String?;
      if (videoId == null || videoId.isEmpty) return null;

      final String title = snippet['title'] as String? ?? '';

      // Los borrados y los privados siguen apareciendo en la lista, pero sin
      // datos con los que hacer nada.
      if (title.isEmpty || title == 'Deleted video' || title == 'Private video') {
        return null;
      }

      return VideoSong(
        url: videoId,
        title: title,
        author: snippet['videoOwnerChannelTitle'] as String?
          ?? snippet['channelTitle'] as String?
          ?? '',
        // Mismo formato corto que usa el resto de la app.
        thumbnail: '$videoId/0.jpg',
        // La rellena _fillDurations.
        duration: 0,
      );
    } catch (ex) {
      debugPrint('Importar lista: entrada ilegible: $ex');
      return null;
    }
  }

  /// `playlistItems.list` no devuelve la duracion: hay que pedirla aparte,
  /// de 50 en 50 ids por llamada.
  Future<void> _fillDurations(List<VideoSong> videos, String apiKey) async {
    for (int start = 0; start < videos.length; start += _pageSize) {
      final int end = (start + _pageSize).clamp(0, videos.length).toInt();
      final List<VideoSong> batch = videos.sublist(start, end);

      try {
        final Uri url = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
          'part': 'contentDetails',
          'id': batch.map((VideoSong video) => video.url).join(','),
          'maxResults': '$_pageSize',
          'key': apiKey,
        });

        final http.Response response = await http.get(url);
        if (response.statusCode != 200) {
          debugPrint('Importar lista: videos.list respondió ${response.statusCode}');
          continue;
        }

        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> items = data['items'] as List<dynamic>? ?? <dynamic>[];

        final Map<String, int> durations = <String, int>{};
        for (final dynamic item in items) {
          final Map<String, dynamic> map = item as Map<String, dynamic>;

          final String? id = map['id'] as String?;
          final String? iso =
            (map['contentDetails'] as Map<String, dynamic>?)?['duration'] as String?;
          if (id == null || iso == null) continue;

          durations[id] = parseIsoDuration(iso);
        }

        for (final VideoSong videoSong in batch) {
          final int? seconds = durations[videoSong.url];
          if (seconds != null) videoSong.duration = seconds;
        }
      } catch (ex) {
        // Sin duracion la cancion suena igual, solo se queda la barra de
        // progreso sin usar. No merece tumbar la importacion entera.
        debugPrint('Importar lista: no se pudieron leer duraciones: $ex');
      }
    }
  }

  /// Convierte la duracion ISO 8601 de la API ('PT4M13S') a segundos.
  static int parseIsoDuration(String iso) {
    final RegExpMatch? match =
      RegExp(r'^P(?:(\d+)D)?T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$').firstMatch(iso);
    if (match == null) return 0;

    final int days = int.tryParse(match.group(1) ?? '') ?? 0;
    final int hours = int.tryParse(match.group(2) ?? '') ?? 0;
    final int minutes = int.tryParse(match.group(3) ?? '') ?? 0;
    final int seconds = int.tryParse(match.group(4) ?? '') ?? 0;

    return days * 86400 + hours * 3600 + minutes * 60 + seconds;
  }
}
