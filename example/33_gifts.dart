// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 33 — GIFTS
// ============================================================================
//
// Telegram lets bots send purchasable "gifts" (Telegram Stars-priced items
// that show up on a user's or channel's profile). This example covers:
//   - `getAvailableGifts` — the current catalog, with prices in Stars.
//   - `sendGift` — sending one to a user or channel.
//   - `giftPremiumSubscription` — gifting Telegram Premium instead of an item.
//   - `getUserGifts` / `getChatGifts` — listing gifts someone has received.
//   - `convertGiftToStars` — cashing in a received gift for its Star value
//     (only for gifts owned by a connected Business Account).
//
// Sending gifts costs real Telegram Stars from the bot's balance — test
// carefully.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/33_gifts.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final userId = update.userId;
    if (chatId == null || text == null || userId == null) continue;

    if (text == '/catalog') {
      final catalog = await bot.getAvailableGifts();
      final gifts = catalog['gifts'] as List;
      final lines = gifts.take(5).map((g) {
        final gift = g as Map<String, dynamic>;
        return '${gift['emoji']} — ${gift['star_count']} Stars';
      });
      await bot.sendMessage(
        chatId,
        'A few available gifts:\n${lines.join('\n')}',
      );
    } else if (text.startsWith('/gift ')) {
      final giftId = text.substring('/gift '.length).trim();
      await bot.sendGift(
        giftId,
        userId: userId,
        text: 'Thanks for trying ptgb!',
      );
      await bot.sendMessage(chatId, 'Gift sent!');
    } else if (text == '/gift_premium') {
      // Gifts 1 month of Telegram Premium for 1000 Stars (adjust to a real
      // current price before using this for real).
      await bot.giftPremiumSubscription(
        userId,
        1,
        1000,
        text: 'Enjoy Premium!',
      );
    } else if (text == '/my_gifts') {
      final owned = await bot.getUserGifts(userId, limit: 5);
      final gifts = owned['gifts'] as List;
      await bot.sendMessage(
        chatId,
        gifts.isEmpty
            ? 'No gifts received yet.'
            : 'You have ${gifts.length} gift(s).',
      );
    } else {
      await bot.sendMessage(
        chatId,
        'Try /catalog, /gift <gift_id>, /gift_premium, or /my_gifts.',
      );
    }
  }
}
