// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 27 — CHAT PERMISSIONS AND ADMIN PROMOTION
// ============================================================================
//
// `07_chat_and_forum_admin.dart` covers muting a single member with a
// shorthand. This example goes one level deeper:
//   - `ChatPermissions` — the full set of member permissions, used both as
//     the group's default permissions (`setChatPermissions`) and per-member
//     restrictions (`restrictChatMember`).
//   - `promoteChatMember` — granting a member specific admin privileges.
//   - `setChatAdministratorCustomTitle` — a custom label shown instead of
//     "Admin" for a promoted member.
//
// The bot needs to be an admin with the relevant rights in the target chat
// for any of this to work.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/27_chat_permissions_and_promotion.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final userId = update.userId;
    if (chatId == null || text == null || userId == null) continue;

    if (text == '/lockdown') {
      // Sets the *default* permissions for every non-admin member of the
      // chat — e.g. a "slow mode"-style lockdown where only plain text is
      // allowed and nobody can invite new users.
      await bot.setChatPermissions(
        chatId,
        const ChatPermissions(
          canSendMessages: true,
          canSendPhotos: false,
          canSendVideos: false,
          canSendOtherMessages: false,
          canInviteUsers: false,
          canPinMessages: false,
        ),
      );
      await bot.sendMessage(chatId, 'Lockdown mode: text only, no invites.');
    } else if (text == '/restrict_me') {
      // Restricting an *individual* member overrides the chat's defaults
      // for just that person, optionally until a given Unix timestamp.
      await bot.restrictChatMember(
        chatId,
        userId,
        const ChatPermissions(canSendMessages: false),
        untilDate: DateTime.now()
                .add(const Duration(minutes: 10))
                .millisecondsSinceEpoch ~/
            1000,
      );
      await bot.sendMessage(chatId, 'Muted for 10 minutes.');
    } else if (text == '/make_moderator') {
      // Grants a specific subset of admin privileges — this member can
      // delete messages and restrict others, but can't touch chat settings
      // or promote further admins.
      await bot.promoteChatMember(
        chatId,
        userId,
        canDeleteMessages: true,
        canRestrictMembers: true,
        canPinMessages: true,
      );
      // A custom title shown next to their name instead of the default "Admin".
      await bot.setChatAdministratorCustomTitle(chatId, userId, 'Moderator');
      await bot.sendMessage(chatId, 'You are now a Moderator.');
    } else {
      await bot.sendMessage(
        chatId,
        'Try /lockdown, /restrict_me, or /make_moderator.',
      );
    }
  }
}
