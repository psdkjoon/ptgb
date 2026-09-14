// A complete, deployable bot: basic group moderation. Deletes messages
// containing links from non-admins (a common spam vector), tracks warnings
// per user, and automatically mutes on the 3rd warning. Admins can also
// manually /warn, /mute, or /ban by replying to a message.
//
// Add this bot to a group as an admin with "Delete messages" and
// "Restrict members" permissions for the automatic actions to work.

import 'package:ptgb/ptgb.dart';

final _linkPattern = RegExp(r'https?://|t\.me/|www\.', caseSensitive: false);

Future<bool> _isAdmin(Bot bot, int chatId, int userId) async {
  final member = await bot.getChatMember(chatId: chatId, userId: userId);
  return member.status == 'administrator' || member.status == 'creator';
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'moderation_data.json');
  await storage.load();

  Future<int> getWarnings(int userId) async {
    final count = storage.getUserData(userId: userId, key: 'warnings') as int?;
    return count ?? 0;
  }

  Future<int> addWarning(int userId) async {
    final next = await getWarnings(userId) + 1;
    await storage.setUserData(userId: userId, key: 'warnings', value: next);
    return next;
  }

  print('Moderation bot running.');

  await for (final update in bot.poll()) {
    final message = update.message;
    final chatId = update.chatId;
    final chatType = update.chatType;
    final user = update.from;
    final text = update.text;
    if (message == null || chatId == null || user == null) continue;
    if (chatType != 'group' && chatType != 'supergroup') continue;

    await storage.saveUser(user: user);

    // --- Automatic link filtering for non-admins ---
    if (text != null && _linkPattern.hasMatch(text) && !await _isAdmin(bot, chatId, user.id)) {
      await bot.deleteMessage(chatId: chatId, messageId: message.messageId);
      final warnings = await addWarning(user.id);
      if (warnings >= 3) {
        await bot.restrictChatMember(
          chatId: chatId,
          userId: user.id,
          permissions: const ChatPermissions(canSendMessages: false),
          untilDate: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        );
        await bot.sendMessage(chatId: chatId, text: '${user.firstName} was muted for 1 hour after 3 warnings.');
      } else {
        await bot.sendMessage(chatId: chatId, text: '${user.firstName}, links aren\'t allowed here. Warning $warnings/3.');
      }
      continue;
    }

    // --- Manual admin commands, used by replying to the target's message ---
    final replyTo = update.replyToMessage;
    final target = replyTo?.from;
    if (text == '/warn' && target != null) {
      if (!await _isAdmin(bot, chatId, user.id)) continue;
      final warnings = await addWarning(target.id);
      await bot.sendMessage(chatId: chatId, text: '${target.firstName} has been warned ($warnings/3).');
    } else if (text == '/mute' && target != null) {
      if (!await _isAdmin(bot, chatId, user.id)) continue;
      await bot.restrictChatMember(
        chatId: chatId,
        userId: target.id,
        permissions: const ChatPermissions(canSendMessages: false),
      );
      await bot.sendMessage(chatId: chatId, text: '${target.firstName} has been muted.');
    } else if (text == '/ban' && target != null) {
      if (!await _isAdmin(bot, chatId, user.id)) continue;
      await bot.banChatMember(chatId: chatId, userId: target.id);
      await bot.sendMessage(chatId: chatId, text: '${target.firstName} has been banned.');
    } else if (text == '/warnings' && target != null) {
      final warnings = await getWarnings(target.id);
      await bot.sendMessage(chatId: chatId, text: '${target.firstName} has $warnings warning(s).');
    }
  }
}
