import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Reads/updates the signed-in user's profile.
class ProfileRepository {
  final SupabaseClient _client;

  const ProfileRepository(this._client);

  Future<Profile> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) {
      return Profile(
        id: user.id,
        displayName: user.userMetadata?['display_name'] as String? ?? '',
        createdAt: DateTime.parse(user.createdAt),
      );
    }
    return Profile.fromMap(data);
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    await _client.from('profiles').update({
      'display_name': displayName,
    }).eq('id', user.id);
    await _client.auth.updateUser(
      UserAttributes(data: {'display_name': displayName}),
    );
  }
}