// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 23 — ADVANCED MESSAGE REACTIONS
// ============================================================================
//
// `05_polls_dice_reactions.dart` shows a single emoji reaction in passing.
// This example goes deeper into `setMessageReaction` and its `ReactionType`
// variants, plus removing reactions:
//   - `ReactionType.emoji(...)` — a standard emoji reaction.
//   - `ReactionType.customEmoji(...)` — a reaction using a custom emoji
//     sticker (requires the custom emoji's sticker ID).
//   - `ReactionType.paid()` — a Telegram Stars reaction.
//   - Setting multiple reactions at once (where the chat allows it).
//   - `deleteMessageReaction` / `deleteAllMessageReactions` to clear them.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/23_advanced_reactions.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    // React to whichever message the command was sent as a reply to; if it
    // wasn't a reply, fall back to reacting to the command message itself.
    final messageId =
        update.replyToMessage?['message_id'] as int? ?? update.messageId;
    if (messageId == null) continue;

    switch (text) {
      case '/react':
        // A single standard-emoji reaction.
        await bot.setMessageReaction(
          chatId,
          messageId,
          reaction: [ReactionType.emoji('🔥')],
        );

      case '/react_big':
        // `isBig: true` plays the large "burst" animation some emoji have.
        await bot.setMessageReaction(
          chatId,
          messageId,
          reaction: [ReactionType.emoji('🎉')],
          isBig: true,
        );

      case '/react_many':
        // Some chats (channels with the right permissions) allow more than
        // one reaction on the same message from the same "reactor".
        await bot.setMessageReaction(
          chatId,
          messageId,
          reaction: [ReactionType.emoji('👍'), ReactionType.emoji('❤')],
        );

      case '/react_paid':
        // A Telegram Stars reaction — visually distinct from emoji
        // reactions, and (unlike them) irreversible once sent.
        await bot.setMessageReaction(
          chatId,
          messageId,
          reaction: [ReactionType.paid()],
        );

      case '/unreact':
        // Passing an empty (or omitted) `reaction` list clears the bot's
        // own reaction from the message.
        await bot.setMessageReaction(chatId, messageId, reaction: []);

      case '/clear_all_reactions':
        // Requires the bot to be an admin with rights over the chat: wipes
        // *everyone's* reactions off the message, not just the bot's own.
        await bot.deleteAllMessageReactions(chatId, messageId);

      default:
        await bot.sendMessage(
          chatId,
          'Try /react, /react_big, /react_many, /react_paid, /unreact, or /clear_all_reactions '
          '(send as a reply to the message you want reacted to).',
        );
    }
  }
}
