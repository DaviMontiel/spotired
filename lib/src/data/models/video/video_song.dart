class VideoSong {
  String url;
  String title;
  String author;
  String thumbnail;

  VideoSong({
    required this.url,
    required this.title,
    required this.author,
    required this.thumbnail,
  });

  toMap() {
    return {
      'url': url,
      'title': title,
      'author': author,
      'thumbnail': thumbnail,
    };
  }

  static VideoSong fromMap(Map<String, dynamic> map) {
    return VideoSong(
      url: map['url'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      thumbnail: map['thumbnail'] as String,
    );
  }
}
