// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 17 — OPTIONAL RATE LIMITING
// ============================================================================
//
// By default, ptgb sends requests as fast as you call them and leaves it to
// you to handle 429 "Too Many Requests" errors (see
// example/15_error_handling_and_retries.dart for that approach).
//
// If you'd rather avoid tripping Telegram's rate limits in the first place
// — e.g. you're broadcasting a message to a big list of chats, or replying
// to a burst of updates all at once — pass a `RateLimiter` to `Bot()`.
// It automatically paces every outgoing request:
//   - a global gate (default: 30 requests/second, across all chats)
//   - a per-chat gate (default: 1 request/second, to the same chat)
//
// Both apply to every typed method (sendMessage, sendPhoto, ...) and to the
// low-level `call()` escape hatch, with no other code changes needed.
//
// A RateLimiter paces requests proactively, but Telegram's exact limits
// aren't fully published and can vary — it's not a hard guarantee you'll
// never see a 429, so it's still worth keeping the try/catch pattern from
// example 15 around calls that really matter.
//
// HOW TO RUN:
//   dart run example/17_rate_limiting.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot(
    // Defaults shown explicitly here; omit either to use them.
    rateLimiter: RateLimiter(globalPerSecond: 30, perChatPerSecond: 1),
  );

  // Simulating a broadcast to several chats: without a RateLimiter these
  // would all fire back-to-back and could easily trip Telegram's per-chat
  // limit. With one, ptgb automatically spaces them out for you.
  final broadcastChatIds = <int>[/* ...your chat IDs... */];
  for (final chatId in broadcastChatIds) {
    await bot.sendMessage(chatId, 'Scheduled announcement!');
  }

  // Everyday polling works exactly the same as without a RateLimiter — the
  // pacing only kicks in if you're actually sending faster than the limits
  // allow, so normal traffic isn't slowed down.
  await for (final update in bot.poll()) {
    if (update.text == '/start') {
      await bot.sendMessage(
        update.chatId!,
        'Hello! My sends are now automatically paced.',
      );
    }
  }
}
