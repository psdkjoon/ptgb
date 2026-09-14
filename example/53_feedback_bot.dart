// A complete, deployable bot: collect anonymous feedback and relay it to
// an admin, without the admin ever seeing who sent it.
//
// Anyone can message the bot directly to leave feedback; it's relayed to
// the configured admin chat via [Bot.copyMessage] (not [Bot.forwardMessage]
// — forwarding keeps a "Forwarded from <name>" tag, which would break
// anonymity; copying sends a fresh, sender-less copy instead). The admin
// can reply to that copy, and the bot relays the reply back to the
// original sender — so it works like a one-way anonymous inbox with an
// optional response channel, without exposing either side's identity.
//
// Setup: put the admin's numeric chat ID in your `.env` file as
// `ADMIN_CHAT_ID=...` (send /start to @userinfobot to find your own ID).

import 'dart:convert';

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

  final storage = BotStorage(path: 'feedback_data.json');
  await storage.load();
  // Make sure the admin chat has a record to attach custom data to (see
  // BotStorage.setChatData's docs — it requires an existing saveChat first).
  await storage.saveChat(chat: Chat({'id': adminChatId, 'type': 'private'}));

  // relayedMessageId (in the admin chat) -> original sender's chatId, kept
  // as one JSON map under the admin chat's own custom data.
  Future<Map<String, int>> loadRelayMap() async {
    final raw = storage.getChatData(chatId: adminChatId, key: 'relay_map') as String?;
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
  }

  Future<void> saveRelayMap(Map<String, int> map) =>
      storage.setChatData(chatId: adminChatId, key: 'relay_map', value: jsonEncode(map));

  print('Feedback bot running. Anonymous messages go to chat $adminChatId.');

  await for (final update in bot.poll()) {
    final message = update.message;
    final chatId = update.chatId;
    final user = update.from;
    if (message == null || chatId == null || user == null) continue;

    if (chatId == adminChatId) {
      // The admin replying to a relayed message sends that reply back to
      // the original (anonymous, to the admin) sender.
      final replyTo = message.replyToMessage;
      if (replyTo != null) {
        final relayMap = await loadRelayMap();
        final originalSenderId = relayMap[replyTo.messageId.toString()];
        if (originalSenderId != null) {
          await bot.copyMessage(chatId: originalSenderId, fromChatId: chatId, messageId: message.messageId);
          await bot.sendMessage(chatId: chatId, text: '↩️ Reply sent.');
        }
      } else if (message.text == '/start') {
        await bot.sendMessage(chatId: chatId, text: 'This is your feedback inbox. Reply to any message here to respond anonymously.');
      }
      continue;
    }

    // Anyone else: relay their message anonymously to the admin, and
    // remember which relayed-message-id maps back to which sender so a
    // later admin reply can find its way back.
    final copied = await bot.copyMessage(chatId: adminChatId, fromChatId: chatId, messageId: message.messageId);
    final relayMap = await loadRelayMap();
    relayMap[copied.messageId.toString()] = chatId;
    await saveRelayMap(relayMap);
    await bot.sendMessage(chatId: chatId, text: '✅ Sent anonymously. You\'ll get a reply here if the admin responds.');
  }
}
