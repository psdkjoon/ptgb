// This is the canonical "example" pub.dev shows on the package page.
//
// It is intentionally tiny: a bot that replies "pong" to every "ping" it
// receives. For a guided tour from beginner to advanced usage, see the
// numbered files in this same folder (start with `01_basic_echo_bot.dart`)
// and `README.md`.
//
// NOTE: this file passes the token directly, as a plain string, so pub.dev
// can show a complete, self-contained snippet with no extra setup. This is
// fine for a 30-second copy-paste experiment, but DO NOT do this in a real
// project: a token hard-coded in source ends up in your git history and
// anywhere else that source is shared. Every other example in this folder
// loads the token from a `.env` file instead (via `Bot()` with no
// arguments) — that's the approach to actually use.

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  // 1. Create a Bot using the token from @BotFather.
  final bot = Bot(token: 'YOUR_BOT_TOKEN_HERE');

  // 2. Start receiving updates. `poll()` handles long-polling and offset
  //    tracking for you, so this is all you need for a working bot.
  await for (final update in bot.poll()) {
    if (update.text == 'ping') {
      await bot.sendMessage(update.chatId!, 'pong');
    }
  }
}
