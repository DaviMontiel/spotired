import 'package:flutter/material.dart';
import 'package:spotired/src/controllers/video_controller.dart';
import 'package:spotired/src/data/models/video/video_song.dart';
import 'package:spotired/src/pages/data/enums/navigation_pages.enum.dart';
import 'package:spotired/src/pages/data/providers/navitation_provider.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: WillPopScope(
        onWillPop: () async {
          if (navigationProvider.isInRoot) return true;

          navigationProvider.goToNavigationRootPage();
          return false;
        },
        child: ListenableBuilder(
            listenable: navigationProvider,
            builder: (context, child) {
              return ValueListenableBuilder<Widget>(
                valueListenable: navigationProvider.currentScreen,
                builder: (context, screen, child) {
                  return Stack(
                    children: [
                      screen,

                      // GRADIENT
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.0),
                                  Colors.black,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  
                      ValueListenableBuilder<VideoSong?>(
                        valueListenable: videoController.currentVideo,
                        builder: (context, value, child) {
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            left: 0,
                            right: 0,
                            bottom: value != null
                              ? 60
                              : -60,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5, right: 5),
                              child: Container(
                                height: 60,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                  color: Color.fromRGBO(4, 48, 35, 1),
                                ),
                                padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // LEFT
                                        Row(
                                          children: [
                                            // SONG IMG
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: const BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.all(Radius.circular(5)),
                                                color: Color.fromRGBO(3, 34, 25, 1),
                                              ),
                                            ),
                                            
                                            const SizedBox(width: 13),
                                            
                                            // SONG TITLE
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  value == null
                                                    ? ''
                                                    : value.title,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const Text(
                                                  'Omar Montes',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color.fromRGBO(
                                                        255, 255, 255, 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                            
                                        // RIGHT
                                        const Padding(
                                          padding: EdgeInsets.only(right: 5),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 35,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      color: Colors.white.withOpacity(0.2),
                                      height: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  
                      // NAVIGATION BAR
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _navigationButton(
                              screenIndex: NavigationPagesEnum.search,
                              baseIcon: Icons.search,
                              text: 'Buscar',
                            ),
                            _navigationButton(
                              screenIndex: NavigationPagesEnum.library,
                              baseIcon: Icons.library_music,
                              text: 'Tu biblioteca',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              );
            }),
      ),
    );
  }

  Widget _navigationButton({
    required NavigationPagesEnum screenIndex,
    required IconData baseIcon,
    required String text,
  }) {
    Color color;
    bool isPressing = false;

    if (navigationProvider.currentPage == screenIndex) {
      color = Colors.white;
    } else {
      color = const Color.fromRGBO(175, 175, 175, 1);
    }

    return Expanded(
      child: Column(
        children: [
          StatefulBuilder(
            builder: (context, setState) => GestureDetector(
              onTap: () => _changeScreen(screenIndex),
              onTapUp: (details) {
                isPressing = false;
                setState(() {});
              },
              onTapDown: (details) {
                isPressing = true;
                setState(() {});
              },
              onTapCancel: () {
                isPressing = false;
                setState(() {});
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Column(
                  children: [
                    Icon(
                      baseIcon,
                      color: color,
                      size: isPressing ? 27 : 30,
                    ),
                    Text(
                      text,
                      style: TextStyle(
                          fontSize: isPressing ? 9 : 10, color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeScreen(NavigationPagesEnum newScreen) {
    navigationProvider.changeNavigationPage(newScreen);
  }
}