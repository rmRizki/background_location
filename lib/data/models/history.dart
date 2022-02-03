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
  String? time;
  int? ticketId;

  History({
    this.id,
    this.action,
    this.time,
    this.ticketId,
  });

  factory History.fromJson(Map<String, dynamic> json) => History(
        id: json['id'] as int?,
        action: json['action'] as String?,
        time: json['time'] as String?,
        ticketId: json['ticket_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'time': time,
        'ticket_id': ticketId,
      };
}
