class TableName {
  static const ticket = 'ticket';
  static const checklist = 'checklist';
  static const history = 'history';
}

class SharedPrefKey {
  static const location = 'location';
  static const lastLocation = 'last_location';
}

enum ArrivalStatus {
  standby,
  departed,
  arrived,
  done,
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
