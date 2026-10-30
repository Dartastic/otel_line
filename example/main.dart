// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_line/otel_line.dart';

/// Traces LINE calls with OpenTelemetry.
///
/// `otel_line` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each LINE call in
/// [tracedLine]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'line-example');

  // Wraps a LINE SDK call in a CLIENT span.
  final lineId = await tracedLine<String>(
    operation: 'create',
    invoke: () async {
      // Make the LINE call here, then report what it returned.
      const id = 'line_8f3a2c';
      return const LineCallResult(
          value: id,
          result: LineResult(
              channelId: 'channel_8f3a2c',
              userId: 'U3Mtw8f3a2c3Mtw8f3a2c3Mtw8f3a2c',
              platform: 'ios',
              loginType: 'lineSdk',
              scopesGranted: ['openid'],
              scopesRequested: ['example'],
              idTokenLength: 128,
              accessTokenLength: 128,
              refreshTokenLength: 128,
              expiresInSec: 1,
              botPrompt: 'aggressive',
              friendshipStatusChanged: true,
              shareTargetCount: 3,
              errorCode: 'INVALID_TOKEN',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedLine create returned $lineId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutLineInstrumentationAsync.
  await runWithoutLineInstrumentationAsync(
    () => tracedLine<String>(
      operation: 'create',
      invoke: () async {
        const id = 'line_8f3a2c';
        return const LineCallResult(
            value: id,
            result: LineResult(
                channelId: 'channel_8f3a2c',
                userId: 'U3Mtw8f3a2c3Mtw8f3a2c3Mtw8f3a2c',
                platform: 'ios',
                loginType: 'lineSdk',
                scopesGranted: ['openid'],
                scopesRequested: ['example'],
                idTokenLength: 128,
                accessTokenLength: 128,
                refreshTokenLength: 128,
                expiresInSec: 1,
                botPrompt: 'aggressive',
                friendshipStatusChanged: true,
                shareTargetCount: 3,
                errorCode: 'INVALID_TOKEN',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
