class ConfigModel {
  final String spreadsheetId;
  final String apiKey;
  final DateTime lastUpdated;

  ConfigModel({
    required this.spreadsheetId,
    required this.apiKey,
    required this.lastUpdated,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      spreadsheetId: json['spreadsheetId']?.toString() ?? '',
      apiKey: json['apiKey']?.toString() ?? '',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['lastUpdated'] as num).toInt())  // Handle num type
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spreadsheetId': spreadsheetId,
      'apiKey': apiKey,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}