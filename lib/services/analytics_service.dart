import 'package:posthog_flutter/posthog_flutter.dart';

import '../core/config.dart';

/// Thin wrapper around the PostHog SDK so the rest of the app can fire
/// analytics events without depending on PostHog directly. Every call is a
/// no-op until [init] succeeds with a configured API key, which keeps widget
/// tests and local development quiet.
class AnalyticsService {
  bool _configured = false;

  Future<void> init() async {
    if (!AppConfig.analyticsConfigured) return;
    await Posthog().setup(PostHogConfig(AppConfig.posthogApiKey));
    _configured = true;
  }

  void identify(String? userId) {
    if (!_configured || userId == null || userId.isEmpty) return;
    Posthog().identify(userId: userId);
  }

  void track(String eventName, {Map<String, Object>? properties}) {
    if (!_configured) return;
    Posthog().capture(eventName: eventName, properties: properties);
  }
}