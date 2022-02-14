class HistoryList {
  List<History>? data;

  HistoryList({this.data});

  factory HistoryList.fromJson(Map<String, dynamic> json) => HistoryList(
        data: (json['data'] as List<dynamic>?)
            ?.map((e) => History.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'data': data?.map((e) => e.toJson()).toList(),
      };
}

class History {
  int? id;
  String? action;
  String? imagePath;
  String? time;
  String? latitude;
  String? longitude;
  int? ticketId;

  History({
    this.id,
    this.action,
    this.imagePath,
    this.time,
    this.latitude,
    this.longitude,
    this.ticketId,
  });

  factory History.fromJson(Map<String, dynamic> json) => History(
        id: json['id'] as int?,
        action: json['action'] as String?,
        imagePath: json['image_path'] as String?,
        time: json['time'] as String?,
        latitude: json['latitude'] as String?,
        longitude: json['longitude'] as String?,
        ticketId: json['ticket_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'image_path': imagePath,
        'time': time,
        'latitude': latitude,
        'longitude': longitude,
        'ticket_id': ticketId,
      };
}
