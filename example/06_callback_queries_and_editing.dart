// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 06 — CALLBACK QUERIES AND LIVE-EDITING MESSAGES
// ============================================================================
//
// This example builds a tiny interactive counter: a message with +/- inline
// buttons that edits itself in place every time a button is tapped, instead
// of sending a new message each time.
//
// HOW TO RUN:
//   dart run example/06_callback_queries_and_editing.dart   (with a `.env` file)
// ============================================================================

import 'package:ptgb/ptgb.dart';

// A tiny in-memory store mapping "chatId:messageId" -> current count.
// In a real bot you'd likely persist this in a database instead.
final Map<String, int> _counters = {};

InlineKeyboardMarkup _counterKeyboard() => InlineKeyboardMarkup.single([
      InlineKeyboardButton.callback('➖', 'counter:dec'),
      InlineKeyboardButton.callback('🔄', 'counter:reset'),
      InlineKeyboardButton.callback('➕', 'counter:inc'),
    ]);

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final callback = update.callbackQuery;

    if (callback != null) {
      final data = update.callbackData;
      final messageId = (callback['message'] as Map)['message_id'] as int;
      final chatId = update.chatId!;
      final key = '$chatId:$messageId';

      // Update our local counter based on which button was tapped.
      final current = _counters[key] ?? 0;
      final next = switch (data) {
        'counter:inc' => current + 1,
        'counter:dec' => current - 1,
        'counter:reset' => 0,
        _ => current,
      };
      _counters[key] = next;

      // Acknowledge the tap immediately so Telegram stops the loading spinner.
      await bot.answerCallbackQuery(callback['id'] as String);

      // Edit the ORIGINAL message in place instead of sending a new one —
      // this is what makes counters, paginated menus, and live dashboards
      // feel responsive rather than spammy.
      await bot.editMessageText(
        'Count: $next',
        chatId: chatId,
        messageId: messageId,
        replyMarkup: _counterKeyboard(),
      );
      continue;
    }

    final text = update.text;
    final chatId = update.chatId;
    if (text == '/counter' && chatId != null) {
      final sent = await bot.sendMessage(
        chatId,
        'Count: 0',
        replyMarkup: _counterKeyboard(),
      );
      _counters['$chatId:${sent['message_id']}'] = 0;
    } else if (text != null && chatId != null) {
      await bot.sendMessage(
        chatId,
        'Send /counter to try a live-editing message.',
      );
    }
  }
}
