import 'package:flutter/material.dart';
import 'package:spotired/src/data/constants.dart';
import 'package:spotired/src/pages/pages/search/native_search_page.dart';
import 'package:spotired/src/pages/pages/search/youtube_search_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Constants.env == 'dev'
      ? const NativeSearchPage()
      : const YoutubeSearchPage();
  }
}