// A complete, deployable bot: flashcard study using a simple spaced-
// repetition schedule (a lightweight SM-2-style approach: cards you know
// well come back less often, cards you struggle with come back sooner).
//
// Usage:
//   /addcard question | answer   — add a card
//   /study                       — review whichever card is due soonest
//   (then tap Again / Good / Easy on the card you're shown)

import 'dart:convert';

import 'package:ptgb/ptgb.dart';

class _Card {
  _Card(this.question, this.answer, this.intervalDays, this.dueAt);
  final String question;
  final String answer;
  int intervalDays;
  DateTime dueAt;

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        'intervalDays': intervalDays,
        'dueAt': dueAt.toIso8601String(),
      };

  static _Card fromJson(Map<String, dynamic> j) => _Card(
        j['question'] as String,
        j['answer'] as String,
        j['intervalDays'] as int,
        DateTime.parse(j['dueAt'] as String),
      );
}

Future<List<_Card>> _getCards(BotStorage storage, int userId) async {
  final raw = storage.getUserData(userId: userId, key: 'cards') as String?;
  if (raw == null) return [];
  return (jsonDecode(raw) as List).map((j) => _Card.fromJson(j as Map<String, dynamic>)).toList();
}

Future<void> _saveCards(BotStorage storage, int userId, List<_Card> cards) => storage.setUserData(
      userId: userId,
      key: 'cards',
      value: jsonEncode(cards.map((c) => c.toJson()).toList()),
    );

InlineKeyboardMarkup _gradeKeyboard(int cardIndex) => InlineKeyboardMarkup(rows: [
      [
        InlineKeyboardButton.callback(text: '😩 Again', data: 'grade:$cardIndex:again'),
        InlineKeyboardButton.callback(text: '🙂 Good', data: 'grade:$cardIndex:good'),
        InlineKeyboardButton.callback(text: '😎 Easy', data: 'grade:$cardIndex:easy'),
      ],
    ],);

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'flashcards_data.json');
  await storage.load();

  await bot.setMyCommands(commands: [
    {'command': 'addcard', 'description': 'Add a card: question | answer'},
    {'command': 'study', 'description': 'Review your next due card'},
  ],);

  print('Flashcard bot running.');

  await for (final update in bot.poll()) {
    final user = update.from;
    final chatId = update.chatId;
    final text = update.text;
    final callback = update.callbackQuery;
    if (user == null || chatId == null) continue;
    await storage.saveUser(user: user);

    if (text != null && text.startsWith('/addcard ')) {
      final body = text.substring('/addcard '.length);
      final parts = body.split('|');
      if (parts.length != 2) {
        await bot.sendMessage(chatId: chatId, text: 'Format: /addcard question | answer');
        continue;
      }
      final cards = await _getCards(storage, user.id);
      cards.add(_Card(parts[0].trim(), parts[1].trim(), 1, DateTime.now()));
      await _saveCards(storage, user.id, cards);
      await bot.sendMessage(chatId: chatId, text: 'Card added! You now have ${cards.length} card(s). Send /study to review.');
    } else if (text == '/study' || text == '/start') {
      final cards = await _getCards(storage, user.id);
      final dueIndex = cards.indexWhere((c) => !c.dueAt.isAfter(DateTime.now()));
      if (dueIndex == -1) {
        await bot.sendMessage(chatId: chatId, text: cards.isEmpty ? 'No cards yet — send /addcard question | answer.' : 'No cards due right now — check back later!');
        continue;
      }
      await bot.sendMessage(chatId: chatId, text: '❓ ${cards[dueIndex].question}\n\n(Think of your answer, then reveal below)');
      await bot.sendMessage(chatId: chatId, text: '💡 ${cards[dueIndex].answer}', replyMarkup: _gradeKeyboard(dueIndex));
    } else if (callback != null) {
      final data = callback.data ?? '';
      if (data.startsWith('grade:')) {
        final parts = data.substring('grade:'.length).split(':');
        final index = int.parse(parts[0]);
        final grade = parts[1];
        final cards = await _getCards(storage, user.id);
        if (index < 0 || index >= cards.length) {
          await bot.answerCallbackQuery(callbackQueryId: callback.id);
          continue;
        }
        final card = cards[index];
        card.intervalDays = switch (grade) {
          'again' => 1,
          'good' => (card.intervalDays * 2).clamp(1, 60),
          _ => (card.intervalDays * 3).clamp(1, 90), // easy
        };
        card.dueAt = DateTime.now().add(Duration(days: card.intervalDays));
        await _saveCards(storage, user.id, cards);
        await bot.answerCallbackQuery(callbackQueryId: callback.id, text: 'Next review in ${card.intervalDays} day(s).');
      }
    }
  }
}
