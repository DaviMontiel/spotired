import 'package:flutter/material.dart';
import 'package:spotired/src/pages/data/enums/navigation_pages.enum.dart';
import 'package:spotired/src/pages/pages/library_page.dart';
import 'package:spotired/src/pages/pages/search_page.dart';

final navigationProvider = NavigationProvider();

class NavigationProvider with ChangeNotifier {
  // DATA
  final Map<NavigationPagesEnum, dynamic> _pages = {
    NavigationPagesEnum.search: const SearchPage(),
    NavigationPagesEnum.library: const LibraryPage(),
  };

  // STATUS
  NavigationPagesEnum currentPage = NavigationPagesEnum.library;
  final ValueNotifier<Widget> currentScreen = ValueNotifier<Widget>(const LibraryPage());
  bool isInRoot = true;


  changeNavigationPage(NavigationPagesEnum newPage) {
    isInRoot = true;
    currentPage = newPage;
    currentScreen.value = _pages[currentPage];
    notifyListeners();
  }

  changeCurrentPage(BuildContext context, dynamic newPage) {
    isInRoot = false;
    currentScreen.value = newPage;
  }

  goToNavigationRootPage() {
    isInRoot = true;
    currentScreen.value = _pages[currentPage];
  }
}
