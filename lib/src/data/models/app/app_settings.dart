class AppSettings {
  final String currentVersion;
  final String apkUrl;

  AppSettings({
    required this.currentVersion,
    required this.apkUrl,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      currentVersion: json['currentVersion'],
      apkUrl: json['apkUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentVersion': currentVersion,
      'apkUrl': apkUrl,
    };
  }
}