import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/access_controller.dart';
import 'package:spotired/src/pages/access_page.dart';
import 'package:spotired/src/data/constants.dart';
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
      home: ValueListenableBuilder<bool>(
        valueListenable: accessController.haveAccess,
        builder: (context, haveAccess, child) {
          return haveAccess
            ? const Navigation()
            : const AccessPage();
        }
      ),
    );
  }
}
