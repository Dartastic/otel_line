// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_line_suppression.dart';

const _tracerName = 'dartastic_otel_libs_line';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class LineResult {
  const LineResult({
    this.channelId,
    this.userId,
    this.platform,
    this.loginType,
    this.scopesGranted,
    this.scopesRequested,
    this.idTokenLength,
    this.accessTokenLength,
    this.refreshTokenLength,
    this.expiresInSec,
    this.botPrompt,
    this.friendshipStatusChanged,
    this.shareTargetCount,
    this.errorCode,
    this.statusCode,
  });

  /// LINE Developers Console channel id.
  final String? channelId;

  /// LINE user id (`Uxxxxxxxxx`).
  final String? userId;

  /// `ios`, `android`, `web`.
  final String? platform;

  /// `lineSdk`, `webLogin`, `qrLogin`.
  final String? loginType;

  /// `openid`, `profile`, `email`, custom permissions.
  final List<String>? scopesGranted;
  final List<String>? scopesRequested;

  final int? idTokenLength;
  final int? accessTokenLength;
  final int? refreshTokenLength;

  final int? expiresInSec;

  /// `aggressive` / `normal` — LINE Bot prompt mode.
  final String? botPrompt;

  /// User added/removed the channel's official account during the flow.
  final bool? friendshipStatusChanged;

  /// `sendMessage` target count.
  final int? shareTargetCount;

  /// LINE API error code (e.g. `INVALID_TOKEN`, `INVALID_GRANT`,
  /// `USER_NOT_FRIEND`, `INVALID_FRIENDSHIP_STATUS`).
  final String? errorCode;
  final int? statusCode;
}

class LineCallResult<T> {
  const LineCallResult({required this.value, this.result});
  final T value;
  final LineResult? result;
}

/// Wraps a LINE SDK call in a CLIENT span. [operation] is one of
/// `login`, `logout`, `refreshAccessToken`, `verifyAccessToken`,
/// `getCurrentAccessToken`, `getProfile`, `getBotFriendshipStatus`,
/// `getFriends`, `sendMessage`, `sendMulticast`.
Future<T> tracedLine<T>({
  required String operation,
  required Future<LineCallResult<T>> Function() invoke,
}) async {
  if (lineInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'line',
    'rpc.method': operation,
    'line.operation': operation,
  };

  final span = _tracer().startSpan(
    'line $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.channelId != null) {
        extras.add(OTel.attributeString('line.channel.id', res.channelId!));
      }
      if (res.userId != null) {
        extras.add(OTel.attributeString('line.user.id', res.userId!));
      }
      if (res.platform != null) {
        extras.add(OTel.attributeString('line.platform', res.platform!));
      }
      if (res.loginType != null) {
        extras.add(OTel.attributeString('line.login.type', res.loginType!));
      }
      if (res.scopesGranted != null) {
        extras.add(OTel.attributeStringList(
          'line.scopes.granted',
          res.scopesGranted!,
        ));
      }
      if (res.scopesRequested != null) {
        extras.add(OTel.attributeStringList(
          'line.scopes.requested',
          res.scopesRequested!,
        ));
      }
      if (res.idTokenLength != null) {
        extras.add(OTel.attributeInt(
          'line.id_token.length',
          res.idTokenLength!,
        ));
      }
      if (res.accessTokenLength != null) {
        extras.add(OTel.attributeInt(
          'line.access_token.length',
          res.accessTokenLength!,
        ));
      }
      if (res.refreshTokenLength != null) {
        extras.add(OTel.attributeInt(
          'line.refresh_token.length',
          res.refreshTokenLength!,
        ));
      }
      if (res.expiresInSec != null) {
        extras.add(OTel.attributeInt(
          'line.expires_in_sec',
          res.expiresInSec!,
        ));
      }
      if (res.botPrompt != null) {
        extras.add(OTel.attributeString('line.bot_prompt', res.botPrompt!));
      }
      if (res.friendshipStatusChanged != null) {
        extras.add(OTel.attributeBool(
          'line.friendship_status_changed',
          res.friendshipStatusChanged!,
        ));
      }
      if (res.shareTargetCount != null) {
        extras.add(OTel.attributeInt(
          'line.share.target_count',
          res.shareTargetCount!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString('line.error.code', res.errorCode!));
        span.setStatus(SpanStatusCode.Error, 'LINE ${res.errorCode}');
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(SpanStatusCode.Error, 'LINE HTTP ${res.statusCode}');
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
