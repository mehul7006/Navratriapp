class Announcement {
  final int? id;
  final String title;
  final String message;
  final String announcementType; // 'general', 'schedule', 'gift', 'emergency'
  final int priority; // 1=low, 2=medium, 3=high
  final bool isActive;
  final int? createdBy;
  final DateTime createdAt;

  Announcement({
    this.id,
    required this.title,
    required this.message,
    this.announcementType = 'general',
    this.priority = 1,
    this.isActive = true,
    this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'announcement_type': announcementType,
      'priority': priority,
      'is_active': isActive ? 1 : 0,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      announcementType: map['announcement_type'],
      priority: map['priority'],
      isActive: map['is_active'] == 1,
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Announcement copyWith({
    int? id,
    String? title,
    String? message,
    String? announcementType,
    int? priority,
    bool? isActive,
    int? createdBy,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      announcementType: announcementType ?? this.announcementType,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
    );
  }
}

class DailySchedule {
  final int? id;
  final int dayNumber;
  final DateTime? eventTime;
  final String eventName;
  final String? eventDescription;
  final String? location;
  final DateTime createdAt;

  DailySchedule({
    this.id,
    required this.dayNumber,
    this.eventTime,
    required this.eventName,
    this.eventDescription,
    this.location,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day_number': dayNumber,
      'event_time': eventTime?.toIso8601String(),
      'event_name': eventName,
      'event_description': eventDescription,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailySchedule.fromMap(Map<String, dynamic> map) {
    return DailySchedule(
      id: map['id'],
      dayNumber: map['day_number'],
      eventTime: map['event_time'] != null
          ? DateTime.parse(map['event_time'])
          : null,
      eventName: map['event_name'],
      eventDescription: map['event_description'],
      location: map['location'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class Broadcast {
  final int? id;
  final String title;
  final String message;
  final String broadcastType; // 'text', 'image', 'video'
  final String? mediaUrl;
  final String targetAudience; // 'all', 'users', 'sponsors'
  final int? sentBy;
  final DateTime sentAt;

  Broadcast({
    this.id,
    required this.title,
    required this.message,
    this.broadcastType = 'text',
    this.mediaUrl,
    this.targetAudience = 'all',
    this.sentBy,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'broadcast_type': broadcastType,
      'media_url': mediaUrl,
      'target_audience': targetAudience,
      'sent_by': sentBy,
      'sent_at': sentAt.toIso8601String(),
    };
  }

  factory Broadcast.fromMap(Map<String, dynamic> map) {
    return Broadcast(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      broadcastType: map['broadcast_type'],
      mediaUrl: map['media_url'],
      targetAudience: map['target_audience'],
      sentBy: map['sent_by'],
      sentAt: DateTime.parse(map['sent_at']),
    );
  }
}
