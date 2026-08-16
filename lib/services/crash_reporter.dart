import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/config.dart';

/// Initializes crash and error reporting via Sentry. A no-op when no DSN is
/// configured via dart-define, so unconfigured builds never hit the network.
Future<void> initCrashReporting() async {
  if (!AppConfig.crashReportingConfigured) return;
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.tracesSampleRate = 1.0;
    },
  );
}