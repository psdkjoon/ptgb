// A complete, deployable bot: anonymous 1-on-1 chat pairing.
//
// Users send /find to join a queue; as soon as two people are waiting,
// they're paired up and every message one sends is relayed to the other —
// without either side ever seeing the other's name, username, or Telegram
// ID. Either side can send /stop to end the chat and requeue.
//
// This is the pattern behind "random chat" bots: no group chat, no shared
// contact info, just a relay through the bot. Pairings and the waiting
// queue are kept in memory (they don't need to survive a restart — anyone
// mid-chat when the bot restarts just gets requeued), but each user's
// "which partner am I paired with right now" pointer is the only state
// that matters, so a `Map<int, int>` is enough.

import 'package:ptgb/ptgb.dart';

void main() async {
  final bot = Bot();

  // userId -> partnerId for everyone currently in an active chat.
  final partners = <int, int>{};
  // Users waiting for a partner, in the order they joined.
  final waiting = <int>[];

  Future<void> endChat(int userId, {required bool notifyPartner}) async {
    final partnerId = partners.remove(userId);
    if (partnerId != null) {
      partners.remove(partnerId);
      if (notifyPartner) {
        await bot.sendMessage(
          chatId: partnerId,
          text: 'Your chat partner left. Send /find to meet someone new.',
        );
      }
    }
    waiting.remove(userId);
  }

  await bot.setMyCommands(commands: [
    {'command': 'find', 'description': 'Find a random chat partner'},
    {'command': 'stop', 'description': 'End the current chat'},
  ],);

  print('Hidden chat bot running. Press Ctrl+C to stop.');

  await for (final update in bot.poll()) {
    final userId = update.userId;
    final chatId = update.chatId;
    final text = update.text;
    if (userId == null || chatId == null) continue;

    if (text == '/find') {
      if (partners.containsKey(userId)) {
        await bot.sendMessage(chatId: chatId, text: 'You\'re already chatting — send /stop first.');
        continue;
      }
      if (waiting.isEmpty) {
        waiting.add(userId);
        await bot.sendMessage(chatId: chatId, text: 'Looking for a partner... you\'ll be notified when someone joins.');
        continue;
      }
      // Pair with whoever's been waiting longest (never pair with yourself,
      // in case of a duplicate /find from the same user).
      final partnerId = waiting.firstWhere((id) => id != userId, orElse: () => -1);
      if (partnerId == -1) {
        continue; // only person waiting was themselves; stay queued
      }
      waiting.remove(partnerId);
      partners[userId] = partnerId;
      partners[partnerId] = userId;
      const found = 'Partner found! Say hi — everything you send is relayed '
          'anonymously. Send /stop to end the chat.';
      await bot.sendMessage(chatId: userId, text: found);
      await bot.sendMessage(chatId: partnerId, text: found);
    } else if (text == '/stop') {
      final wasChatting = partners.containsKey(userId);
      await endChat(userId, notifyPartner: true);
      await bot.sendMessage(
        chatId: chatId,
        text: wasChatting
            ? 'Chat ended. Send /find to meet someone new.'
            : 'You\'re not in a chat. Send /find to start one.',
      );
    } else if (text != null) {
      final partnerId = partners[userId];
      if (partnerId == null) {
        await bot.sendMessage(chatId: chatId, text: 'Send /find to get matched with someone, then just type to chat.');
      } else {
        await bot.sendMessage(chatId: partnerId, text: text);
      }
    }
  }
}
