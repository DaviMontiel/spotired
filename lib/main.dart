import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotired/src/app.dart';
import 'package:spotired/src/controllers/playlist_controller.dart';
import 'package:spotired/src/controllers/video_controller.dart';

void main() async {
  // INIT FLUTTER SERVICES
  WidgetsFlutterBinding.ensureInitialized();

  // UP BAR TRANSPARENT
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await playlistController.init();
  await videoController.init();

  runApp( const MyApp() );
}