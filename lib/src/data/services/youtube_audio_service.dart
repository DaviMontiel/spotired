import 'dart:async';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// URL de audio de YouTube ya resuelta Y VALIDADA, junto con las cabeceras
/// con las que debe consumirse.
///
/// Motivo de que esto exista: YouTube ata la URL del stream al cliente que la
/// solicitó. `youtube_explode_dart` pide el manifest haciéndose pasar por la
/// app oficial de Android, pero después la URL se consumía desde ExoPlayer
/// (just_audio) y desde `http.Request`, que envían su propio `User-Agent`.
/// googlevideo detecta la incoherencia y responde **403 Forbidden**.
///
/// Por eso la URL nunca debe viajar sola: siempre va acompañada de las
/// cabeceras del cliente que la generó.
class ResolvedAudio {
  /// URL directa del stream de audio en googlevideo.
  final String url;

  /// Cabeceras obligatorias para consumir [url]. Puede estar vacío si el
  /// cliente que resolvió la URL no declara ningún `User-Agent` propio.
  final Map<String, String> headers;

  /// Momento en el que la URL deja de ser válida, leído del parámetro
  /// `expire` de la propia URL. `null` si la URL no lo trae.
  final DateTime? expiresAt;

  /// `true` si no se pudo usar un stream de solo audio y se cayó al formato
  /// muxado 18 (360p + AAC). Suena igual, pero gasta más datos.
  final bool muxedFallback;

  const ResolvedAudio({
    required this.url,
    required this.headers,
    this.expiresAt,
    this.muxedFallback = false,
  });

  /// Las URLs de googlevideo caducan (típicamente a las pocas horas). Se
  /// considera caducada con 5 minutos de margen para no empezar una descarga
  /// que va a morir a mitad.
  bool get isExpired {
    final DateTime? expiry = expiresAt;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  /// Cabeceras listas para `AudioSource.uri`, que espera `null` (no un mapa
  /// vacío) cuando no hay nada que enviar.
  Map<String, String>? get headersOrNull => headers.isEmpty ? null : headers;

  factory ResolvedAudio._fromMap(Map<String, dynamic> map) {
    final int? expiresAtMs = map['expiresAtMs'] as int?;
    return ResolvedAudio(
      url: map['url'] as String,
      headers: Map<String, String>.from(map['headers'] as Map),
      expiresAt: expiresAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(expiresAtMs),
      muxedFallback: map['muxedFallback'] as bool? ?? false,
    );
  }
}

final youtubeAudioService = YoutubeAudioService();

class YoutubeAudioService {
  /// Resuelve la URL de audio de [videoUrl] y devuelve una URL **ya probada**
  /// contra los servidores de YouTube.
  ///
  /// Lanza una excepción con el detalle de cada cliente que falló si ninguno
  /// consigue una URL reproducible. No devuelve `null` silenciosamente: quien
  /// llama necesita saber por qué ha fallado.
  Future<ResolvedAudio> resolve(String videoUrl) async {
    final Map<String, dynamic> result = await Isolate.run(
      () => _resolveAudioInIsolate(videoUrl),
    );
    return ResolvedAudio._fromMap(result);
  }
}

/// Clientes que se prueban, en orden de menor a mayor probabilidad de exigir
/// un GVS PO Token.
///
/// YouTube exige un "GVS PO Token" para descargar los bytes del stream en los
/// clientes `web`, `mweb`, `android` e `ios`. Sin ese token googlevideo deja
/// pasar los primeros bytes y devuelve **403 en cuanto se piden rangos
/// posteriores**, que es justo lo que hacía fallar a ExoPlayer.
///
/// `tv` (TVHTML5) es, según la guía de PO Tokens de yt-dlp, el cliente que no
/// lo exige, por eso va primero. `androidVr` tampoco lo exigía, pero desde
/// 2026 solo sirve el formato 18 sin token, así que queda como plan B.
///
/// No es `const` a propósito: `YoutubeApiClient.ios` es una propiedad estática.
final List<YoutubeApiClient> _clientsInOrder = <YoutubeApiClient>[
  YoutubeApiClient.tv,
  YoutubeApiClient.androidVr,
  YoutubeApiClient.androidSdkless,
  YoutubeApiClient.ios,
];

/// Formato muxado 360p H.264 + AAC. Es el único que YouTube sigue sirviendo sin
/// GVS PO Token en los clientes restringidos. No es solo-audio (trae vídeo que
/// el reproductor ignora), pero suena, y es preferible a no reproducir nada.
const int _muxedFallbackTag = 18;

/// Se ejecuta en un isolate aparte para no bloquear la UI: `getManifest` hace
/// varias peticiones de red y resuelve firmas en JS.
Future<Map<String, dynamic>> _resolveAudioInIsolate(String videoUrl) async {
  final YoutubeExplode yt = YoutubeExplode();
  final List<String> failures = <String>[];

  try {
    for (final YoutubeApiClient client in _clientsInOrder) {
      final String clientName = _clientNameOf(client);

      try {
        final StreamManifest manifest = await yt.videos.streams.getManifest(
          videoUrl,
          ytClients: <YoutubeApiClient>[client],
        );
        final Map<String, String> headers = _headersFor(client);

        // 1) Preferencia: stream de solo audio, mejor bitrate.
        final List<AudioOnlyStreamInfo> audioStreams =
            manifest.audioOnly.toList();
        if (audioStreams.isEmpty) {
          failures.add('$clientName: el manifest no trae streams de solo audio');
        } else {
          final AudioOnlyStreamInfo audioStream =
              audioStreams.withHighestBitrate();
          final _ProbeResult probe =
              await _probe(audioStream.url, headers, audioStream.size.totalBytes);
          if (probe.ok) {
            return _describe(audioStream.url, headers, muxedFallback: false);
          }
          failures.add('$clientName solo-audio: ${probe.describe()}');
        }

        // 2) Plan B: el formato muxado 18, el único que sigue sirviéndose sin
        //    GVS PO Token. Trae vídeo 360p que el reproductor descarta.
        MuxedStreamInfo? muxed;
        for (final MuxedStreamInfo candidate in manifest.muxed) {
          if (candidate.tag == _muxedFallbackTag) {
            muxed = candidate;
            break;
          }
        }
        if (muxed == null) {
          failures.add('$clientName: sin formato muxado $_muxedFallbackTag');
          continue;
        }

        final _ProbeResult muxedProbe =
            await _probe(muxed.url, headers, muxed.size.totalBytes);
        if (muxedProbe.ok) {
          return _describe(muxed.url, headers, muxedFallback: true);
        }
        failures.add('$clientName muxado $_muxedFallbackTag: ${muxedProbe.describe()}');
      } catch (ex) {
        failures.add('$clientName: $ex');
      }
    }
  } finally {
    yt.close();
  }

  // Se lanza un Exception con mensaje plano (siempre enviable entre isolates)
  // en lugar de una clase propia.
  throw Exception(
    'No se pudo obtener una URL de audio reproducible para $videoUrl. '
    'Intentos: ${failures.join(' | ')}',
  );
}

Map<String, dynamic> _describe(
  Uri url,
  Map<String, String> headers, {
  required bool muxedFallback,
}) {
  return <String, dynamic>{
    'url': url.toString(),
    'headers': headers,
    'expiresAtMs': _expiryOf(url)?.millisecondsSinceEpoch,
    'muxedFallback': muxedFallback,
  };
}

class _ProbeResult {
  final int statusCode;
  final String? error;
  final String range;

