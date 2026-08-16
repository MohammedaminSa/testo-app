import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';

/// Provides the analytics service. `main` overrides this with the instance it
/// initializes before the app starts; the default is an unconfigured no-op so
/// widget tests can rely on events being silently ignored.
final analyticsProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);