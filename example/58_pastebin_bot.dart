// A complete, deployable bot: paste a code/text snippet, get back a short
// reference you (or anyone) can share inline in any chat to post the full
// snippet, formatted as a code block. Snippets persist via [BotStorage].
//
// Usage:
//   Send any message starting with ``` to save it as a snippet (the same
//   ``` fence you'd use in Markdown), e.g.:
//     ```dart
//     void main() => print('hi');
//     ```
//   The bot replies with a short code. Then anywhere, type
//   `@yourbot <code>` to share that snippet inline.

import 'package:ptgb/ptgb.dart';

String _shortCode(int n) => n.toRadixString(36);

/// Extracts the language tag (if any) and body from a ```lang\nbody\n``` block.
({String? language, String body})? _parseSnippet(String text) {
  final match = RegExp(r'^```(\w*)\n(.*)\n```$', dotAll: true).firstMatch(text.trim());
  if (match == null) return null;
  final lang = match.group(1);
  return (language: lang?.isEmpty ?? true ? null : lang, body: match.group(2)!);
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'pastes_data.json');
  await storage.load();
  await storage.saveChat(chat: Chat({'id': 0, 'type': 'private'}));
  final me = await bot.getMe();

  var nextId = (storage.getChatData(chatId: 0, key: 'next_id') as int?) ?? 1;

  Future<void> savePaste(String code, String language, String body) async {
    await storage.setChatData(chatId: 0, key: 'paste:$code', value: '$language\n$body');
    nextId++;
    await storage.setChatData(chatId: 0, key: 'next_id', value: nextId);
  }

  ({String language, String body})? loadPaste(String code) {
    final raw = storage.getChatData(chatId: 0, key: 'paste:$code') as String?;
    if (raw == null) return null;
    final newlineIndex = raw.indexOf('\n');
    return (language: raw.substring(0, newlineIndex), body: raw.substring(newlineIndex + 1));
  }

  print('Pastebin bot running.');

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final inlineQuery = update.inlineQuery;

    if (inlineQuery != null) {
      final code = inlineQuery.query.trim();
      final paste = loadPaste(code);
      if (paste == null) {
        await bot.answerInlineQuery(inlineQueryId: inlineQuery.id, results: [], cacheTime: 0);
        continue;
      }
      final formatted = '```${paste.language}\n${paste.body}\n```';
      await bot.answerInlineQuery(
        inlineQueryId: inlineQuery.id,
        results: [
          InlineQueryResultArticle(
            id: code,
            title: 'Snippet $code${paste.language.isNotEmpty ? ' (${paste.language})' : ''}',
            description: paste.body.split('\n').first,
            inputMessageContent: InputTextMessageContent(messageText: formatted, parseMode: ParseMode.markdown),
          ),
        ],
        cacheTime: 300,
      );
      continue;
    }

    if (chatId == null || text == null) continue;

    if (text.startsWith('```')) {
      final parsed = _parseSnippet(text);
      if (parsed == null) {
        await bot.sendMessage(chatId: chatId, text: 'Couldn\'t parse that — make sure it\'s a ```-fenced block, opening and closing on their own lines.');
        continue;
      }
      final code = _shortCode(nextId);
      await savePaste(code, parsed.language ?? '', parsed.body);
      await bot.sendMessage(
        chatId: chatId,
        text: 'Saved! Share it inline: @${me.username} $code',
      );
    } else if (text == '/start') {
      await bot.sendMessage(
        chatId: chatId,
        text: 'Send a ```code block``` to save a snippet, then share it inline anywhere with @${me.username} <code>.',
      );
    }
  }
}
