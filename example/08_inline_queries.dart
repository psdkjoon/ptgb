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
// Note: `ptgb` represents inline query results as raw `Json` maps (matching
// Telegram's API shape 1:1) rather than typed classes, since there are many
// result types (article, photo, gif, ...) with very different fields.
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

    final queryId = query['id'] as String;
    final searchText = (query['query'] as String? ?? '').trim();

    // Build a couple of simple text-article results based on what the
    // user typed. Each result needs a unique `id`.
    final results = <Json>[
      {
        'type': 'article',
        'id': '1',
        'title': 'Echo: $searchText',
        'input_message_content': {'message_text': 'You searched for: $searchText'},
        'description': 'Sends the query text back as a message',
      },
      {
        'type': 'article',
        'id': '2',
        'title': 'Shout it',
        'input_message_content': {'message_text': '${searchText.toUpperCase()}!!!'},
        'description': 'Sends the query text, but louder',
      },
    ];

    await bot.answerInlineQuery(queryId, results, cacheTime: 0);
  }
}
