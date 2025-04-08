class AccessKey {
  final String name;
  final String key;
  final DateTime? expirationDate;

  AccessKey({
    required this.name,
    required this.key,
    this.expirationDate,
  });

  factory AccessKey.fromJson(Map<String, dynamic> json) {
    return AccessKey(
      name: json['name'],
      key: json['key'],
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'key': key,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }
}