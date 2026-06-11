class Event {
  final String id;
  final String spotId;
  final String spotTitle;
  final String userId;
  final String username;
  final DateTime dateTime;
  final String description;

  Event({
    required this.id,
    required this.spotId,
    required this.spotTitle,
    required this.userId,
    required this.username,
    required this.dateTime,
    required this.description,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? json['Id'] ?? '',
      spotId: json['spotId'] ?? json['SpotId'] ?? '',
      spotTitle: json['spotTitle'] ?? json['SpotTitle'] ?? '',
      userId: json['userId'] ?? json['UserId'] ?? '',
      username: json['username'] ?? json['Username'] ?? '',
      dateTime: DateTime.parse(
        json['dateTime'] ??
            json['DateTime'] ??
            DateTime.now().toIso8601String(),
      ),
      description: json['description'] ?? json['Description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spotId': spotId,
      'spotTitle': spotTitle,
      'userId': userId,
      'username': username,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
    };
  }
}
