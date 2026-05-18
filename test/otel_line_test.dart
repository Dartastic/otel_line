// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_line/otel_line.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(serviceName: 'otel_line-test');
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('login records channel + scopes + bot prompt', () async {
    await tracedLine<String>(
      operation: 'login',
      invoke: () async => const LineCallResult(
        value: 'ok',
        result: LineResult(
          channelId: 'ch_1',
          userId: 'U12345',
          platform: 'ios',
          loginType: 'lineSdk',
          scopesGranted: ['openid', 'profile'],
          botPrompt: 'aggressive',
          friendshipStatusChanged: true,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('line login')!);
    expect(a['line.channel.id'], 'ch_1');
    expect(a['line.bot_prompt'], 'aggressive');
    expect(a['line.friendship_status_changed'], true);
  });

  test('INVALID_TOKEN sets span error', () async {
    await tracedLine<String>(
      operation: 'verifyAccessToken',
      invoke: () async => const LineCallResult(
        value: 'ok',
        result: LineResult(errorCode: 'INVALID_TOKEN', statusCode: 401),
      ),
    );
    expect(
      spans.findSpanByName('line verifyAccessToken')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutLineInstrumentationAsync(() async {
      await tracedLine<String>(
        operation: 'logout',
        invoke: () async => const LineCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('line '), isEmpty);
  });
}
