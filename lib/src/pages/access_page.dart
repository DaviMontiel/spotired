import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotired/src/controllers/access_controller.dart';

class AccessPage extends StatelessWidget {
  const AccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    _checkKey();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: accessController.accessKey.key));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Center(
                  child: Text("Clave de acceso copiado ✅"),
                ),
              ),
            );
          },
          child: Container(
            height: 70,
            alignment: Alignment.center,
            color: Colors.transparent,
            child: Text(
              accessController.accessKey.key,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _checkKey() {
    accessController.checkActualAccess();
  }
}