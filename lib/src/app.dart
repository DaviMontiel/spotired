import 'package:flutter/material.dart';
import 'package:spotired/src/pages/data/constants.dart';
import 'package:spotired/src/pages/navigation.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotired',
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Constants.secondaryColor,
          cursorColor: Constants.secondaryColor,
          selectionHandleColor: Constants.secondaryColor,
        ),
      ),
      home:  const Navigation(),
    );
  }
}
