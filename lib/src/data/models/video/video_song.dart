class VideoSong {
  String url;
  String title;
  String author;
  String thumbnail;
  int duration;
  List<int> playlists;
  bool downloaded;

  VideoSong({
    required this.url,
    required this.title,
    required this.author,
    required this.thumbnail,
    required this.duration,
    List<int>? playlists,
    this.downloaded = false,
  }): playlists = playlists ?? [];

  toMap() {
    return {
      'url': url,
      'title': title,
      'author': author,
      'thumbnail': thumbnail,
      'duration': duration,
      'playlists': playlists,
      'downloaded': downloaded,
    };
  }

  static VideoSong fromMap(Map<String, dynamic> map) {
    return VideoSong(
      url: map['url'],
      title: map['title'],
      author: map['author'],
      thumbnail: map['thumbnail'],
      duration: map['duration'],
      playlists: List<int>.from(map['playlists'] ?? []),
      downloaded: map['downloaded'] ?? false,
    );
  }

  copy() {
    final map = toMap();
    return fromMap(map);
  }
}
