// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 21 — REPLY PARAMETERS AND QUOTING
// ============================================================================
//
// Most send methods accept a `replyParameters` argument for replying to an
// existing message. This example shows:
//   - The simple case: replying to a message in the same chat.
//   - Quoting a specific excerpt of the original message (rather than the
//     whole thing) via `ReplyParameters.quote`.
//   - Replying across chats with `ReplyParameters.chatId`.
//   - `allowSendingWithoutReply`, so the reply still sends even if the
//     original message was deleted in the meantime.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/21_reply_parameters_and_quoting.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final messageId = update.messageId;
    if (chatId == null || text == null || messageId == null) continue;

    if (text == '/reply') {
      // A plain reply: just target `messageId`. This is equivalent to the
      // older `replyToMessageId` parameter, but `ReplyParameters` is the
      // one to reach for when you also want quoting or cross-chat replies.
      await bot.sendMessage(
        chatId,
        'This is a reply to your message.',
        replyParameters: ReplyParameters(messageId),
      );
    } else if (text.startsWith('/quote ')) {
      // Quote a specific substring of the message being replied to. This
      // only makes sense when replying to a *different* message than the
      // one containing "/quote ..." itself, so here we quote the command
      // text back for demonstration purposes.
      final excerpt = text.substring('/quote '.length);
      await bot.sendMessage(
        chatId,
        'You asked me to quote: "$excerpt"',
        replyParameters: ReplyParameters(
          messageId,
          quote: excerpt,
          // If the excerpt appears more than once in the original message,
          // `quotePosition` (a character offset) disambiguates which
          // occurrence to highlight.
        ),
      );
    } else if (text == '/safe_reply') {
      // `allowSendingWithoutReply: true` means: if the message we're trying
      // to reply to has since been deleted, send this as a normal message
      // instead of throwing a `TelegramApiException`. Handy for bots that
      // reply asynchronously (e.g. after a slow API call) where the
      // original message might not survive that long.
      await bot.sendMessage(
        chatId,
        'Replying safely — this sends even if the original message is gone.',
        replyParameters:
            ReplyParameters(messageId, allowSendingWithoutReply: true),
      );
    } else {
      await bot.sendMessage(
        chatId,
        'Try /reply, /quote <text>, or /safe_reply.',
      );
    }
  }
}
