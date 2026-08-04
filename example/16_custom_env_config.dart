// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 16 — CUSTOM .env FILENAME AND KEY
// ============================================================================
//
// By default, `Bot()` looks for a file named `.env` next to your script and
// reads a key named `TOKEN` from it. If that doesn't fit your project —
// maybe you already have a `.env` with other keys, or you keep secrets in
// `secrets.env`, or you use a different key name — you can override both
// via the `dotFileName` and `envKey` parameters.
//
// This is handy if:
//   - You already use `.env` for other config and don't want ptgb's TOKEN
//     key colliding with something else.
//   - Your deployment tooling expects a specific file name.
//   - You're running multiple bots from the same project and want each one
//     to load its own file (e.g. `bot1.env`, `bot2.env`).
//
// HOW TO RUN:
//   1. Create a file named `secrets.env` next to this script containing:
//        BOT_TOKEN=123456:ABC-your-token-here
//   2. dart run example/16_custom_env_config.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  // `dotFileName` overrides which file is read (default: '.env').
  // `envKey` overrides which key inside that file holds the token
  // (default: 'TOKEN'). Both can be changed independently.
  final bot = Bot(
    dotFileName: 'secrets.env',
    envKey: 'BOT_TOKEN',
  );

  await for (final update in bot.poll()) {
    if (update.text == '/start') {
      await bot.sendMessage(
        update.chatId!,
        'Hello! I loaded my token from secrets.env.',
      );
    }
  }
}
