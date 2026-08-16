import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/models.dart';

class ProfileService {
  static const String _table = 'profiles';

  Future<Profile> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    final data = await supabase
        .from(_table)
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
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    await supabase.from(_table).update({
      'display_name': displayName,
    }).eq('id', user.id);
    await supabase.auth.updateUser(
      UserAttributes(data: {'display_name': displayName}),
    );
  }
}