// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 15 — ERROR HANDLING AND RETRIES
// ============================================================================
//
// ptgb does not retry failed requests or throttle them for you — every
// failed Bot API call surfaces as a `TelegramApiException` and it's up to
// your bot to decide what to do next. That decision depends on *why* it
// failed:
//
//   - 429 Too Many Requests — you're rate-limited. Telegram tells you
//     exactly how long to wait in `parameters['retry_after']` (seconds).
//     Wait that long, then retry the same call.
//   - 403 Forbidden — the user blocked the bot, left the chat, etc. This
//     will never succeed on retry; stop messaging that chat_id.
//   - Anything else (400 Bad Request, 500, network errors, ...) — usually a
//     bug in your request or a transient server issue. Log it and move on,
//     optionally with a couple of quick retries.
//
// This example wraps `sendMessage` in a small helper that handles all
// three cases, then hammers it with messages to demonstrate hitting a
// rate limit in practice.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/15_error_handling_and_retries.dart
// ============================================================================

import 'dart:developer';

import 'package:ptgb/ptgb.dart';

/// Sends [text] to [chatId], automatically waiting out rate limits and
/// giving up (without throwing) if the chat is unreachable.
///
/// [maxAttempts] bounds how many times we'll retry a rate-limited or
/// transient failure, so a persistently broken call can't loop forever.
Future<void> sendMessageReliably(
  Bot bot,
  int chatId,
  String text, {
  int maxAttempts = 5,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await bot.sendMessage(chatId, text);
      return;
    } on TelegramApiException catch (e) {
      if (e.errorCode == 429) {
        // Telegram tells us exactly how long to back off.
        final retryAfter = e.parameters?['retry_after'] as int? ?? 1;
        log('Rate limited sending to $chatId, waiting ${retryAfter}s '
            '(attempt $attempt/$maxAttempts)...');
        await Future<void>.delayed(Duration(seconds: retryAfter));
        continue;
      }

      if (e.errorCode == 403) {
        // The user blocked the bot / left the chat — retrying won't help.
        // A real bot would mark this chat_id inactive in its own storage.
        log('Chat $chatId is unreachable (403): ${e.description}. Giving up.');
        return;
      }

      // Anything else: log it and back off briefly before retrying, in
      // case it was a transient network/server hiccup.
      log('sendMessage to $chatId failed (${e.errorCode}): ${e.description}');
      if (attempt == maxAttempts) return;
      await Future<void>.delayed(Duration(seconds: attempt));
    }
  }
}

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    if (chatId == null || update.text != '/spam') continue;

    // Fire off a burst of messages fast enough to realistically trigger
    // Telegram's rate limiting, so you can see `sendMessageReliably` back
    // off and recover instead of crashing the loop.
    for (var i = 1; i <= 30; i++) {
      await sendMessageReliably(bot, chatId, 'Message #$i');
    }
    await sendMessageReliably(bot, chatId, 'Done — sent 30 messages.');
  }
}
