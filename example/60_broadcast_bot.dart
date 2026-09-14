// A complete, deployable bot: lets a configured admin broadcast a message
// to every user and chat that's ever messaged the bot — the classic
// "announcement bot" pattern, e.g. for a product update or outage notice.
//
// Everyone who talks to the bot is remembered via [BotStorage] (as any
// bot using it typically would for other features too); the admin sends
// /broadcast followed by the message, and it's relayed to everyone,
// skipping any recipient who's blocked the bot (Telegram reports that
// as a `TelegramApiException` per-send, which is caught and skipped
// rather than stopping the whole broadcast).
//
// Setup: put your numeric chat ID in `.env` as `ADMIN_CHAT_ID=...`.

import 'package:penv/penv.dart';
import 'package:ptgb/ptgb.dart';

void main() async {
  final bot = Bot();
  final adminChatIdRaw = penvload('.env')['ADMIN_CHAT_ID'];
  final adminChatId = adminChatIdRaw == null ? null : int.tryParse(adminChatIdRaw);
  if (adminChatId == null) {
    print('Add ADMIN_CHAT_ID=<your numeric chat id> to your .env file.');
    return;
  }

  final storage = BotStorage(path: 'broadcast_data.json');
  await storage.load();

  print('Broadcast bot running. Admin: $adminChatId');

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final user = update.from;
    if (chatId == null || user == null) continue;

    await storage.saveUser(user: user);
    final chat = update.chat;
    if (chat != null) await storage.saveChat(chat: chat);

    if (chatId != adminChatId) {
      if (text == '/start') {
        await bot.sendMessage(chatId: chatId, text: 'Hi! You\'ll receive announcements here from time to time.');
      }
      continue;
    }

    if (text != null && text.startsWith('/broadcast ')) {
      final announcement = text.substring('/broadcast '.length);
      final recipients = {
        for (final u in storage.allUsers()) u.id,
        for (final c in storage.allChats()) c.id,
      };
      var sent = 0;
      var failed = 0;
      for (final recipientId in recipients) {
        try {
          await bot.sendMessage(chatId: recipientId, text: announcement);
          sent++;
        } on TelegramApiException {
          // Most commonly: the user blocked the bot, or the chat no
          // longer exists. Skip and keep going rather than aborting.
          failed++;
        }
      }
      await bot.sendMessage(chatId: adminChatId, text: 'Broadcast sent to $sent recipient(s), $failed failed.');
    } else if (text == '/stats') {
      await bot.sendMessage(
        chatId: adminChatId,
        text: 'Known users: ${storage.allUsers().length}\nKnown chats: ${storage.allChats().length}',
      );
    } else if (text == '/start') {
      await bot.sendMessage(chatId: adminChatId, text: 'Send /broadcast <message> to announce to everyone, or /stats for counts.');
    }
  }
}
