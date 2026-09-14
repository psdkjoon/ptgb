// A complete, deployable bot: classic number-guessing game, playable
// solo or as a shared per-chat game everyone in a group can compete on.
// The bot picks a number 1-100; each guess gets a "higher/lower" hint
// until someone guesses right.

import 'dart:math';

import 'package:ptgb/ptgb.dart';

final _random = Random();

class _Game {
  _Game(this.target) : guessCount = 0;
  final int target;
  int guessCount;
}

void main() async {
  final bot = Bot();

  // One active game per chat.
  final games = <int, _Game>{};

  await bot.setMyCommands(commands: [
    {'command': 'guess', 'description': 'Start a new number guessing game'},
  ],);

  print('Guessing game bot running.');

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final user = update.from;
    if (chatId == null || text == null || user == null) continue;

    if (text == '/guess' || text == '/start') {
      games[chatId] = _Game(_random.nextInt(100) + 1);
      await bot.sendMessage(chatId: chatId, text: '🎲 I\'m thinking of a number between 1 and 100. Send your guess!');
      continue;
    }

    final game = games[chatId];
    if (game == null) continue;

    final guess = int.tryParse(text.trim());
    if (guess == null) continue;

    game.guessCount++;
    if (guess == game.target) {
      games.remove(chatId);
      await bot.sendMessage(
        chatId: chatId,
        text: '🎉 ${user.firstName} got it in ${game.guessCount} guess(es)! The number was ${game.target}. Send /guess to play again.',
      );
    } else if (guess < game.target) {
      await bot.sendMessage(chatId: chatId, text: '📈 Higher than $guess.');
    } else {
      await bot.sendMessage(chatId: chatId, text: '📉 Lower than $guess.');
    }
  }
}
