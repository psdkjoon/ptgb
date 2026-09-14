// A complete, deployable bot: search Tenor's GIF library from inline mode
// in any chat — `@yourbot dancing cat` shows a scrollable strip of GIFs
// that can be sent without ever opening a conversation with the bot.
//
// This demonstrates the general shape of "search a third-party API and
// return results inline" bots — the same pattern works for image search,
// sticker packs, product catalogs, or any other searchable media API; only
// the request/parsing in `_searchTenor` and the `InlineQueryResult*` type
// you build from it change.
//
// Setup: get a free Tenor API key at
// https://developers.google.com/tenor/guides/quickstart, then add it to
// your `.env` file as `TENOR_API_KEY=...` alongside your `TOKEN=...` line
// (see `16_custom_env_config.dart` if you want it under a different name).

import 'dart:convert';
import 'dart:io';

import 'package:penv/penv.dart';
import 'package:ptgb/ptgb.dart';

/// One GIF result from Tenor, trimmed to what we need to build an
/// [InlineQueryResultGif].
class _TenorGif {
  _TenorGif(this.id, this.gifUrl, this.previewUrl, this.width, this.height);
  final String id;
  final String gifUrl;
  final String previewUrl;
  final int width;
  final int height;
}

Future<List<_TenorGif>> _searchTenor(String query, String apiKey) async {
  final url = Uri.parse(
    'https://tenor.googleapis.com/v2/search'
    '?q=${Uri.encodeQueryComponent(query)}'
    '&key=$apiKey&client_key=ptgb_example&limit=12&media_filter=gif',
  );
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) return [];
    final json = jsonDecode(body) as Map<String, dynamic>;
    final results = json['results'] as List;
    return results.map((r) {
      final formats = r['media_formats'] as Map<String, dynamic>;
      final gif = formats['gif'] as Map<String, dynamic>;
      final tiny = formats['tinygif'] as Map<String, dynamic>? ?? gif;
      final dims = (gif['dims'] as List).cast<int>();
      return _TenorGif(r['id'] as String, gif['url'] as String, tiny['url'] as String, dims[0], dims[1]);
    }).toList();
  } finally {
    client.close();
  }
}

void main() async {
  final bot = Bot();
  final apiKey = penvload('.env')['TENOR_API_KEY'];
  if (apiKey == null) {
    print('Add TENOR_API_KEY=... to your .env file — see the file header for how to get one.');
    return;
  }

  print('GIF search bot running. Try inline: @yourbot dancing cat');

  await for (final update in bot.poll()) {
    final inlineQuery = update.inlineQuery;
    if (inlineQuery == null) continue;

    final query = inlineQuery.query.trim();
    if (query.isEmpty) {
      await bot.answerInlineQuery(inlineQueryId: inlineQuery.id, results: [], cacheTime: 0);
      continue;
    }

    final gifs = await _searchTenor(query, apiKey);
    await bot.answerInlineQuery(
      inlineQueryId: inlineQuery.id,
      results: gifs
          .map((g) => InlineQueryResultGif(
                id: g.id,
                gifUrl: g.gifUrl,
                thumbnailUrl: g.previewUrl,
                gifWidth: g.width,
                gifHeight: g.height,
              ),)
          .toList(),
      cacheTime: 300,
    );
  }
}
