class DrawTicket {
  final int? id;
  final String ticketCode;
  final int? userId;
  final int dayNumber;
  final bool isAssigned;
  final bool isWinner;
  final DateTime? assignedAt;
  final DateTime createdAt;

  // Joined fields
  final String? userName;
  final String? houseNumber;

  DrawTicket({
    this.id,
    required this.ticketCode,
    this.userId,
    required this.dayNumber,
    this.isAssigned = false,
    this.isWinner = false,
    this.assignedAt,
    DateTime? createdAt,
    this.userName,
    this.houseNumber,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_code': ticketCode,
      'user_id': userId,
      'day_number': dayNumber,
      'is_assigned': isAssigned ? 1 : 0,
      'is_winner': isWinner ? 1 : 0,
      'assigned_at': assignedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DrawTicket.fromMap(Map<String, dynamic> map) {
    return DrawTicket(
      id: map['id'],
      ticketCode: map['ticket_code'],
      userId: map['user_id'],
      dayNumber: map['day_number'],
      isAssigned: map['is_assigned'] == 1,
      isWinner: map['is_winner'] == 1,
      assignedAt: map['assigned_at'] != null
          ? DateTime.parse(map['assigned_at'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      userName: map['user_name'],
      houseNumber: map['house_number'],
    );
  }

  DrawTicket copyWith({
    int? id,
    String? ticketCode,
    int? userId,
    int? dayNumber,
    bool? isAssigned,
    bool? isWinner,
    DateTime? assignedAt,
  }) {
    return DrawTicket(
      id: id ?? this.id,
      ticketCode: ticketCode ?? this.ticketCode,
      userId: userId ?? this.userId,
      dayNumber: dayNumber ?? this.dayNumber,
      isAssigned: isAssigned ?? this.isAssigned,
      isWinner: isWinner ?? this.isWinner,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt,
      userName: userName,
      houseNumber: houseNumber,
    );
  }
}

class NavratriDay {
  final int? id;
  final int dayNumber;
  final DateTime date;
  final String? goddessName;
  final String? dressCode;
  final String? eventSchedule;
  final bool isActive;
  final bool isCompleted;
  final DateTime createdAt;

  NavratriDay({
    this.id,
    required this.dayNumber,
    required this.date,
    this.goddessName,
    this.dressCode,
    this.eventSchedule,
    this.isActive = false,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day_number': dayNumber,
      'date': date.toIso8601String(),
      'goddess_name': goddessName,
      'dress_code': dressCode,
      'event_schedule': eventSchedule,
      'is_active': isActive ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NavratriDay.fromMap(Map<String, dynamic> map) {
    return NavratriDay(
      id: map['id'],
      dayNumber: map['day_number'],
      date: DateTime.parse(map['date']),
      goddessName: map['goddess_name'],
      dressCode: map['dress_code'],
      eventSchedule: map['event_schedule'],
      isActive: map['is_active'] == 1,
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  NavratriDay copyWith({
    int? id,
    int? dayNumber,
    DateTime? date,
    String? goddessName,
    String? dressCode,
    String? eventSchedule,
    bool? isActive,
    bool? isCompleted,
  }) {
    return NavratriDay(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      goddessName: goddessName ?? this.goddessName,
      dressCode: dressCode ?? this.dressCode,
      eventSchedule: eventSchedule ?? this.eventSchedule,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}

class DailyDraw {
  final int? id;
  final int dayNumber;
  final int drawNumber;
  final int? winnerTicketId;
  final int? winnerUserId;
  final String? prizeDescription;
  final DateTime? drawnAt;
  final bool isCompleted;
  final DateTime createdAt;

  // Joined fields
  final String? ticketCode;
  final String? winnerName;
  final String? winnerHouse;

  DailyDraw({
    this.id,
    required this.dayNumber,
    required this.drawNumber,
    this.winnerTicketId,
    this.winnerUserId,
    this.prizeDescription,
    this.drawnAt,
    this.isCompleted = false,
    DateTime? createdAt,
    this.ticketCode,
    this.winnerName,
    this.winnerHouse,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day_number': dayNumber,
      'draw_number': drawNumber,
      'winner_ticket_id': winnerTicketId,
      'winner_user_id': winnerUserId,
      'prize_description': prizeDescription,
      'drawn_at': drawnAt?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyDraw.fromMap(Map<String, dynamic> map) {
    return DailyDraw(
      id: map['id'],
      dayNumber: map['day_number'],
      drawNumber: map['draw_number'],
      winnerTicketId: map['winner_ticket_id'],
      winnerUserId: map['winner_user_id'],
      prizeDescription: map['prize_description'],
      drawnAt: map['drawn_at'] != null
          ? DateTime.parse(map['drawn_at'])
          : null,
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      ticketCode: map['ticket_code'],
      winnerName: map['winner_name'],
      winnerHouse: map['winner_house'],
    );
  }
}
