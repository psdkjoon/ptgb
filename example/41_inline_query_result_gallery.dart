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
      InlineQueryResultArticle(id: 'article', title: 'Article result', inputMessageContent: InputTextMessageContent(messageText: 'Sent from an InlineQueryResultArticle.'), description: 'A link-style result with a title and description', url: 'https://core.telegram.org/bots/api#inlinequeryresultarticle'),
      InlineQueryResultPhoto(id: 'photo', photoUrl: 'https://picsum.photos/seed/photo/600', thumbnailUrl: 'https://picsum.photos/seed/photo/100', title: 'Photo result', caption: 'A photo fetched by URL'),
      InlineQueryResultGif(id: 'gif', gifUrl: 'https://example.com/sample.gif', thumbnailUrl: 'https://example.com/sample_thumb.jpg', title: 'GIF result'),
      InlineQueryResultMpeg4Gif(id: 'mpeg4_gif', mpeg4Url: 'https://example.com/sample.mp4', thumbnailUrl: 'https://example.com/sample_thumb.jpg', title: 'MPEG4 GIF result'),
      InlineQueryResultVideo(
        id: 'video',
        videoUrl: 'https://example.com/sample.mp4',
        mimeType: 'video/mp4',
        thumbnailUrl: 'https://example.com/sample_thumb.jpg',
        title: 'Video result',
        // Embedded (non-MP4) videos can't be sent directly, so a `video/mp4`
        // result like this one is sent as-is — inputMessageContent is only
        // required for `text/html` video results.
        description: 'An MP4 video fetched by URL',
      ),
      InlineQueryResultAudio(id: 'audio', audioUrl: 'https://example.com/sample.mp3', title: 'Audio result', performer: 'ptgb'),
      InlineQueryResultVoice(id: 'voice', voiceUrl: 'https://example.com/sample.ogg', title: 'Voice result'),
      InlineQueryResultDocument(id: 'document', title: 'Document result', documentUrl: 'https://example.com/sample.pdf', mimeType: 'application/pdf', description: 'A PDF fetched by URL'),
      InlineQueryResultLocation(id: 'location', latitude: 51.5074, longitude: -0.1278, title: 'Location result'),
      InlineQueryResultVenue(id: 'venue', latitude: 40.7484, longitude: -73.9857, title: 'Venue result', address: '350 5th Ave, New York, NY'),
      InlineQueryResultContact(id: 'contact', phoneNumber: '+15551234567', firstName: 'Contact result'),
      InlineQueryResultGame(id: 'game', gameShortName: 'your_game_short_name'),
      InlineQueryResultSticker(id: 'sticker', stickerUrl: 'https://example.com/sample_sticker.webp'),

      // --- Cached (`file_id`-based) results -----------------------------
      // These reuse a file already on Telegram's servers — swap in a real
      // `file_id` your bot has previously received or uploaded.
      InlineQueryResultCachedPhoto(id: 'cached_photo', photoFileId: 'YOUR_PHOTO_FILE_ID'),
      InlineQueryResultCachedGif(id: 'cached_gif', gifFileId: 'YOUR_GIF_FILE_ID'),
      InlineQueryResultCachedMpeg4Gif(id: 'cached_mpeg4_gif', mpeg4FileId: 'YOUR_MPEG4_FILE_ID'),
      InlineQueryResultCachedSticker(id: 'cached_sticker', stickerFileId: 'YOUR_STICKER_FILE_ID'),
      InlineQueryResultCachedDocument(id: 'cached_document', title: 'Cached document result', documentFileId: 'YOUR_DOCUMENT_FILE_ID'),
      InlineQueryResultCachedVideo(id: 'cached_video', videoFileId: 'YOUR_VIDEO_FILE_ID', title: 'Cached video result'),
      InlineQueryResultCachedVoice(id: 'cached_voice', voiceFileId: 'YOUR_VOICE_FILE_ID', title: 'Cached voice result'),
      InlineQueryResultCachedAudio(id: 'cached_audio', audioFileId: 'YOUR_AUDIO_FILE_ID'),

      // --- Every InputMessageContent subtype, via plain articles --------
      InlineQueryResultArticle(id: 'input_text', title: 'InputTextMessageContent', inputMessageContent: InputTextMessageContent(messageText: '*Bold* text via Markdown', parseMode: ParseMode.markdownV2)),
      InlineQueryResultArticle(id: 'input_location', title: 'InputLocationMessageContent', inputMessageContent: InputLocationMessageContent(latitude: 48.8584, longitude: 2.2945)),
      InlineQueryResultArticle(id: 'input_venue', title: 'InputVenueMessageContent', inputMessageContent: InputVenueMessageContent(latitude: 48.8584, longitude: 2.2945, title: 'Eiffel Tower', address: 'Champ de Mars, 5 Av. Anatole France, Paris')),
      InlineQueryResultArticle(id: 'input_contact', title: 'InputContactMessageContent', inputMessageContent: InputContactMessageContent(phoneNumber: '+15551234567', firstName: 'ptgb')),
      InlineQueryResultArticle(id: 'input_invoice', title: 'InputInvoiceMessageContent', inputMessageContent: InputInvoiceMessageContent(title: 'Sample product', description: 'A product sent from an inline query result', payload: 'sample-payload', currency: 'XTR', prices: [
            {'label': 'Sample product', 'amount': 100},
          ],),),
    ];

    await bot.answerInlineQuery(inlineQueryId: query.id, results: results, cacheTime: 0, isPersonal: false, nextOffset: '' /* set to a real cursor if you paginate results */,
      button: {
        'text': 'About this gallery',
        'start_parameter': 'gallery_info',
      },);
  }
}
