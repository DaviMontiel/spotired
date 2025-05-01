class Playlist {
  int id;
  String name;
  List<String> videos;
  bool delete;
  bool deleteAudios;
  bool downloadVideos;

  Playlist({
    required this.id,
    required this.name,
    this.delete = false,
    this.deleteAudios = false,
    this.videos = const [],
    this.downloadVideos = false,
  });

  toMap() {
    return {
      'id': id,
      'name': name,
      'delete': delete,
      'deleteAudios': deleteAudios,
      'videos': videos,
      'downloadVideos': downloadVideos,
    };
  }

  static Playlist fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      delete: map['delete'] ?? false,
      deleteAudios: map['deleteAudios'] ?? false,
      videos: List<String>.from(map['videos']),
      downloadVideos: map['downloadVideos'] ?? false,
    );
  }
}
