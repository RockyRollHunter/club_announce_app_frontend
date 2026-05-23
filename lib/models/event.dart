class Event {
  final int id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;           // ← New: nullable (may be null)
  final String location;
  final DateTime createdAt;
  final String? officialLink;        // ← New: nullable (may be empty)
  final Club club;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.location,
    required this.createdAt,
    this.officialLink,
    required this.club,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      location: json['location'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      officialLink: json['official_link'],
      club: Club.fromJson(json['club']),
    );
  }
}

class Club {
  final int id;
  final String name;
  final String description;
  final String instagramHandle;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.instagramHandle,
  });
  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      instagramHandle: json['instagram_handle'] ?? '',
    );
  }
}

class Announcement {
  final int id;
  final int eventId;
  final String message;
  final DateTime timestamp;

  Announcement({
    required this.id,
    required this.eventId,
    required this.message,
    required this.timestamp,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      eventId: json['event'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}