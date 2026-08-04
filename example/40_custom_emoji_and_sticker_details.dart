// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 40 — CUSTOM EMOJI AND STICKER SET DETAILS
// ============================================================================
//
// `14_sticker_sets.dart` covers the multi-step flow for creating a sticker
// set. This example covers a few smaller, standalone lookups and edits
// around stickers and custom emoji:
//   - `getStickerSet` — full metadata for an existing set by name.
//   - `getCustomEmojiStickers` — resolving custom emoji IDs (as seen in
//     message entities) into full sticker info.
//   - `getForumTopicIconStickers` — the built-in icon set for forum topics.
//   - `setStickerEmojiList` / `setStickerKeywords` — editing a single
//     sticker's search metadata after it's already in a set.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/40_custom_emoji_and_sticker_details.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text.startsWith('/set_info ')) {
      final name = text.substring('/set_info '.length).trim();
      final set = await bot.getStickerSet(name);
      final stickers = set['stickers'] as List;
      await bot.sendMessage(
        chatId,
        '${set['title']} — ${stickers.length} sticker(s), type: ${set['sticker_type']}',
      );
    } else if (text == '/topic_icons') {
      // The fixed palette of icon stickers Telegram offers for forum topics.
      final icons = await bot.getForumTopicIconStickers();
      await bot.sendMessage(
        chatId,
        '${icons.length} forum topic icons available.',
      );
    } else if (text.startsWith('/resolve_emoji ')) {
      final customEmojiId = text.substring('/resolve_emoji '.length).trim();
      final stickers = await bot.getCustomEmojiStickers([customEmojiId]);
      if (stickers.isEmpty) {
        await bot.sendMessage(chatId, 'Unknown custom emoji ID.');
      } else {
        await bot.sendMessage(
          chatId,
          'Resolved to sticker: ${stickers.first['file_id']}',
        );
      }
    } else if (text.startsWith('/retag ')) {
      // Re-tags an existing sticker (identified by its own `file_id`,
      // *not* the set's name) with new search emoji and keywords.
      final fileId = text.substring('/retag '.length).trim();
      await bot.setStickerEmojiList(fileId, ['😀', '🙂']);
      await bot.setStickerKeywords(fileId, keywords: ['happy', 'smile']);
      await bot.sendMessage(chatId, 'Sticker re-tagged.');
    } else {
      await bot.sendMessage(
        chatId,
        'Try /set_info <name>, /topic_icons, /resolve_emoji <id>, or /retag <file_id>.',
      );
    }
  }
}
