// A complete, deployable bot: a personal todo list. Add items with plain
// text, tick them off with inline buttons, and everything persists across
// restarts via [BotStorage]'s per-user custom data.
//
// This is the pattern behind most "personal assistant" utility bots: state
// lives entirely in per-user custom data (as a JSON-encoded blob), and the
// UI is a message that gets edited in place as the list changes, instead
// of spamming a new message per action.

import 'dart:convert';

import 'package:ptgb/ptgb.dart';

class _Todo {
  _Todo(this.text, this.done);
  final String text;
  bool done;

  Map<String, dynamic> toJson() => {'text': text, 'done': done};
  static _Todo fromJson(Map<String, dynamic> j) => _Todo(j['text'] as String, j['done'] as bool);
}

Future<List<_Todo>> _getTodos(BotStorage storage, int userId) async {
  final raw = storage.getUserData(userId: userId, key: 'todos') as String?;
  if (raw == null) return [];
  return (jsonDecode(raw) as List).map((j) => _Todo.fromJson(j as Map<String, dynamic>)).toList();
}

Future<void> _saveTodos(BotStorage storage, int userId, List<_Todo> todos) => storage.setUserData(
      userId: userId,
      key: 'todos',
      value: jsonEncode(todos.map((t) => t.toJson()).toList()),
    );

InlineKeyboardMarkup _todoKeyboard(List<_Todo> todos) => InlineKeyboardMarkup(rows: [
      for (var i = 0; i < todos.length; i++)
        [
          InlineKeyboardButton.callback(
            text: '${todos[i].done ? '✅' : '⬜'} ${todos[i].text}',
            data: 'toggle:$i',
          ),
          InlineKeyboardButton.callback(text: '🗑', data: 'delete:$i'),
        ],
      if (todos.any((t) => t.done)) [InlineKeyboardButton.callback(text: 'Clear completed', data: 'clear')],
    ],);

String _listText(List<_Todo> todos) {
  if (todos.isEmpty) return 'Your list is empty. Just send a message to add an item!';
  final done = todos.where((t) => t.done).length;
  return 'Your todo list ($done/${todos.length} done):';
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'todo_data.json');
  await storage.load();

  await bot.setMyCommands(commands: [
    {'command': 'list', 'description': 'Show your todo list'},
    {'command': 'clear', 'description': 'Remove all items'},
  ],);

  print('Todo bot running.');

  await for (final update in bot.poll()) {
    final user = update.from;
    final chatId = update.chatId;
    if (user == null || chatId == null) continue;
    await storage.saveUser(user: user);

    final text = update.text;
    final callback = update.callbackQuery;

    if (callback != null) {
      final data = callback.data ?? '';
      final todos = await _getTodos(storage, user.id);
      if (data.startsWith('toggle:')) {
        final index = int.parse(data.substring('toggle:'.length));
        if (index >= 0 && index < todos.length) todos[index].done = !todos[index].done;
        await _saveTodos(storage, user.id, todos);
      } else if (data.startsWith('delete:')) {
        final index = int.parse(data.substring('delete:'.length));
        if (index >= 0 && index < todos.length) todos.removeAt(index);
        await _saveTodos(storage, user.id, todos);
      } else if (data == 'clear') {
        todos.removeWhere((t) => t.done);
        await _saveTodos(storage, user.id, todos);
      }
      await bot.answerCallbackQuery(callbackQueryId: callback.id);
      final messageId = callback.message?['message_id'] as int?;
      if (messageId != null) {
        await bot.editMessageText(
          chatId: chatId,
          messageId: messageId,
          text: _listText(todos),
          replyMarkup: todos.isEmpty ? null : _todoKeyboard(todos),
        );
      }
    } else if (text == '/list' || text == '/start') {
      final todos = await _getTodos(storage, user.id);
      await bot.sendMessage(chatId: chatId, text: _listText(todos), replyMarkup: todos.isEmpty ? null : _todoKeyboard(todos));
    } else if (text == '/clear') {
      await _saveTodos(storage, user.id, []);
      await bot.sendMessage(chatId: chatId, text: 'List cleared.');
    } else if (text != null && !text.startsWith('/')) {
      final todos = await _getTodos(storage, user.id);
      todos.add(_Todo(text, false));
      await _saveTodos(storage, user.id, todos);
      await bot.sendMessage(chatId: chatId, text: 'Added! ${_listText(todos)}', replyMarkup: _todoKeyboard(todos));
    }
  }
}
