// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 41 — INLINE QUERY RESULT GALLERY
// ============================================================================
//
// A reference showing one of EVERY `InlineQueryResult*` subtype (including
// the `Cached*` variants that reuse a `file_id` already on Telegram's
// servers) and every `InputMessageContent*` subtype, plus the extra
// `answerInlineQuery` parameters (`cacheTime`, `isPersonal`, `nextOffset`,
// `button`). See `example/08_inline_queries.dart` for a simpler, more
// typical inline-mode bot.
//
// HOW TO RUN:
//   1. Enable inline mode for your bot via @BotFather.
//   2. dart run example/41_inline_query_result_gallery.dart
//   3. In any chat, type "@your_bot_username gallery"
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final query = update.inlineQuery;
    if (query == null) continue;

    final results = <InlineQueryResult>[
      // --- Fetched-by-URL results --------------------------------------
      InlineQueryResultArticle(
        'article',
        'Article result',
        InputTextMessageContent('Sent from an InlineQueryResultArticle.'),
        description: 'A link-style result with a title and description',
        url: 'https://core.telegram.org/bots/api#inlinequeryresultarticle',
      ),
      InlineQueryResultPhoto(
        'photo',
        'https://picsum.photos/seed/photo/600',
        'https://picsum.photos/seed/photo/100',
        title: 'Photo result',
        caption: 'A photo fetched by URL',
      ),
      InlineQueryResultGif(
        'gif',
        'https://example.com/sample.gif',
        'https://example.com/sample_thumb.jpg',
        title: 'GIF result',
      ),
      InlineQueryResultMpeg4Gif(
        'mpeg4_gif',
        'https://example.com/sample.mp4',
        'https://example.com/sample_thumb.jpg',
        title: 'MPEG4 GIF result',
      ),
      InlineQueryResultVideo(
        'video',
        'https://example.com/sample.mp4',
        'video/mp4',
        'https://example.com/sample_thumb.jpg',
        'Video result',
        // Embedded (non-MP4) videos can't be sent directly, so a `video/mp4`
        // result like this one is sent as-is — inputMessageContent is only
        // required for `text/html` video results.
        description: 'An MP4 video fetched by URL',
      ),
      InlineQueryResultAudio(
        'audio',
        'https://example.com/sample.mp3',
        'Audio result',
        performer: 'ptgb',
      ),
      InlineQueryResultVoice(
        'voice',
        'https://example.com/sample.ogg',
        'Voice result',
      ),
      InlineQueryResultDocument(
        'document',
        'Document result',
        'https://example.com/sample.pdf',
        'application/pdf',
        description: 'A PDF fetched by URL',
      ),
      InlineQueryResultLocation(
        'location',
        51.5074,
        -0.1278,
        'Location result',
      ),
      InlineQueryResultVenue(
        'venue',
        40.7484,
        -73.9857,
        'Venue result',
        '350 5th Ave, New York, NY',
      ),
      InlineQueryResultContact(
        'contact',
        '+15551234567',
        'Contact result',
      ),
      InlineQueryResultGame('game', 'your_game_short_name'),
      InlineQueryResultSticker(
        'sticker',
        'https://example.com/sample_sticker.webp',
      ),

      // --- Cached (`file_id`-based) results -----------------------------
      // These reuse a file already on Telegram's servers — swap in a real
      // `file_id` your bot has previously received or uploaded.
      InlineQueryResultCachedPhoto('cached_photo', 'YOUR_PHOTO_FILE_ID'),
      InlineQueryResultCachedGif('cached_gif', 'YOUR_GIF_FILE_ID'),
      InlineQueryResultCachedMpeg4Gif(
        'cached_mpeg4_gif',
        'YOUR_MPEG4_FILE_ID',
      ),
      InlineQueryResultCachedSticker('cached_sticker', 'YOUR_STICKER_FILE_ID'),
      InlineQueryResultCachedDocument(
        'cached_document',
        'Cached document result',
        'YOUR_DOCUMENT_FILE_ID',
      ),
      InlineQueryResultCachedVideo(
        'cached_video',
        'YOUR_VIDEO_FILE_ID',
        'Cached video result',
      ),
      InlineQueryResultCachedVoice(
        'cached_voice',
        'YOUR_VOICE_FILE_ID',
        'Cached voice result',
      ),
      InlineQueryResultCachedAudio('cached_audio', 'YOUR_AUDIO_FILE_ID'),

      // --- Every InputMessageContent subtype, via plain articles --------
      InlineQueryResultArticle(
        'input_text',
        'InputTextMessageContent',
        InputTextMessageContent(
          '*Bold* text via Markdown',
          parseMode: ParseMode.markdownV2,
        ),
      ),
      InlineQueryResultArticle(
        'input_location',
        'InputLocationMessageContent',
        InputLocationMessageContent(48.8584, 2.2945),
      ),
      InlineQueryResultArticle(
        'input_venue',
        'InputVenueMessageContent',
        InputVenueMessageContent(
          48.8584,
          2.2945,
          'Eiffel Tower',
          'Champ de Mars, 5 Av. Anatole France, Paris',
        ),
      ),
      InlineQueryResultArticle(
        'input_contact',
        'InputContactMessageContent',
        InputContactMessageContent('+15551234567', 'ptgb'),
      ),
      InlineQueryResultArticle(
        'input_invoice',
        'InputInvoiceMessageContent',
        InputInvoiceMessageContent(
          'Sample product',
          'A product sent from an inline query result',
          'sample-payload',
          'XTR',
          [
            {'label': 'Sample product', 'amount': 100},
          ],
        ),
      ),
    ];

    await bot.answerInlineQuery(
      query.id,
      results,
      cacheTime: 0,
      isPersonal: false,
      nextOffset: '', // set to a real cursor if you paginate results
      button: {
        'text': 'About this gallery',
        'start_parameter': 'gallery_info',
      },
    );
  }
}
