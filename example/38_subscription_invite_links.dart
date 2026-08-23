// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 38 — SUBSCRIPTION INVITE LINKS AND STAR SUBSCRIPTIONS
// ============================================================================
//
// `13_invite_links_and_join_requests.dart` covers ordinary invite links.
// This example covers the subscription variant, where joining costs a
// recurring Telegram Stars payment:
//   - `createChatSubscriptionInviteLink` — an invite link with a price and
//     billing period attached (channels only).
//   - `editChatSubscriptionInviteLink` — renaming an existing one (the
//     price/period can't be changed after creation).
//   - `editUserStarSubscription` — canceling (or reinstating) a specific
//     user's active subscription from the bot side.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/38_subscription_invite_links.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text == '/create_subscription_link') {
      // `subscriptionPeriod` is fixed at 2592000 seconds (30 days) as of
      // this writing; `subscriptionPrice` is in Telegram Stars per period.
      final link = await bot.createChatSubscriptionInviteLink(
        chatId,
        2592000,
        250,
        name: 'Monthly membership',
      );
      await bot.sendMessage(
        chatId,
        'Subscription link: ${link.inviteLink}',
      );
    } else if (text.startsWith('/rename_link ')) {
      final inviteLink = text.substring('/rename_link '.length).trim();
      await bot.editChatSubscriptionInviteLink(
        chatId,
        inviteLink,
        name: 'VIP membership',
      );
      await bot.sendMessage(chatId, 'Renamed.');
    } else if (text.startsWith('/cancel_subscription ')) {
      final parts =
          text.substring('/cancel_subscription '.length).trim().split(' ');
      final userId = int.parse(parts[0]);
      final chargeId = parts[1];
      await bot.editUserStarSubscription(userId, chargeId, true);
      await bot.sendMessage(chatId, 'Subscription canceled for user $userId.');
    } else {
      await bot.sendMessage(
        chatId,
        'Try /create_subscription_link, /rename_link <link>, or '
        '/cancel_subscription <user_id> <charge_id>.',
      );
    }
  }
}
