// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 03 — INLINE AND REPLY KEYBOARDS
// ============================================================================
//
// Telegram bots aren't limited to text — you can attach buttons to your
// messages. This example covers both keyboard types:
//   - InlineKeyboardMarkup: buttons attached directly under a message,
//     which trigger a "callback query" instead of sending a chat message.
//   - ReplyKeyboardMarkup: buttons that replace the user's device keyboard
//     and send plain text when tapped.
//
// HOW TO RUN:
//   dart run example/03_keyboards.dart   (with a `.env` file, see example 02)
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    // --- Handling button presses from an inline keyboard -------------------
    // When a user taps an InlineKeyboardButton with `callbackData` set,
    // Telegram sends a "callback query" update instead of a normal message.
    final callback = update.callbackQuery;
    if (callback != null) {
      final data = update.callbackData; // the button's callbackData string
      final chatId = update.chatId;

      // You should ALWAYS answer callback queries, even with no arguments —
      // otherwise Telegram keeps showing a loading spinner on the button.
      await bot.answerCallbackQuery(
        callback['id'] as String,
        text: 'You picked: $data', // shown as a small popup toast
      );

      if (chatId != null) {
        await bot.sendMessage(chatId, 'Inline button pressed: $data');
      }
      continue;
    }

    final text = update.text;
    final chatId = update.chatId;
    if (text == null || chatId == null) continue;

    if (text == '/inline') {
      // An inline keyboard: 2 buttons on the first row, 1 on the second.
      await bot.sendMessage(
        chatId,
        'Pick a color:',
        replyMarkup: InlineKeyboardMarkup([
          [
            InlineKeyboardButton.callback('🔴 Red', 'color:red'),
            InlineKeyboardButton.callback('🔵 Blue', 'color:blue'),
          ],
          [
            InlineKeyboardButton.url(
              '📖 Telegram Bot API docs',
              'https://core.telegram.org/bots/api',
            ),
          ],
        ]),
      );
    } else if (text == '/keyboard') {
      // A reply keyboard: replaces the user's device keyboard with buttons.
      // Tapping a button sends its label as a normal text message.
      await bot.sendMessage(
        chatId,
        'Choose an option below:',
        replyMarkup: ReplyKeyboardMarkup(
          [
            [KeyboardButton('Option A'), KeyboardButton('Option B')],
            [KeyboardButton('📍 Share my location', requestLocation: true)],
          ],
          resizeKeyboard: true, // shrink the keyboard to fit its buttons
          oneTimeKeyboard: true, // hide it again after one use
        ),
      );
    } else if (text == '/remove') {
      // Hide the custom keyboard and go back to the device's default one.
      await bot.sendMessage(
        chatId,
        'Keyboard removed.',
        replyMarkup: ReplyKeyboardRemove(),
      );
    } else {
      await bot.sendMessage(
        chatId,
        'Try /inline or /keyboard to see the two keyboard types in action.',
      );
    }
  }
}
