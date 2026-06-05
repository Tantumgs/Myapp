import 'package:uuid/uuid.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] != null ? json['id'].toString() : const Uuid().v4(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'title': title,
      'description': description,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
    };
    if (updatedAt != null) {
      json['updated_at'] = updatedAt!.toIso8601String();
    }
    return json;
  }
}

class EventParticipant {
  final String id;
  final String eventId;
  final String userId;
  final DateTime joinedAt;

  EventParticipant({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.joinedAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}