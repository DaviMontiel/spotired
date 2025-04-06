import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotired/src/app.dart';
import 'package:spotired/src/controllers/access_controller.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  // INIT FLUTTER SERVICES
  WidgetsFlutterBinding.ensureInitialized();

  // UP BAR TRANSPARENT
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Reproducción de audio',
    androidNotificationOngoing: true,
  );

  await accessController.init();
  await playlistController.init();
  await videoController.init();

  runApp( const MyApp() );
}