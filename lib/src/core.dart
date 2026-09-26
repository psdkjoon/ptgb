/// A convenient alias for the JSON object shape used throughout `ptgb`.
///
/// Every Telegram Bot API request and response body is a JSON object.
/// `ptgb`'s typed wrapper classes (like [Message] and [Update]) read from
/// and are constructed around a `Json` — it stays available as `.raw` on
/// every wrapper, and is used directly wherever no typed wrapper exists yet.
typedef Json = Map<String, dynamic>;

/// Thrown whenever the Telegram Bot API responds with `"ok": false`.
///
/// Contains everything Telegram sent back about the failure, so you can
/// inspect [errorCode] and [description] (and [parameters] for special
/// cases like rate limiting) to decide how to react.
///
/// ```dart
/// try {
///   await bot.sendMessage(chatId: chatId, text: 'hi');
/// } on TelegramApiException catch (e) {
///   if (e.errorCode == 429) {
///     final retryAfter = e.parameters?['retry_after'] as int?;
///     print('Rate limited, retry after $retryAfter seconds');
///   }
/// }
/// ```
///
/// Common [errorCode]s you'll see in practice: `400` (bad request — a
/// parameter Telegram rejected, check [description]), `401`/`403`
/// (unauthorized/forbidden — bad token, or the bot was blocked/kicked
/// from the chat), `404` (chat/message/file not found, often because it
/// was already deleted), and `429` (too many requests — see below). If
/// you'd rather avoid `429`s proactively instead of catching them, pass a
/// [RateLimiter] to [Bot.new].
class TelegramApiException implements Exception {
  /// The numeric error code Telegram returned (e.g. `400`, `403`, `429`).
  final int errorCode;

  /// A human-readable explanation of what went wrong.
  final String description;

  /// Extra machine-readable details Telegram sometimes attaches, such as
  /// `retry_after` for rate-limit errors.
  final Json? parameters;

  /// Creates a [TelegramApiException] with the given [errorCode], [description],
  /// and optional [parameters].
  TelegramApiException(this.errorCode, this.description, this.parameters);

  @override
  String toString() => 'TelegramApiException($errorCode): $description';
}
