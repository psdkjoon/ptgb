// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 30 — GAMES AND HIGH SCORES
// ============================================================================
//
// Telegram Games are HTML5 games registered with @BotFather (via
// `/newgame`), then launched from a message with a "Play" button. This
// example shows the three methods around them:
//   - `sendGame` — posts the playable card for a registered game.
//   - `setGameScore` — reports a player's score after they finish playing
//     (called from your game's backend/webview, not by the player).
//   - `getGameHighScores` — fetches the leaderboard around a player.
//
// You must register a game with @BotFather first and use its short name
// below — this won't work with a made-up name.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. Set gameShortName below to a game you've registered with @BotFather.
//   3. dart run example/30_games_and_high_scores.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

const gameShortName = 'your_game_short_name';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final userId = update.userId;
    if (chatId == null || text == null || userId == null) continue;

    if (text == '/play') {
      // Posts a card with a "Play" button that opens the registered game.
      await bot.sendGame(chatId, gameShortName);
    } else if (text.startsWith('/score ')) {
      // In a real game, this would be called by your game's own server once
      // it detects the round ended — not directly from a chat command like
      // this. It's inlined here purely so the example is runnable end to end.
      final score = int.tryParse(text.substring('/score '.length)) ?? 0;
      await bot.setGameScore(userId, score, chatId: chatId);
      await bot.sendMessage(chatId, 'Recorded a score of $score.');
    } else if (text == '/leaderboard') {
      // Returns scores for the players "closest" to this one on the
      // leaderboard, not a global top-N — pass the same chat/message
      // context the game card was posted in.
      final scores = await bot.getGameHighScores(userId, chatId: chatId);
      if (scores.isEmpty) {
        await bot.sendMessage(
          chatId,
          'No scores recorded yet — try /score <number> first.',
        );
      } else {
        final lines = scores
            .map(GameHighScore.new)
            .map((s) => '${s.user.firstName}: ${s.score}');
        await bot.sendMessage(chatId, 'Leaderboard:\n${lines.join('\n')}');
      }
    } else {
      await bot.sendMessage(
        chatId,
        'Try /play, /score <number>, or /leaderboard.',
      );
    }
  }
}
