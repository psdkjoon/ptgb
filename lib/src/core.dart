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
///   await bot.sendMessage(chatId, 'hi');
/// } on TelegramApiException catch (e) {
///   if (e.errorCode == 429) {
///     final retryAfter = e.parameters?['retry_after'] as int?;
///     print('Rate limited, retry after $retryAfter seconds');
///   }
/// }
/// ```
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
