import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'profile-photos';

  Future<UserProfile?> get(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : UserProfile.fromMap(row);
  }

  Future<UserProfile> upsert({
    required String userId,
    required String name,
    String? photoUrl,
  }) async {
    final row = await _client
        .from('profiles')
        .upsert({
          'id': userId,
          'name': name,
          if (photoUrl != null) 'photo_url': photoUrl,
        })
        .select()
        .single();
    return UserProfile.fromMap(row);
  }

  Future<String> uploadPhoto({
    required String userId,
    required File file,
  }) async {
    final id = const Uuid().v4();
    final path = '$userId/$id.jpg';
    await _client.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
