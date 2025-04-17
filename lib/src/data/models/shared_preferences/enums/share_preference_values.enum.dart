enum SharePreferenceValues {
  // APP
  accessKey('access-key'),
  appSettings('app-settings'),

  // PLAYBACK
  currentPlaylistId('current-playlist-id'),
  savedIsPlaylistSequential('saved-is-playlist-sequential'),
  currentVideo('current-video'),

  // DATA
  playlists('playlists'),
  videos('videos');


  final String value;

  const SharePreferenceValues(this.value);
}