// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 35 — BUSINESS ACCOUNT STARS AND MESSAGE MANAGEMENT
// ============================================================================
//
// More Business Connection methods, this time around Stars and messages
// rather than profile fields:
//   - `getBusinessAccountStarBalance` / `transferBusinessAccountStars`
//   - `readBusinessMessage` — marks a message as read on the connected
//     account's behalf.
//   - `deleteBusinessMessages` — deletes messages the *connected account*
//     sent (not messages the bot sent on their behalf).
//
// See `34_business_account_profile.dart` for how `businessConnectionId`
// arrives in your update stream.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. Connect a Business Account to this bot in Telegram's settings.
//   3. dart run example/35_business_stars_and_messages.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final businessConnectionId =
        update.businessConnection?['id'] as String?;
    if (chatId == null || text == null || businessConnectionId == null)
      continue;

    if (text == '/star_balance') {
      final balance =
          await bot.getBusinessAccountStarBalance(businessConnectionId);
      await bot.sendMessage(
        chatId,
        'Business account Star balance: ${balance['amount']}',
      );
    } else if (text == '/withdraw_stars') {
      // Moves Stars out of the connected business account into the bot's
      // own balance — requires the account's owner to have granted the
      // relevant right when connecting.
      await bot.transferBusinessAccountStars(businessConnectionId, 100);
      await bot.sendMessage(chatId, 'Transferred 100 Stars.');
    } else if (text == '/mark_read') {
      final targetMessageId = update.replyToMessage?['message_id'] as int?;
      if (targetMessageId != null) {
        await bot.readBusinessMessage(
          businessConnectionId,
          chatId,
          targetMessageId,
        );
        await bot.sendMessage(chatId, 'Marked as read.');
      }
    } else if (text == '/delete_last') {
      final targetMessageId = update.replyToMessage?['message_id'] as int?;
      if (targetMessageId != null) {
        // Accepts a batch of message IDs, same as `deleteMessages`.
        await bot
            .deleteBusinessMessages(businessConnectionId, [targetMessageId]);
        await bot.sendMessage(chatId, 'Deleted.');
      }
    } else {
      await bot.sendMessage(
        chatId,
        'Try /star_balance, /withdraw_stars, or reply with /mark_read or /delete_last.',
      );
    }
  }
}
