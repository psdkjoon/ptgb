// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 08 — INLINE MODE
// ============================================================================
//
// "Inline mode" lets any Telegram user type `@yourbot <query>` in ANY chat
// (not just a chat with your bot) and get a list of results to pick from,
// without leaving that chat. You must first enable inline mode for your
// bot via @BotFather (/setinline).
//
// `ptgb` represents inline query results as typed `InlineQueryResult*`
// classes (one per result shape) rather than raw JSON — see
// `example/41_inline_query_result_gallery.dart` for one of every type.
//
// HOW TO RUN:
//   1. Enable inline mode for your bot via @BotFather.
//   2. dart run example/08_inline_queries.dart   (with a `.env` file)
//   3. In any chat, type "@your_bot_username hello"
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final query = update.inlineQuery;
    if (query == null) continue;

    final searchText = query.query.trim();

    // Build a few results based on what the user typed, mixing more than
    // one result type. Each result needs a unique `id` within this answer.
    final results = <InlineQueryResult>[
      // A plain text article — the most common result type.
      InlineQueryResultArticle(id: '1', title: 'Echo: $searchText', inputMessageContent: InputTextMessageContent(messageText: 'You searched for: $searchText'), description: 'Sends the query text back as a message'),
      InlineQueryResultArticle(id: '2', title: 'Shout it', inputMessageContent: InputTextMessageContent(messageText: '${searchText.toUpperCase()}!!!'), description: 'Sends the query text, but louder'),
      // A photo result fetched by URL, with its own caption.
      InlineQueryResultPhoto(id: '3', photoUrl: 'https://picsum.photos/seed/$searchText/600', thumbnailUrl: 'https://picsum.photos/seed/$searchText/100', title: 'A random photo', caption: 'Seeded from: $searchText'),
      // A location result — tapping it sends a static point on the map.
      InlineQueryResultLocation(id: '4', latitude: 51.5074, longitude: -0.1278, title: 'London (just an example location)'),
    ];

    await bot.answerInlineQuery(inlineQueryId: query.id, results: results, cacheTime: 0);
  }
}
