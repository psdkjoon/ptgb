// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 24 — FORWARDING AND COPYING MESSAGES
// ============================================================================
//
// Telegram gives you two ways to relay a message somewhere else:
//   - Forward: the destination sees "Forwarded from ..." and a link back to
//     the original sender/chat. Use `forwardMessage`/`forwardMessages`.
//   - Copy: the content is resent as if the bot wrote it itself, with no
//     attribution to the original. Use `copyMessage`/`copyMessages`.
//
// Both come in single-message and batch (`...Messages`, plural) variants.
// This example relays whatever you send the bot to a second chat you
// control, once as a forward and once as a copy, so you can compare them.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. Set ARCHIVE_CHAT_ID below to a chat ID the bot can post to (e.g. a
//      private group with just you and the bot).
//   3. dart run example/24_forwarding_and_copying.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

// Replace with a real chat ID before running.
const archiveChatId = -1001234567890;

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final messageId = update.messageId;
    if (chatId == null || messageId == null) continue;

    // Forward: recipients see this came from the original chat/user.
    await bot.forwardMessage(archiveChatId, chatId, messageId);

    // Copy: recipients see this as an ordinary message from the bot, with
    // no reference to where it originally came from. `copyMessage` returns
    // just the new message's ID (as `MessageId`), not the full message.
    await bot.copyMessage(archiveChatId, chatId, messageId);

    await bot.sendMessage(
      chatId,
      'Archived your message both ways — check the archive chat.',
    );

    // Batch versions accept a list of message IDs and relay them all in one
    // call, preserving their relative order — useful for archiving an
    // entire album (media group) at once instead of one call per item:
    //   await bot.forwardMessages(archiveChatId, chatId, [101, 102, 103]);
    //   await bot.copyMessages(archiveChatId, chatId, [101, 102, 103]);
  }
}
