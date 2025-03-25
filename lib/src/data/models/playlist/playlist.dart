class Playlist {
  final String? img;
  final String name;
  final int size;
  final List<int> videos;

  Playlist({
    this.img,
    required this.name,
    this.size = 0,
    this.videos = const [],
  });

  toMap() {
    return {
      'img': img,
      'name': name,
      'size': size,
      'videos': videos,
    };
  }
}
