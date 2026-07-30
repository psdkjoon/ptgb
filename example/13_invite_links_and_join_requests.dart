// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 13 — INVITE LINKS AND JOIN REQUESTS
// ============================================================================
//
// A common but confusing feature: invite links that require the bot's
// approval before someone can actually join. This is different from a
// plain invite link, which lets anyone in immediately.
//
// The flow has three parts:
//   1. Create an invite link with `createsJoinRequest: true`.
//   2. When someone taps it, Telegram sends your bot a `chat_join_request`
//      update instead of letting them straight in.
//   3. Your bot calls `approveChatJoinRequest` or `declineChatJoinRequest`.
//
// Your bot needs to be an admin of the chat with the "invite users" right
// for any of this to work.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. Add this bot as an admin to a group/channel.
//   3. dart run example/13_invite_links_and_join_requests.dart
//   4. Send /invite to the bot in a private chat to get a join-request link,
//      then try joining the group through it from a different account.
// ============================================================================

import 'dart:developer';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  // Replace with the numeric ID of the group/channel you're testing with —
  // `getChat` or a bot like @userinfobot can help you find it.
  const targetChatId = -1001234567890;

  await for (final update in bot.poll()) {
    // Part 2: someone tapped a join-request link. `chatJoinRequest` is the
    // raw JSON payload Telegram sends — it includes `from` (the requester)
    // and `chat` (which chat they're trying to join).
    final joinRequest = update.chatJoinRequest;
    if (joinRequest != null) {
      final userId = joinRequest['from']['id'] as int;
      final chatId = joinRequest['chat']['id'] as int;
      final username = joinRequest['from']['username'] as String?;

      // A real bot might check an allowlist, a captcha answer, an account
      // age, etc. here before deciding. This demo just approves everyone
      // and logs it.
      await bot.approveChatJoinRequest(chatId, userId);
      log('Approved join request from ${username ?? userId}');

      // To reject instead:
      //   await bot.declineChatJoinRequest(chatId, userId);
      continue;
    }

    final text = update.text;
    final chatId = update.chatId;
    if (text == null || chatId == null) continue;

    if (text == '/invite') {
      // Part 1: create a link that funnels joiners through your bot for
      // approval instead of adding them immediately.
      final link = await bot.createChatInviteLink(
        targetChatId,
        name: 'Approved by bot',
        createsJoinRequest: true,
      );
      await bot.sendMessage(
        chatId,
        'Share this link — anyone who uses it will need my approval to join:\n'
        '${link['invite_link']}',
      );
    }
  }
}
