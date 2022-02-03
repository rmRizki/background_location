class CheckList {
  List<CheckListItem>? data;

  CheckList({this.data});

  factory CheckList.fromJson(Map<String, dynamic> json) => CheckList(
        data: (json['data'] as List<dynamic>?)
            ?.map((e) => CheckListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'data': data?.map((e) => e.toJson()).toList(),
      };
}

class CheckListItem {
  int? id;
  String? title;
  String? type;
  String? time;
  String? status;
  int? ticketId;

  CheckListItem({
    this.id,
    this.title,
    this.type,
    this.time,
    this.status,
    this.ticketId,
  });

  factory CheckListItem.fromJson(Map<String, dynamic> json) => CheckListItem(
        id: json['id'] as int?,
        title: json['title'] as String?,
        type: json['type'] as String?,
        time: json['time'] as String?,
        status: json['status'] as String?,
        ticketId: json['ticket_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'time': time,
        'status': status,
        'ticket_id': ticketId,
      };
}
