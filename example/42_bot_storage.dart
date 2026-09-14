// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 42 — REMEMBERING USERS AND CHATS WITH BotStorage
// ============================================================================
//
// Most bots eventually need to answer "who has talked to me before?" or
// "what did this user pick last time?". `BotStorage` handles that for you,
// backed by a plain JSON file on disk — no database setup required. This
// example saves every user and chat that messages the bot, adds a simple
// per-user counter as custom data, and shows how to read it all back.
//
// HOW TO RUN:
//   dart run example/42_bot_storage.dart   (with a `.env` file)
//
// After running it and sending a few messages, open `bot_data.json` next to
// this file to see exactly what got saved.
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  // Backed by `bot_data.json`. `load()` reads any existing data from disk,
  // or starts empty the very first time — safe to call even if the file
  // doesn't exist yet.
  final storage = BotStorage(path: 'bot_data.json');
  await storage.load();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final user = update.from;
    final text = update.text;
    if (chatId == null || text == null) continue;

    final chat = update.message?.chat;
    if (chat != null) await storage.saveChat(chat: chat);

    if (text == '/whoami') {
      // Check BEFORE saving, so a brand-new user genuinely sees the
      // "not saved yet" branch on their very first message.
      final record = user == null ? null : storage.getUser(userId: user.id);
      if (user != null) await storage.saveUser(user: user);
      await bot.sendMessage(
        chatId: chatId,
        text: record == null
            ? 'I don\'t have you saved yet — send any message first!'
            : 'You are ${record.firstName} (id: ${record.id}).',
      );
    } else if (text == '/users') {
      // Saving is cheap and idempotent — call it on every other update.
      // The first time a user is seen this creates their record; every
      // later call just refreshes their name/username in place.
      if (user != null) await storage.saveUser(user: user);
      final users = storage.allUsers();
      await bot.sendMessage(
        chatId: chatId,
        text: 'I know ${users.length} user(s) so far:\n'
            '${users.map((u) => '• ${u.firstName}').join('\n')}',
      );
    } else if (text == '/visits') {
      if (user != null) await storage.saveUser(user: user);
      // Custom per-user data: a simple visit counter, stored alongside the
      // user's built-in fields (name, username, ...).
      if (user != null) {
        final current = storage.getUserData(userId: user.id, key: 'visits') as int? ?? 0;
        final next = current + 1;
        await storage.setUserData(userId: user.id, key: 'visits', value: next);
        await bot.sendMessage(chatId: chatId, text: 'You\'ve sent /visits $next time(s).');
      }
    } else {
      if (user != null) await storage.saveUser(user: user);
      await bot.sendMessage(chatId: chatId, text: 'Try /whoami, /users, or /visits.');
    }
  }
}
