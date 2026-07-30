/// `ptgb` — a full, pure-Dart Telegram Bot API client.
///
/// Import this file to get everything you need: the [Bot] class plus every
/// supporting type (keyboards, media, permissions, enums, updates, ...).
///
/// ```dart
/// import 'package:ptgb/ptgb.dart';
///
/// void main() async {
///   // Loads the token from a `.env` file (TOKEN=...) next to your script.
///   // Pass `Bot(token: '...')` directly if you'd rather manage it yourself.
///   final bot = Bot();
///   await for (final update in bot.poll()) {
///     if (update.text == '/start') {
///       await bot.sendMessage(update.chatId!, 'Hello from ptgb!');
///     }
///   }
/// }
/// ```
///
/// See the `example/` folder in the package for a full set of runnable
/// examples, from a minimal echo bot up to a "god mode" bot exercising
/// keyboards, media, payments, stickers, forums, and webhooks.
library;

export 'src/bot.dart';
