class Playlist {
  String name;
  List<String> videos;

  Playlist({
    required this.name,
    this.videos = const [],
  });

  toMap() {
    return {
      'name': name,
      'videos': videos,
    };
  }
}
