// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 37 — PREPARED INLINE MESSAGES AND KEYBOARD BUTTONS
// ============================================================================
//
// `08_inline_queries.dart` answers inline queries on demand, computing
// results each time. When the same result is likely to be reused a lot
// (e.g. "share this product card"), you can pre-upload it once and hand
// out a short-lived ID instead:
//   - `savePreparedInlineMessage` — pre-registers an inline query result
//     for a specific user, returning an ID good for sharing via a
//     `switch_inline_query`-style button.
//   - `savePreparedKeyboardButton` — the same idea, but for a keyboard
//     button's content rather than an inline query result.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/37_prepared_messages.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final userId = update.userId;
    if (chatId == null || text == null || userId == null) continue;

    if (text == '/prepare_share_card') {
      // The `result` shape here is the same as what you'd hand to
      // `answerInlineQuery` for a single result — see 08_inline_queries.dart.
      final prepared = await bot.savePreparedInlineMessage(
        userId,
        {
          'type': 'article',
          'id': 'share-card',
          'title': 'Check out ptgb',
          'input_message_content': {
            'message_text':
                'ptgb — a complete Dart client for the Telegram Bot API.',
          },
        },
        allowUserChats: true,
        allowGroupChats: true,
      );
      final preparedId = prepared['id'] as String;

      // Give the user a button that shares this prepared result into any
      // chat they pick, without re-running your inline-query logic.
      await bot.sendMessage(
        chatId,
        'Tap to share:',
        replyMarkup: InlineKeyboardMarkup.single([
          InlineKeyboardButton(
            text: 'Share',
            switchInlineQueryChosenChat: {
              'query': '',
              'prepared_inline_message_id': preparedId,
            },
          ),
        ]),
      );
    } else if (text == '/prepare_keyboard_button') {
      // Same idea, but for a reply-keyboard "share chat" style button
      // rather than an inline result.
      final prepared = await bot.savePreparedKeyboardButton(
        userId,
        {
          'text': 'Send feedback',
          'request_users': {'request_id': 1},
        },
      );
      await bot.sendMessage(
        chatId,
        'Prepared keyboard button: ${prepared['id']}',
      );
    } else {
      await bot.sendMessage(
        chatId,
        'Try /prepare_share_card or /prepare_keyboard_button.',
      );
    }
  }
}
