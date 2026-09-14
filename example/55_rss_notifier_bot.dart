// A complete, deployable bot: subscribes chats to an RSS feed and posts
// new entries as they appear. Polls the feed every 5 minutes alongside
// listening for Telegram updates (using [Bot.poll]'s stream and a
// separate [Timer.periodic] side by side — a common pattern any time a
// bot needs to react to something other than incoming messages).
//
// Usage: /subscribe in any chat to start receiving new posts from the
// feed configured below; /unsubscribe to stop. Already-seen entries
// (by link) are remembered via [BotStorage] so a restart doesn't
// re-announce the whole feed.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ptgb/ptgb.dart';

// Swap this for any RSS feed URL you want to watch.
const _feedUrl = 'https://news.ycombinator.com/rss';

Future<List<({String title, String link})>> _fetchFeedItems(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    final items = <({String title, String link})>[];
    // Minimal, dependency-free RSS parsing: RSS <item> blocks contain
    // <title> and <link> — good enough for most feeds without pulling in
    // a full XML package. Swap for package:xml if you need robustness
    // against CDATA sections, namespaces, or malformed feeds.
    final itemPattern = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final titlePattern = RegExp(r'<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>', dotAll: true);
    final linkPattern = RegExp(r'<link>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</link>', dotAll: true);
    for (final itemMatch in itemPattern.allMatches(body)) {
      final block = itemMatch.group(1)!;
      final title = titlePattern.firstMatch(block)?.group(1)?.trim();
      final link = linkPattern.firstMatch(block)?.group(1)?.trim();
      if (title != null && link != null) items.add((title: title, link: link));
    }
    return items;
  } finally {
    client.close();
  }
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'feed_data.json');
  await storage.load();
  await storage.saveChat(chat: Chat({'id': 0, 'type': 'private'}));

  Future<Set<String>> loadSeenLinks() async {
    final raw = storage.getChatData(chatId: 0, key: 'seen_links') as String?;
    return raw == null ? {} : (jsonDecode(raw) as List).cast<String>().toSet();
  }

  Future<void> saveSeenLinks(Set<String> links) =>
      storage.setChatData(chatId: 0, key: 'seen_links', value: jsonEncode(links.toList()));

  Future<Set<int>> loadSubscribers() async {
    final raw = storage.getChatData(chatId: 0, key: 'subscribers') as String?;
    return raw == null ? {} : (jsonDecode(raw) as List).cast<int>().toSet();
  }

  Future<void> saveSubscribers(Set<int> subs) =>
      storage.setChatData(chatId: 0, key: 'subscribers', value: jsonEncode(subs.toList()));

  Future<void> checkFeed() async {
    final items = await _fetchFeedItems(_feedUrl);
    final seen = await loadSeenLinks();
    final newItems = items.where((i) => !seen.contains(i.link)).toList();
    if (newItems.isEmpty) return;

    final subscribers = await loadSubscribers();
    for (final item in newItems.reversed) {
      // Oldest-first so subscribers see them in publish order.
      for (final chatId in subscribers) {
        await bot.sendMessage(chatId: chatId, text: '📰 ${item.title}\n${item.link}');
      }
      seen.add(item.link);
    }
    await saveSeenLinks(seen);
  }

  // Seed "seen" on first run so subscribers don't get flooded with the
  // entire feed's back-catalog the moment they subscribe.
  if ((await loadSeenLinks()).isEmpty) {
    final initial = await _fetchFeedItems(_feedUrl);
    await saveSeenLinks(initial.map((i) => i.link).toSet());
  }

  Timer.periodic(const Duration(minutes: 5), (_) => checkFeed());

  await bot.setMyCommands(commands: [
    {'command': 'subscribe', 'description': 'Get notified about new feed posts'},
    {'command': 'unsubscribe', 'description': 'Stop notifications'},
  ],);

  print('Feed notifier bot running, watching $_feedUrl.');

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text == '/subscribe' || text == '/start') {
      final subs = await loadSubscribers();
      subs.add(chatId);
      await saveSubscribers(subs);
      await bot.sendMessage(chatId: chatId, text: 'Subscribed! You\'ll get new posts as they appear (checked every 5 minutes).');
    } else if (text == '/unsubscribe') {
      final subs = await loadSubscribers();
      subs.remove(chatId);
      await saveSubscribers(subs);
      await bot.sendMessage(chatId: chatId, text: 'Unsubscribed.');
    }
  }
}
