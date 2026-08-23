// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)
// ============================================================================
// 29 — DEFAULT ADMINISTRATOR RIGHTS
// ============================================================================
//
// When someone adds your bot to a group/channel as an admin, Telegram
// pre-fills the rights checklist using whatever you've configured as the
// bot's *default* admin rights — saving the person doing the inviting from
// manually ticking every box your bot actually needs.
//
// This example sets sensible defaults for a moderation bot (message
// deletion + member restriction, nothing else) and shows how to read them
// back, separately for groups and channels via `forChannels`.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/29_default_admin_rights.dart
// ============================================================================
import 'dart:developer';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  // Groups/supergroups: this bot only needs to delete messages and
  // restrict/ban members — no need to request anything broader.
  await bot.setMyDefaultAdministratorRights(
    rights: const ChatAdministratorRights(
      canDeleteMessages: true,
      canRestrictMembers: true,
      canInviteUsers: true,
    ),
  );

  // Channels have a different rights vocabulary (posting/editing messages
  // instead of restricting members), configured separately via `forChannels`.
  await bot.setMyDefaultAdministratorRights(
    forChannels: true,
    rights: const ChatAdministratorRights(
      canPostMessages: true,
      canEditMessages: true,
      canDeleteMessages: true,
    ),
  );

  log('Default admin rights configured for groups and channels.');

  // Read them back to confirm — useful for debugging what a fresh "Add to
  // Group" flow will pre-select.
  final groupRights = await bot.getMyDefaultAdministratorRights();
  final channelRights =
      await bot.getMyDefaultAdministratorRights(forChannels: true);

  log('Group defaults: canDeleteMessages=${groupRights.canDeleteMessages}, '
      'canRestrictMembers=${groupRights.canRestrictMembers}, '
      'canInviteUsers=${groupRights.canInviteUsers}');
  log('Channel defaults: canPostMessages=${channelRights.canPostMessages}, '
      'canEditMessages=${channelRights.canEditMessages}, '
      'canDeleteMessages=${channelRights.canDeleteMessages}');
}
