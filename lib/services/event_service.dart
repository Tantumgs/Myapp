import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';

class EventService {
  final SupabaseClient _client;

  EventService(this._client);

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<void> ensureUserExists(String userId) async {
    try {
      await _client.from('users').insert({'id': userId}).select().single();
    } catch (e) {
      // User already exists or table doesn't exist
    }
  }

  Future<Event> createEvent(Event event) async {
    final uuid = const Uuid().v4();
    final response = await _client.from('events').insert({
      'id': uuid,
      'title': event.title,
      'description': event.description,
      'creator_id': event.creatorId,
      'created_at': event.createdAt.toIso8601String(),
    }).select().single();
    return Event.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Event>> getAvailableEvents() async {
    final response = await _client.from('events').select().order('created_at', ascending: false);
    return (response as List).map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Event>> getMyEvents(String userId) async {
    final response = await _client.from('events').select().eq('creator_id', userId).order('created_at', ascending: false);
    return (response as List).map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getParticipantCount(String eventId) async {
    final response = await _client.from('event_participants').select().eq('event_id', eventId);
    return (response as List).length;
  }

  Future<bool> isUserJoined(String eventId, String userId) async {
    final response = await _client.from('event_participants').select().eq('event_id', eventId).eq('user_id', userId).limit(1);
    return (response as List).isNotEmpty;
  }

  Future<void> joinEvent(String eventId, String userId) async {
    await _client.from('event_participants').insert({
      'id': const Uuid().v4(),
      'event_id': eventId,
      'user_id': userId,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    await _client.from('event_participants').delete().eq('event_id', eventId).eq('user_id', userId);
  }

  Future<List<EventParticipant>> getEventParticipants(String eventId) async {
    final response = await _client.from('event_participants').select().eq('event_id', eventId);
    return (response as List).map((e) => EventParticipant.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getViewCount(String eventId) async {
    final response = await _client.from('event_views').select().eq('event_id', eventId);
    return (response as List).length;
  }

  Future<void> recordView(String eventId, String userId) async {
    final existing = await _client.from('event_views').select().eq('event_id', eventId).eq('user_id', userId).limit(1);
    if ((existing as List).isEmpty) {
      await _client.from('event_views').insert({
        'id': const Uuid().v4(),
        'event_id': eventId,
        'user_id': userId,
        'viewed_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  Future<void> updateEvent(String eventId, {required String title, required String description}) async {
    await _client.from('events').update({
      'title': title,
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId);
  }

  Future<void> removeParticipant(String eventId, String participantId) async {
    await _client.from('event_participants').delete().eq('id', participantId);
  }
}