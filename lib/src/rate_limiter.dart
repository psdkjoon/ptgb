import 'dart:async';
import 'dart:collection';

/// An optional flood-control helper — pass one to [Bot]'s constructor to
/// automatically pace outgoing requests so a burst of sends doesn't trip
/// Telegram's rate limits.
///
/// `ptgb` does not enable this by default; without a [RateLimiter], `Bot`
/// sends requests as fast as you call its methods, and it's on you to
/// handle `TelegramApiException`s with `errorCode == 429` yourself (see
/// `example/15_error_handling_and_retries.dart`). Passing a [RateLimiter]
/// instead pre-emptively spaces requests out so you hit 429s far less often
/// in the first place. The two approaches are complementary — a
/// [RateLimiter] shouldn't be treated as a guarantee you'll never see a 429
/// (Telegram's exact limits aren't fully published and can vary), so still
/// keep a `try`/`catch` around calls that matter.
///
/// Telegram's commonly cited guidance is: no more than ~30 requests per
/// second overall (across all chats), and no more than one message per
/// second sustained to the same chat (short bursts of a handful are usually
/// tolerated, but not indefinitely). [RateLimiter]'s defaults follow that
/// guidance; override [globalPerSecond] and [perChatPerSecond] if your bot's
/// traffic pattern calls for something different.
///
/// This is an in-memory, single-process limiter — it isn't shared across
/// multiple instances of your bot (e.g. horizontally scaled workers sharing
/// one token), and per-chat state isn't persisted across restarts, so treat
/// it as best-effort pacing rather than a hard external guarantee.
///
/// ```dart
/// final bot = Bot(rateLimiter: RateLimiter());
/// // Every call to a typed method (sendMessage, sendPhoto, ...) — and to
/// // the low-level `call()` escape hatch — now waits its turn automatically.
/// ```
class RateLimiter {
  /// Maximum requests per second across all chats combined.
  final double globalPerSecond;

  /// Maximum requests per second to any single chat.
  final double perChatPerSecond;

  final _MinIntervalGate _global;
  final HashMap<Object, _MinIntervalGate> _perChat = HashMap();

  /// Creates a limiter. Defaults follow Telegram's commonly cited guidance:
  /// 30 requests/second overall, 1 request/second per chat.
  RateLimiter({this.globalPerSecond = 30, this.perChatPerSecond = 1})
      : _global = _MinIntervalGate(1 / globalPerSecond);

  /// Waits until it's safe to send another request. Pass [chatId] (the
  /// `chat_id` value of the request, if it has one) to also enforce the
  /// per-chat limit; omit it for chat-less methods like `getMe`.
  ///
  /// Called automatically by [Bot.call] once a [RateLimiter] has been
  /// passed to [Bot]'s constructor — you generally don't need to call this yourself.
  Future<void> acquire([Object? chatId]) async {
    final chatGate = chatId == null
        ? null
        : _perChat.putIfAbsent(
            chatId,
            () => _MinIntervalGate(1 / perChatPerSecond),
          );
    // Reserve both slots synchronously (before awaiting either) so
    // concurrent acquire() calls don't race on the same gate.
    final globalWait = _global.reserve();
    final chatWait = chatGate?.reserve();
    await globalWait;
    if (chatWait != null) await chatWait;
  }
}

/// Enforces a minimum gap of [intervalSeconds] between successive
/// reservations, queueing callers in the order they reserved a slot.
class _MinIntervalGate {
  final double intervalSeconds;
  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  _MinIntervalGate(this.intervalSeconds);

  /// Synchronously claims the next available slot and returns a [Future]
  /// that completes once that slot's time arrives.
  Future<void> reserve() {
    final now = DateTime.now();
    final slot = _nextSlot.isAfter(now) ? _nextSlot : now;
    _nextSlot =
        slot.add(Duration(microseconds: (intervalSeconds * 1e6).round()));
    final delay = slot.difference(now);
    return delay > Duration.zero
        ? Future<void>.delayed(delay)
        : Future<void>.value();
  }
}
