// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 01 — BASIC ECHO BOT
// ============================================================================
//
// The simplest possible bot: it echoes back whatever text you send it.
// This example shows the three things every ptgb bot needs:
//   1. Create a `Bot`.
//   2. Listen for updates.
//   3. Call a method on `bot` in response.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/01_basic_echo_bot.dart
// ============================================================================

import 'dart:developer';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  // A `Bot` is your single entry point to the entire Telegram Bot API.
  // Create exactly one and reuse it for the whole lifetime of your program.
  //
  // Calling `Bot()` with no `token` argument makes ptgb look for a `.env`
  // file (via the `penv` package) and read the `TOKEN` key from it. This
  // is the recommended way to supply your token — it keeps secrets out of
  // your source code and git history. Add `.env` to your `.gitignore`
  // (already done for you if you used this package's own .gitignore as a
  // starting point).
  //
  // `Bot(token: '...')` also exists, for passing a token you're managing
  // yourself (e.g. from a secrets manager) — see `ptgb_example.dart` for
  // what that looks like. Avoid hard-coding a real token either way.
  final bot = Bot();

  log('Bot started. Send it a message on Telegram!');

  // `bot.poll()` returns a Stream<Update> that yields every new update
  // (message, button press, etc) as it arrives. Looping over it with
  // `await for` is the standard way to run a bot forever.
  await for (final update in bot.poll()) {
    // `update.text` is a shortcut that returns the message text, whichever
    // kind of message it came from (normal, edited, channel post, ...).
    final text = update.text;

    // `update.chatId` is a shortcut for the chat this update relates to —
    // exactly what `sendMessage` and friends expect as their first argument.
    final chatId = update.chatId;

    // Not every update has text (e.g. a photo, a button press) or a chat
    // (e.g. an inline query) — always guard against null before using them.
    if (text != null && chatId != null) {
      await bot.sendMessage(chatId, 'You said: $text');
    }
  }
}
