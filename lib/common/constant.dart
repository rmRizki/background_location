class TableName {
  static const ticket = 'ticket';
  static const checklist = 'checklist';
}

enum ArrivalStatus {
  standby,
  departed,
  arrived,
}

enum TicketStatus {
  open,
  solved,
}

enum ChecklistType {
  depart,
  arrive,
}

enum CheckListStatus {
  undone,
  done,
}
