// A complete, deployable bot: track daily habits with streaks. Add habits,
// check them off once a day, and the bot tracks your current and longest
// streak per habit — all persisted via [BotStorage].
//
// Usage:
//   /add Drink water     — start tracking a new habit
//   /done Drink water    — mark it done for today (once per day)
//   /habits              — see all habits with current streaks
//   /remove Drink water  — stop tracking a habit

import 'dart:convert';

import 'package:ptgb/ptgb.dart';

class _Habit {
  _Habit(this.name, this.currentStreak, this.longestStreak, this.lastDone);
  final String name;
  int currentStreak;
  int longestStreak;
  String? lastDone; // ISO date string (yyyy-mm-dd), or null if never done

  Map<String, dynamic> toJson() => {
        'name': name,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastDone': lastDone,
      };

  static _Habit fromJson(Map<String, dynamic> j) => _Habit(
        j['name'] as String,
        j['currentStreak'] as int,
        j['longestStreak'] as int,
        j['lastDone'] as String?,
      );
}

String _today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);

String _yesterday() => DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

Future<List<_Habit>> _getHabits(BotStorage storage, int userId) async {
  final raw = storage.getUserData(userId: userId, key: 'habits') as String?;
  if (raw == null) return [];
  return (jsonDecode(raw) as List).map((j) => _Habit.fromJson(j as Map<String, dynamic>)).toList();
}

Future<void> _saveHabits(BotStorage storage, int userId, List<_Habit> habits) => storage.setUserData(
      userId: userId,
      key: 'habits',
      value: jsonEncode(habits.map((h) => h.toJson()).toList()),
    );

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'habits_data.json');
  await storage.load();

  await bot.setMyCommands(commands: [
    {'command': 'add', 'description': 'Add a habit, e.g. /add Drink water'},
    {'command': 'done', 'description': 'Mark a habit done for today'},
    {'command': 'habits', 'description': 'Show all habits and streaks'},
    {'command': 'remove', 'description': 'Stop tracking a habit'},
  ],);

  print('Habit tracker bot running.');

  await for (final update in bot.poll()) {
    final user = update.from;
    final chatId = update.chatId;
    final text = update.text;
    if (user == null || chatId == null || text == null) continue;
    await storage.saveUser(user: user);

    if (text.startsWith('/add ')) {
      final name = text.substring('/add '.length).trim();
      final habits = await _getHabits(storage, user.id);
      if (habits.any((h) => h.name.toLowerCase() == name.toLowerCase())) {
        await bot.sendMessage(chatId: chatId, text: 'Already tracking "$name".');
        continue;
      }
      habits.add(_Habit(name, 0, 0, null));
      await _saveHabits(storage, user.id, habits);
      await bot.sendMessage(chatId: chatId, text: 'Now tracking "$name". Send /done $name once you\'ve done it today!');
    } else if (text.startsWith('/done ')) {
      final name = text.substring('/done '.length).trim();
      final habits = await _getHabits(storage, user.id);
      final habit = habits.where((h) => h.name.toLowerCase() == name.toLowerCase()).firstOrNull;
      if (habit == null) {
        await bot.sendMessage(chatId: chatId, text: 'You\'re not tracking "$name" — send /add $name first.');
        continue;
      }
      final today = _today();
      if (habit.lastDone == today) {
        await bot.sendMessage(chatId: chatId, text: 'Already marked "$name" done today — streak is ${habit.currentStreak}.');
        continue;
      }
      habit.currentStreak = habit.lastDone == _yesterday() ? habit.currentStreak + 1 : 1;
      habit.lastDone = today;
      if (habit.currentStreak > habit.longestStreak) habit.longestStreak = habit.currentStreak;
      await _saveHabits(storage, user.id, habits);
      await bot.sendMessage(chatId: chatId, text: '🔥 "$name" done! Current streak: ${habit.currentStreak} day(s).');
    } else if (text.startsWith('/remove ')) {
      final name = text.substring('/remove '.length).trim();
      final habits = await _getHabits(storage, user.id);
      final existed = habits.any((h) => h.name.toLowerCase() == name.toLowerCase());
      habits.removeWhere((h) => h.name.toLowerCase() == name.toLowerCase());
      await _saveHabits(storage, user.id, habits);
      await bot.sendMessage(chatId: chatId, text: existed ? 'Removed "$name".' : 'You weren\'t tracking "$name".');
    } else if (text == '/habits' || text == '/start') {
      final habits = await _getHabits(storage, user.id);
      if (habits.isEmpty) {
        await bot.sendMessage(chatId: chatId, text: 'No habits yet — send /add <name> to start one.');
        continue;
      }
      final lines = habits.map((h) {
        final active = h.lastDone == _today() || h.lastDone == _yesterday();
        final flame = active && h.currentStreak > 0 ? '🔥' : '💤';
        return '$flame ${h.name}: ${h.currentStreak} day streak (best: ${h.longestStreak})';
      });
      await bot.sendMessage(chatId: chatId, text: lines.join('\n'));
    }
  }
}
