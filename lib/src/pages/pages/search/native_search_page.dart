import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/access_controller.dart';
import 'package:spotired/src/data/constants.dart';
import 'package:spotired/src/pages/data/providers/navitation_provider.dart';
import 'package:spotired/src/pages/pages/search/native_search/native_search_search_page.dart';

class NativeSearchPage extends StatefulWidget {
  const NativeSearchPage({super.key});

  @override
  State<NativeSearchPage> createState() => _NativeSearchPageState();
}

class _NativeSearchPageState extends State<NativeSearchPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: SafeArea(
        child: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, playlistIndex) {
            return Padding(
              padding: const EdgeInsets.only(left: 20, top: 50, right: 20, bottom: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  _showHeader(),

                  const SizedBox( height: 20 ),

                  _showSearch(),

                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _showHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 5),

            Container(
              width: 33,
              height: 33,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(247, 114, 161, 1),
                shape: BoxShape.circle,
              ),
              child: Text(
                accessController.accessKey.name.substring(0, 1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(width: 15),

            // TOP
            const Text(
              'Buscar',
              style: TextStyle(
                color: Constants.tertiaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  _showSearch() {
    return GestureDetector(
      onTap: _openSearch,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 10, right: 10),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: Colors.white,
        ),
        child: const Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Color.fromRGBO(42, 42, 42, 1),
              size: 35,
            ),

            SizedBox( width: 10 ),

            Text(
              '¿Qué te apetece escuchar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromRGBO(42, 42, 42, 1),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _openSearch() {
    navigationProvider.changeCurrentPage(context, const NativeSearchSearchPage());
  }
}