  const _ProbeResult.status(this.statusCode, this.range) : error = null;
  const _ProbeResult.failure(this.error)
      : statusCode = -1,
        range = '';

  bool get ok => statusCode == 200 || statusCode == 206;

  String describe() => error != null
      ? 'error de red ($error)'
      : 'googlevideo respondió $statusCode a $range';
}

/// Comprueba que la URL es realmente reproducible, no solo que exista.
///
/// Se hacen DOS peticiones porque el fallo que había no se detecta con una:
///
///  1. `Range: bytes=0-` — exactamente lo que envía ExoPlayer al abrir el
///     stream (`ProgressiveMediaPeriod`).
///  2. Un rango profundo (75% del fichero) — sin GVS PO Token googlevideo
///     sirve los primeros bytes y devuelve 403 más adelante. Sondear solo el
///     principio daba un falso OK y el 403 aparecía al reproducir.
///
/// Solo se da por buena la URL si ambas pasan.
Future<_ProbeResult> _probe(
  Uri url,
  Map<String, String> headers,
  int totalBytes,
) async {
  final _ProbeResult opening = await _probeRange(url, headers, 'bytes=0-');
  if (!opening.ok) return opening;

  if (totalBytes <= 0) return opening;

  final int deepOffset = (totalBytes * 3) ~/ 4;
  return _probeRange(url, headers, 'bytes=$deepOffset-${deepOffset + 1}');
}

Future<_ProbeResult> _probeRange(
  Uri url,
  Map<String, String> headers,
  String range,
) async {
  final http.Client client = http.Client();
  try {
    final http.Request request = http.Request('GET', url);
    request.headers.addAll(headers);
    request.headers['Range'] = range;

    final http.StreamedResponse response =
        await client.send(request).timeout(const Duration(seconds: 15));

    // Cerramos el cuerpo sin descargarlo.
    final StreamSubscription<List<int>> subscription =
        response.stream.listen(null);
    await subscription.cancel();

    return _ProbeResult.status(response.statusCode, range);
  } on TimeoutException {
    return _ProbeResult.failure('tiempo de espera agotado en $range');
  } catch (ex) {
    return _ProbeResult.failure('$ex (en $range)');
  } finally {
    client.close();
  }
}

/// Cabeceras con las que hay que consumir una URL obtenida con [client].
///
/// El `User-Agent` **no se inventa**: se lee del propio payload del cliente que
/// declara `youtube_explode_dart`. Si esa librería lo actualiza, esto lo sigue
/// automáticamente. Si el cliente no declara ninguno, no se fuerza cabecera y
/// se deja el `User-Agent` por defecto del reproductor.
Map<String, String> _headersFor(YoutubeApiClient client) {
  final Map<String, String> headers = <String, String>{};

  final Object? declared =
      client.headers['User-Agent'] ?? client.headers['user-agent'];
  if (declared is String && declared.isNotEmpty) {
    headers['User-Agent'] = declared;
    return headers;
  }

  final Object? context = client.payload['context'];
  if (context is Map) {
    final Object? inner = context['client'];
    if (inner is Map) {
      final Object? userAgent = inner['userAgent'];
      if (userAgent is String && userAgent.isNotEmpty) {
        headers['User-Agent'] = userAgent;
      }
    }
  }

  return headers;
}

String _clientNameOf(YoutubeApiClient client) {
  final Object? context = client.payload['context'];
  if (context is Map) {
    final Object? inner = context['client'];
    if (inner is Map) {
      final Object? name = inner['clientName'];
      if (name is String) return name;
    }
  }
  return 'cliente desconocido';
}

/// Las URLs de googlevideo llevan `expire=<epoch en segundos>`.
DateTime? _expiryOf(Uri url) {
  final String? expire = url.queryParameters['expire'];
  if (expire == null) return null;

  final int? seconds = int.tryParse(expire);
  if (seconds == null) return null;

  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();
}
