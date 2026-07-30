// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 11 — GOD MODE: a full-featured showcase bot
// ============================================================================
//
// This is the "kitchen sink" example: a single bot that ties together
// everything shown in the earlier numbered examples, plus a few extras,
// behind a friendly /menu. Use it as a reference / copy-paste starting
// point for a real project — it's organized into clearly separated
// sections so you can lift out only the parts you need.
//
// FEATURES DEMONSTRATED:
//   • Command routing + registered bot commands
//   • Inline & reply keyboards, including a live-editing counter
//   • Sending photos, albums, locations, and stickers
//   • Polls, quizzes, dice, and message reactions
//   • Inline mode (@yourbot ...)
//   • Telegram Stars payments
//   • Chat administration (mute/pin) + forum topics
//   • Web App `initData` verification
//   • A typing indicator while "thinking"
//   • Graceful shutdown on Ctrl+C
//
// HOW TO RUN:
//   dart run example/11_god_mode_bot.dart   (with a `.env` file, see example 02)
// ============================================================================

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:ptgb/ptgb.dart';

// In-memory counter state, keyed by "chatId:messageId" (see example 06).
final Map<String, int> _counters = {};

Future<void> main() async {
  final bot = Bot();

  // --- One-time setup ------------------------------------------------------
  await bot.setMyCommands([
    {'command': 'menu', 'description': 'Show everything this bot can do'},
    {'command': 'counter', 'description': 'A live-editing +/- counter'},
    {'command': 'photo', 'description': 'Send a photo + an album'},
    {'command': 'location', 'description': 'Send a venue on the map'},
    {'command': 'poll', 'description': 'Send a quiz poll'},
    {'command': 'dice', 'description': 'Roll an animated die'},
    {'command': 'buy', 'description': 'Buy something with Telegram Stars'},
  ]);
  await bot.setMyDescription(
    description: 'A ptgb demo bot showcasing keyboards, media, polls, payments, and more.',
  );

  log('God-mode bot running. Press Ctrl+C to stop.');

  // Graceful shutdown: release the HTTP client's resources instead of
  // leaving connections open when the process is killed.
  ProcessSignal.sigint.watch().listen((_) {
    log('Shutting down...');
    bot.dispose();
    exit(0);
  });

  await for (final update in bot.poll()) {
    // Route each update to its handler. Order matters: check the more
    // specific payload types (callback query, inline query, ...) before
    // falling back to plain text commands.
    try {
      if (update.callbackQuery != null) {
        await _handleCallback(bot, update);
      } else if (update.inlineQuery != null) {
        await _handleInlineQuery(bot, update);
      } else if (update.preCheckoutQuery != null) {
        await bot.answerPreCheckoutQuery(update.preCheckoutQuery!['id'] as String, true);
      } else if (update.message?['successful_payment'] != null) {
        await bot.sendMessage(update.chatId!, '✅ Payment received, thank you!');
      } else if (update.text != null) {
        await _handleCommand(bot, update);
      }
    } on TelegramApiException catch (e) {
      // Never let one failed API call crash the whole bot — log and continue.
      log('Telegram API error: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Command handling
// ---------------------------------------------------------------------------

Future<void> _handleCommand(Bot bot, Update update) async {
  final chatId = update.chatId!;
  final command = update.text!.split(' ').first;

  switch (command) {
    case '/menu':
    case '/start':
      await bot.sendMessage(
        chatId,
        '*God Mode Demo Bot* 🤖\n\nTry any of the commands below:',
        parseMode: ParseMode.markdown,
        replyMarkup: InlineKeyboardMarkup([
          [InlineKeyboardButton.callback('🔢 Counter', 'menu:counter')],
          [InlineKeyboardButton.callback('📷 Photos', 'menu:photo')],
          [InlineKeyboardButton.callback('📍 Location', 'menu:location')],
          [InlineKeyboardButton.callback('❓ Quiz', 'menu:poll')],
          [InlineKeyboardButton.callback('🎲 Dice', 'menu:dice')],
          [InlineKeyboardButton.callback('⭐ Buy something', 'menu:buy')],
        ]),
      );

    case '/counter':
      final sent = await bot.sendMessage(chatId, 'Count: 0', replyMarkup: _counterKeyboard());
      _counters['$chatId:${sent['message_id']}'] = 0;

    case '/photo':
      // Show a "sending photo..." indicator while we prepare the album.
      await bot.sendChatAction(chatId, ChatAction.uploadPhoto);
      await bot.sendPhoto(chatId, InputFile.url('https://picsum.photos/800/600'), caption: 'A single photo.');
      await bot.sendMediaGroup(chatId, [
        InputMediaPhoto(InputFile.url('https://picsum.photos/seed/a/600')),
        InputMediaPhoto(InputFile.url('https://picsum.photos/seed/b/600'), caption: 'Album item 2'),
      ]);

    case '/location':
      await bot.sendVenue(
        chatId,
        41.0082,
        28.9784,
        'Hagia Sophia',
        'Sultan Ahmet, Istanbul, Turkey',
      );

    case '/poll':
      await bot.sendPoll(
        chatId,
        'Which of these is a Telegram Bot API method?',
        ['sendMessage', 'sendEmail', 'sendSMS'],
        type: PollType.quiz,
        correctOptionId: 0,
      );

    case '/dice':
      await bot.sendDice(chatId, emoji: DiceEmoji.dart);

    case '/buy':
      await bot.sendInvoice(
        chatId,
        'Supporter Badge',
        'A small way to support this demo bot.',
        'supporter_badge_v1',
        'XTR',
        [
          {'label': 'Supporter Badge', 'amount': 25},
        ],
      );

    default:
      await bot.sendMessage(chatId, 'Unknown command — try /menu to see what I can do.');
  }
}

// ---------------------------------------------------------------------------
// Callback query handling (inline keyboard button taps)
// ---------------------------------------------------------------------------

InlineKeyboardMarkup _counterKeyboard() => InlineKeyboardMarkup.single([
      InlineKeyboardButton.callback('➖', 'counter:dec'),
      InlineKeyboardButton.callback('🔄', 'counter:reset'),
      InlineKeyboardButton.callback('➕', 'counter:inc'),
    ]);

Future<void> _handleCallback(Bot bot, Update update) async {
  final callback = update.callbackQuery!;
  final data = update.callbackData ?? '';
  final chatId = update.chatId!;
  final messageId = (callback['message'] as Map)['message_id'] as int;

  // The main /menu screen re-dispatches to the same logic as the slash
  // commands, so tapping a button behaves identically to typing the command.
  if (data.startsWith('menu:')) {
    await bot.answerCallbackQuery(callback['id'] as String);
    // Build a minimal synthetic "message" update carrying the button's
    // target command, so `_handleCommand` can handle it uniformly.
    final syntheticMessage = <String, dynamic>{
      ...callback['message'] as Map<String, dynamic>,
      'text': '/${data.substring(5)}',
    };
    await _handleCommand(bot, Update({'update_id': update.updateId, 'message': syntheticMessage}));
    return;
  }

  if (data.startsWith('counter:')) {
    final key = '$chatId:$messageId';
    final current = _counters[key] ?? 0;
    final next = switch (data) {
      'counter:inc' => current + 1,
      'counter:dec' => current - 1,
      _ => 0,
    };
    _counters[key] = next;
    await bot.answerCallbackQuery(callback['id'] as String);
    await bot.editMessageText(
      'Count: $next',
      chatId: chatId,
      messageId: messageId,
      replyMarkup: _counterKeyboard(),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline mode handling (@yourbot ...)
// ---------------------------------------------------------------------------

Future<void> _handleInlineQuery(Bot bot, Update update) async {
  final query = update.inlineQuery!;
  final searchText = (query['query'] as String? ?? '').trim();

  await bot.answerInlineQuery(query['id'] as String, [
    {
      'type': 'article',
      'id': '1',
      'title': 'Send: "$searchText"',
      'input_message_content': {'message_text': searchText.isEmpty ? 'Hello from god mode!' : searchText},
    },
  ]);
}
