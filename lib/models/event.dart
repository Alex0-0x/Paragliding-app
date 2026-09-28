class Event {
  final int id;
  final int spotId;
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
      id: json['id'] ?? json['Id'] ?? 0,
      spotId: json['spotId'] ?? json['SpotId'] ?? 0,
      spotTitle: json['paraSpotTitle'] ??
          json['ParaSpotTitle'] ??
          '',
      userId: json['userId'] ?? json['UserId'] ?? '',
      username: json['userName'] ??
          json['UserName'] ??
          '',
      dateTime: DateTime.parse(
        json['startDate'] ??
            json['StartDate'] ??
            DateTime.now().toIso8601String(),
      ),
      description: json['description'] ??
          json['Description'] ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'spotId': spotId,
      'userName': username,
      'paraSpotTitle': spotTitle,
      'startDate': dateTime.toIso8601String(),
      'description': description,
    };
  }
}