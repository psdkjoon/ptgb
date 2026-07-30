// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 02 — COMMANDS AND TEXT HANDLING
// ============================================================================
//
// Real bots respond to `/commands` (like /start and /help) and route
// different text to different logic. This example shows:
//   - Loading the token from a `.env` file instead of hard-coding it.
//   - A simple command router using a switch statement.
//   - Registering the command list so Telegram shows it in the `/` menu.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/02_commands_and_text.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  // Calling `Bot()` with no `token` argument makes ptgb look for a `.env`
  // file (via the `penv` package) and read the `TOKEN` key from it. This
  // keeps secrets out of your source code — remember to add `.env` to
  // your `.gitignore` (already done for you if you used this package's
  // own .gitignore as a starting point).
  final bot = Bot();

  // Registering commands makes Telegram show a "/" menu with descriptions,
  // instead of the user having to guess what commands exist.
  await bot.setMyCommands([
    {'command': 'start', 'description': 'Say hello'},
    {'command': 'help', 'description': 'List available commands'},
    {'command': 'time', 'description': 'Show the current server time'},
  ]);

  await for (final update in bot.poll()) {
    final text = update.text;
    final chatId = update.chatId;
    if (text == null || chatId == null) continue;

    // A simple router: commands start with "/", everything else is
    // treated as plain conversation.
    switch (text.split(' ').first) {
      case '/start':
        await bot.sendMessage(
          chatId,
          'Hi! I understand /start, /help, and /time.',
        );
      case '/help':
        await bot.sendMessage(
          chatId,
          '*Available commands:*\n'
          '/start — say hello\n'
          '/help — show this message\n'
          '/time — show the current time',
          parseMode: ParseMode.markdown,
        );
      case '/time':
        await bot.sendMessage(chatId, 'Server time: ${DateTime.now()}');
      default:
        // Anything that isn't a known command is just echoed back.
        await bot.sendMessage(chatId, 'Unknown command. Try /help.');
    }
  }
}
