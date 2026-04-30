import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/workout_log.dart';

class WorkoutService {
  WorkoutService(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'workout-photos';

  Future<List<WorkoutLog>> listForGroup(String groupId, {int limit = 50}) async {
    final rows = await _client
        .from('workout_logs')
        .select()
        .eq('group_id', groupId)
        .order('logged_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => WorkoutLog.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkoutLog>> listForUserInGroup({
    required String userId,
    required String groupId,
    DateTime? since,
  }) async {
    var query = _client
        .from('workout_logs')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId);
    if (since != null) {
      query = query.gte('logged_at', since.toIso8601String());
    }
    final rows = await query.order('logged_at', ascending: false);
    return (rows as List)
        .map((r) => WorkoutLog.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> _uploadPhoto({
    required String userId,
    required File photo,
  }) async {
    final id = const Uuid().v4();
    final path = '$userId/$id.jpg';
    await _client.storage.from(_bucket).upload(
          path,
          photo,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<WorkoutLog> logWorkout({
    required String userId,
    required String groupId,
    required int durationMinutes,
    required String workoutType,
    File? photo,
  }) async {
    String? photoUrl;
    if (photo != null) {
      photoUrl = await _uploadPhoto(userId: userId, photo: photo);
    }
    final inserted = await _client
        .from('workout_logs')
        .insert({
          'user_id': userId,
          'group_id': groupId,
          'duration_minutes': durationMinutes,
          'workout_type': workoutType,
          'photo_url': photoUrl,
        })
        .select()
        .single();
    return WorkoutLog.fromMap(inserted);
  }
}
