class TicketList {
  List<Ticket>? data;

  TicketList({this.data});

  factory TicketList.fromJson(Map<String, dynamic> json) => TicketList(
        data: (json['data'] as List<dynamic>?)
            ?.map((e) => Ticket.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'data': data?.map((e) => e.toJson()).toList(),
      };
}

class Ticket {
  int? id;
  String? title;
  String? description;
  String? arrivalStatus;
  String? ticketStatus;

  Ticket({
    this.id,
    this.title,
    this.description,
    this.arrivalStatus,
    this.ticketStatus,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'] as int?,
        title: json['title'] as String?,
        description: json['description'] as String?,
        arrivalStatus: json['arrival_status'] as String?,
        ticketStatus: json['ticket_status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'arrival_status': arrivalStatus,
        'ticket_status': ticketStatus,
      };
}
