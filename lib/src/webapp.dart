import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'core.dart';

/// The parsed, signature-verified `initData` string sent by a Telegram Mini
/// App, as returned by [Bot.verifyWebAppInitData].
///
/// **Always check [isValid] before trusting any other field.** A `false`
/// value means the HMAC signature didn't match, which can happen if the
/// data was tampered with, is stale, or wasn't actually issued by Telegram.
class WebAppInitData {
  /// Every raw key/value pair from the `initData` query string.
  final Json fields;

  /// Whether the HMAC signature was successfully verified against the bot's token.
  final bool isValid;

  /// Wraps parsed [fields] with their [isValid] verification result.
  const WebAppInitData(this.fields, this.isValid);

  /// The Telegram user who opened the Mini App, if present.
  Json? get user => _decodeJsonField('user');

  /// The user the Mini App's message will be sent to, if applicable.
  Json? get receiver => _decodeJsonField('receiver');

  /// The chat the Mini App was opened from, if applicable.
  Json? get chat => _decodeJsonField('chat');

  /// The type of chat the Mini App was opened from (`'sender'`, `'private'`, `'group'`, etc).
  String? get chatType => fields['chat_type'] as String?;

  /// A unique identifier for the chat instance the Mini App was opened from.
  String? get chatInstance => fields['chat_instance'] as String?;

  /// The deep-link start parameter, if the Mini App was opened via a `startapp` link.
  String? get startParam => fields['start_param'] as String?;

  /// The number of seconds after which a message can be sent via the `answerWebAppQuery` method.
  int? get canSendAfter {
    final raw = fields['can_send_after'] as String?;
    return raw != null ? int.tryParse(raw) : null;
  }

  /// The moment the Mini App was opened / this data was generated.
  DateTime? get authDate {
    final raw = fields['auth_date'] as String?;
    return raw != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(raw) * 1000,
            isUtc: true,)
        : null;
  }

  /// A unique identifier for this particular Mini App session.
  String? get queryId => fields['query_id'] as String?;

  /// The Ed25519 signature of the data, an alternative to the HMAC [isValid] check.
  String? get signature => fields['signature'] as String?;

  Json? _decodeJsonField(String key) {
    final raw = fields[key];
    if (raw == null) return null;
    return jsonDecode(raw as String) as Json;
  }
}

/// Parses and cryptographically verifies a Telegram Mini App's `initData`
/// string against [botToken]. Prefer calling this through [Bot.verifyWebAppInitData].
WebAppInitData verifyWebAppInitData(String initData, String botToken) {
  final params = Uri.splitQueryString(initData);
  final receivedHash = params['hash'];
  if (receivedHash == null) return WebAppInitData(params, false);

  final entries = params.entries.where((e) => e.key != 'hash').toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final dataCheckString = entries.map((e) => '${e.key}=${e.value}').join('\n');

  final secretKey = Hmac(sha256, utf8.encode('WebAppData'))
      .convert(utf8.encode(botToken))
      .bytes;
  final computedHash =
      Hmac(sha256, secretKey).convert(utf8.encode(dataCheckString)).toString();

  return WebAppInitData(params, computedHash == receivedHash);
}
