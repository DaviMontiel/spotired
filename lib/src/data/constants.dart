import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {

  // APP
  static String env = dotenv.env['ENV']!;

  // COLORS
  static const primaryColor = Color.fromARGB(255, 243, 35, 35);
  static const secondaryColor = Colors.red;
  static const tertiaryColor = Colors.white;

  // YOUTUBE
  static String youtubeApiKey = dotenv.env['YOUTUBE_API_KEY']!;
}