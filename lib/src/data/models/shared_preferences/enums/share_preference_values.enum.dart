enum SharePreferenceValues {
  // APP
  accessKey('access-key'),
  appSettings('app-settings'),

  // PLAYBACK
  currentPlaylistId('current-playlist-id'),
  savedIsPlaylistSequential('saved-is-playlist-sequential'),
  currentVideoSecond('current-video-second'),
  currentVideoColor('current-video-color'),
  currentVideo('current-video'),
  pendingVideos('pending-videos'),
  pendingVideosCursor('pending-videos-cursor'),

  // DATA
  playlists('playlists'),
  videos('videos');


  final String value;

  const SharePreferenceValues(this.value);
}