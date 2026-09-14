// A complete, deployable bot: welcomes new group members and requires
// them to pass a simple button-tap "captcha" before they can send
// messages — a common anti-spam-bot measure ("prove you're human by
// tapping this button within 2 minutes, or you'll be removed").
//
// Requires the bot to be a group admin with "Restrict members" permission
// (new members are muted on join, then unmuted once they tap the button).

import 'dart:async';

import 'package:ptgb/ptgb.dart';

void main() async {
  final bot = Bot();

  // userId -> the timer that will kick them if they don't verify in time.
  final pendingVerification = <int, Timer>{};

  print('Welcome bot running.');

  await for (final update in bot.poll()) {
    final message = update.message;
    final chatId = update.chatId;
    if (message == null || chatId == null) continue;

    final newMembers = message.newChatMembers;
    if (newMembers != null) {
      for (final member in newMembers) {
        if (member.isBot) continue; // don't captcha other bots
        await bot.restrictChatMember(
          chatId: chatId,
          userId: member.id,
          permissions: const ChatPermissions(canSendMessages: false),
        );
        await bot.sendMessage(
          chatId: chatId,
          text: 'Welcome, ${member.firstName}! Tap the button below within 2 minutes to unlock chatting.',
          replyMarkup: InlineKeyboardMarkup.single(
            row: [InlineKeyboardButton.callback(text: '✅ I\'m human', data: 'verify:${member.id}')],
          ),
        );
        pendingVerification[member.id] = Timer(const Duration(minutes: 2), () async {
          if (pendingVerification.containsKey(member.id)) {
            pendingVerification.remove(member.id);
            await bot.banChatMember(chatId: chatId, userId: member.id);
            await bot.unbanChatMember(chatId: chatId, userId: member.id); // ban+unban = kick, not a permanent ban
            await bot.sendMessage(chatId: chatId, text: '${member.firstName} didn\'t verify in time and was removed.');
          }
        });
      }
      continue;
    }

    final callback = update.callbackQuery;
    if (callback != null) {
      final data = callback.data ?? '';
      if (data.startsWith('verify:')) {
        final expectedUserId = int.parse(data.substring('verify:'.length));
        if (callback.from.id != expectedUserId) {
          await bot.answerCallbackQuery(callbackQueryId: callback.id, text: 'This button isn\'t for you.');
          continue;
        }
        pendingVerification.remove(expectedUserId)?.cancel();
        await bot.restrictChatMember(
          chatId: chatId,
          userId: expectedUserId,
          permissions: const ChatPermissions(
            canSendMessages: true,
            canSendPhotos: true,
            canSendVideos: true,
            canSendOtherMessages: true,
          ),
        );
        await bot.answerCallbackQuery(callbackQueryId: callback.id, text: 'Verified! Welcome aboard.');
        final messageId = callback.message?['message_id'] as int?;
        if (messageId != null) {
          await bot.editMessageText(chatId: chatId, messageId: messageId, text: '✅ Verified — welcome!');
        }
      }
    }
  }
}
