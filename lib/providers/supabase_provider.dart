import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

/// The one place that touches the global Supabase client. Every repository
/// gets its client from here, so screens never import the global getter.
final supabaseProvider = Provider<SupabaseClient>((ref) => supabase);
