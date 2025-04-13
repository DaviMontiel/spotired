class Playlist {
  int id;
  String name;
  List<String> videos;

  Playlist({
    required this.id,
    required this.name,
    this.videos = const [],
  });

  toMap() {
    return {
      'id': id,
      'name': name,
      'videos': videos,
    };
  }

  static Playlist fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      videos: List<String>.from(map['videos']),
    );
  }
}
