class VideoSong {
  String url;
  String title;
  String author;
  String thumbnail;
  int duration;

  VideoSong({
    required this.url,
    required this.title,
    required this.author,
    required this.thumbnail,
    required this.duration,
  });

  toMap() {
    return {
      'url': url,
      'title': title,
      'author': author,
      'thumbnail': thumbnail,
      'duration': duration,
    };
  }

  static VideoSong fromMap(Map<String, dynamic> map) {
    return VideoSong(
      url: map['url'],
      title: map['title'],
      author: map['author'],
      thumbnail: map['thumbnail'],
      duration: map['duration'],
    );
  }
}
