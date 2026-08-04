// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 26 — CONTACTS AND CHAT ACTIONS
// ============================================================================
//
// This example shows:
//   - `sendContact` — sharing a phone contact card.
//   - `sendChatAction` — the "typing...", "sending photo...", etc status
//     indicator, useful to show while your bot is doing slow work (calling
//     a third-party API, generating an image, ...) before it replies.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/26_contacts_and_chat_actions.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text == '/contact') {
      await bot.sendContact(chatId, '+1234567890', 'Support', lastName: 'Team');
    } else if (text == '/slow') {
      // Chat actions expire after ~5 seconds, so for genuinely slow work,
      // send it again periodically (e.g. every 4 seconds) until you're
      // ready to reply — a single call is enough for short delays like this.
      await bot.sendChatAction(chatId, ChatAction.typing);
      await Future<void>.delayed(const Duration(seconds: 3));
      await bot.sendMessage(chatId, 'Done thinking!');
    } else if (text == '/generating') {
      // Different actions fit different kinds of work — pick the one that
      // matches what you're about to send, so the status makes sense.
      await bot.sendChatAction(chatId, ChatAction.uploadPhoto);
      await Future<void>.delayed(const Duration(seconds: 2));
      await bot.sendPhoto(chatId, InputFile.url('https://picsum.photos/400'));
    } else {
      await bot.sendMessage(chatId, 'Try /contact, /slow, or /generating.');
    }
  }
}
