/// `ptgb` — a full, pure-Dart Telegram Bot API client.
///
/// Import this file to get everything you need: the [Bot] class plus every
/// supporting type (keyboards, media, permissions, enums, updates,
/// built-in [BotStorage] persistence, ...).
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
///       await bot.sendMessage(chatId: update.chatId!, text: 'Hello from ptgb!');
///     }
///   }
/// }
/// ```
///
/// Want to remember your bot's users and chats between runs without
/// setting up a database? See [BotStorage] — a built-in, file-backed
/// store for users, chats, and any custom per-user/per-chat data you want
/// to keep.
///
/// See the `example/` folder in the package for a full set of runnable
/// examples, from a minimal echo bot up to a "god mode" bot exercising
/// keyboards, media, payments, stickers, forums, and webhooks.
library;

export 'src/bot.dart';
export 'src/storage.dart';
