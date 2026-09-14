// A complete, deployable bot: shorten any URL and share it inline in any
// chat. Since ptgb doesn't include a web server framework, "shortening"
// here means generating a short code and remembering the mapping via
// [BotStorage] — clicks are tracked by counting how many times each code
// has been opened via its `/start <code>` deep link, which doubles as
// your redirect endpoint if you front this with your own HTTP server
// (see `10_webhook_server.dart` for the `dart:io` `HttpServer` pattern
// you'd extend for that).
//
// Usage: send any URL as a plain message to get back a `t.me/yourbot?start=<code>`
// deep link; opening that link (or sending `/start <code>`) counts a click
// and redirects the user with the real URL. Also works inline:
// `@yourbot https://example.com/very/long/path` shows a shareable result.

import 'dart:convert';
import 'dart:math';

import 'package:ptgb/ptgb.dart';

final _random = Random();
const _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String _generateCode() => List.generate(6, (_) => _chars[_random.nextInt(_chars.length)]).join();

bool _looksLikeUrl(String text) => RegExp(r'^https?://\S+$').hasMatch(text.trim());

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'shortener_data.json');
  await storage.load();
  final me = await bot.getMe();

  // code -> {url, clicks}, stored as a single JSON blob under a fixed key
  // (there's no per-link owner concept here, but you could key these
  // under the creator's userId via setUserData instead for a "my links"
  // feature).
  Map<String, dynamic> loadLinks() {
    final raw = storage.getChatData(chatId: 0, key: 'links') as String?;
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveLinks(Map<String, dynamic> links) =>
      storage.setChatData(chatId: 0, key: 'links', value: jsonEncode(links));

  // A dummy chat record so setChatData/getChatData (which require an
  // existing record, same as their per-user equivalents) has something to
  // attach to — see `saveChat`'s docs.
  await storage.saveChat(chat: Chat({'id': 0, 'type': 'private'}));

  await bot.setMyCommands(commands: [
    {'command': 'start', 'description': 'Open a short link (used automatically via deep links)'},
  ],);

  print('URL shortener bot running. Send any URL to shorten it.');

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final inlineQuery = update.inlineQuery;

    if (inlineQuery != null) {
      final query = inlineQuery.query.trim();
      if (!_looksLikeUrl(query)) {
        await bot.answerInlineQuery(inlineQueryId: inlineQuery.id, results: [], cacheTime: 0);
        continue;
      }
      final links = loadLinks();
      final code = _generateCode();
      links[code] = {'url': query, 'clicks': 0};
      await saveLinks(links);
      final shortLink = 'https://t.me/${me.username}?start=$code';
      await bot.answerInlineQuery(
        inlineQueryId: inlineQuery.id,
        results: [
          InlineQueryResultArticle(
            id: code,
            title: 'Shortened link',
            description: shortLink,
            inputMessageContent: InputTextMessageContent(messageText: shortLink),
          ),
        ],
        cacheTime: 0,
      );
      continue;
    }

    if (chatId == null || text == null) continue;

    if (text.startsWith('/start ')) {
      final code = text.substring('/start '.length).trim();
      final links = loadLinks();
      final entry = links[code] as Map<String, dynamic>?;
      if (entry == null) {
        await bot.sendMessage(chatId: chatId, text: 'That link doesn\'t exist or has expired.');
      } else {
        entry['clicks'] = (entry['clicks'] as int) + 1;
        await saveLinks(links);
        await bot.sendMessage(chatId: chatId, text: '🔗 ${entry['url']}\n\n(${entry['clicks']} click(s) so far)');
      }
    } else if (_looksLikeUrl(text)) {
      final links = loadLinks();
      final code = _generateCode();
      links[code] = {'url': text.trim(), 'clicks': 0};
      await saveLinks(links);
      await bot.sendMessage(chatId: chatId, text: 'Shortened: https://t.me/${me.username}?start=$code');
    } else if (text == '/start') {
      await bot.sendMessage(chatId: chatId, text: 'Send me any URL to shorten it, or try me inline: @${me.username} https://example.com');
    }
  }
}
