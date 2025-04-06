class AccessKey {
  final String key;
  final DateTime? expirationDate;

  AccessKey({
    required this.key,
    this.expirationDate,
  });

  factory AccessKey.fromJson(Map<String, dynamic> json) {
    return AccessKey(
      key: json['key'],
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }
}