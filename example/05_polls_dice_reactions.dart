// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 05 — POLLS, DICE, AND REACTIONS
// ============================================================================
//
// Telegram supports a few fun, interactive message types beyond plain text:
// native polls/quizzes, animated "dice" (server-decided random results),
// and emoji reactions the bot can leave on messages.
//
// HOW TO RUN:
//   dart run example/05_polls_dice_reactions.dart   (with a `.env` file)
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final text = update.text;
    final chatId = update.chatId;

    // --- Reacting to messages -----------------------------------------------
    // If any message arrives, leave a 👍 reaction on it as a lightweight
    // acknowledgement, without sending a new message.
    final message = update.message;
    if (message != null && chatId != null) {
      await bot.setMessageReaction(
        chatId,
        message['message_id'] as int,
        reaction: [ReactionType.emoji('👍')],
      );
    }

    if (text == null || chatId == null) continue;

    if (text == '/poll') {
      // A regular poll — every option is just an opinion, none is "correct".
      await bot.sendPoll(
        chatId,
        'What\'s your favorite season?',
        ['Spring', 'Summer', 'Autumn', 'Winter'],
      );
    } else if (text == '/quiz') {
      // A quiz poll — exactly one option is correct, revealed after voting.
      await bot.sendPoll(
        chatId,
        'What language is ptgb written in?',
        ['Python', 'Dart', 'Go', 'Rust'],
        type: PollType.quiz,
        correctOptionId: 1, // zero-based index — "Dart"
      );
    } else if (text == '/dice') {
      // Telegram rolls the dice server-side and tells us the result —
      // this is provably fair, unlike generating a random number ourselves.
      final result = await bot.sendDice(chatId);
      final value = (result['dice'] as Map)['value'];
      await bot.sendMessage(chatId, 'You rolled: $value');
    } else if (text == '/basketball') {
      await bot.sendDice(chatId, emoji: DiceEmoji.basketball);
    } else {
      await bot.sendMessage(chatId, 'Try /poll, /quiz, /dice, or /basketball!');
    }
  }
}
