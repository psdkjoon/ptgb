// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 14 — CREATING AND MANAGING A STICKER SET
// ============================================================================
//
// Sending an existing sticker is simple (`sendSticker`), but *creating* a
// sticker set trips people up because it's a multi-step flow with a
// non-obvious detail: the set is owned by a Telegram *user* — typically
// you, the developer — not by the bot itself. You'll need your own numeric
// user ID (a bot like @userinfobot can tell you yours).
//
// The flow:
//   1. Upload the image once with `uploadStickerFile` to get a `file_id`.
//   2. Create the set with `createNewStickerSet`, referencing that `file_id`.
//   3. From then on, add more stickers to the same set with `addStickerToSet`.
//
// Image requirements (enforced by Telegram, not by ptgb): a static sticker
// must be a PNG or WEBP, up to 512x512, with at least one side exactly 512px.
// See https://core.telegram.org/bots/api#sending-files for the full rules.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. Put a 512x512 PNG at the path below (or point PATH at your own).
//   3. dart run example/14_sticker_sets.dart
// ============================================================================

import 'dart:developer';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  // Your personal Telegram user ID — the set's owner. NOT the bot's own ID.
  const ownerUserId = 123456789;
  const stickerImagePath = 'assets/sticker.png';
  // Sticker set names must be unique across all of Telegram and end in
  // "_by_<bot_username>" (no leading @).
  const setName = 'my_demo_set_by_your_bot';

  // Step 1: upload the raw image and get back a reusable file_id.
  final uploaded = await bot.uploadStickerFile(
    ownerUserId,
    InputFile.path(stickerImagePath),
    StickerFormat.static,
  );
  final fileId = uploaded.fileId;
  log('Uploaded sticker file: $fileId');

  // Step 2: create the set using that file_id. Every sticker needs at least
  // one emoji describing it, used when people search for stickers.
  await bot.createNewStickerSet(
    ownerUserId,
    setName,
    'My Demo Sticker Set',
    [
      InputSticker(InputFile.id(fileId), StickerFormat.static, ['😀']),
    ],
  );
  log('Created sticker set: $setName');

  // Step 3: adding a second sticker to the same set later just needs the
  // set name — no need to recreate it. Reusing the same uploaded file here
  // for simplicity; in practice you'd upload a different image.
  await bot.addStickerToSet(
    ownerUserId,
    setName,
    InputSticker(InputFile.id(fileId), StickerFormat.static, ['😎']),
  );
  log('Added a second sticker to the set.');

  // The set can now be sent like any other sticker set. `getStickerSet`
  // returns its stickers (each with its own file_id) if you need them.
  final set = await bot.getStickerSet(setName);
  final firstStickerFileId = set.stickers.first.fileId;

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    if (chatId == null || update.text != '/sticker') continue;
    await bot.sendSticker(chatId, InputFile.id(firstStickerFileId));
  }
}
