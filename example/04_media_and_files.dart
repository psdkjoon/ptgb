// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 04 — SENDING AND RECEIVING MEDIA
// ============================================================================
//
// This example shows the three ways to provide a file to Telegram
// (`InputFile.url`, `InputFile.path`, `InputFile.bytes`), how to send an
// album with `sendMediaGroup`, and how to download a file a user sent you.
//
// HOW TO RUN:
//   dart run example/04_media_and_files.dart   (with a `.env` file)
// ============================================================================

import 'dart:io';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final text = update.text;
    final chatId = update.chatId;
    if (chatId == null) continue;

    if (text == '/photo_url') {
      // Simplest option: let Telegram fetch the file from a public URL.
      // No upload bandwidth used on your end.
      await bot.sendPhoto(
        chatId,
        InputFile.url('https://picsum.photos/800/600'),
        caption: 'A random photo, fetched by Telegram from a URL.',
      );
    } else if (text == '/photo_local') {
      // Upload a file that lives on disk next to your script.
      // (Swap this path for a real file on your machine to try it.)
      final path = 'example/assets/sample.jpg';
      if (File(path).existsSync()) {
        await bot.sendPhoto(
          chatId,
          InputFile.path(path),
          caption: 'Uploaded from disk.',
        );
      } else {
        await bot.sendMessage(
          chatId,
          'Put a sample.jpg at $path to try this one!',
        );
      }
    } else if (text == '/photo_bytes') {
      // Upload raw bytes you already have in memory — e.g. bytes you
      // generated, downloaded, or received from another API.
      final bytes =
          await InputFile.url('https://picsum.photos/200').readBytes();
      await bot.sendPhoto(
        chatId,
        InputFile.bytes(bytes, filename: 'generated.jpg'),
        caption: 'Uploaded straight from memory.',
      );
    } else if (text == '/album') {
      // Send up to 10 photos/videos as a single grouped album message.
      await bot.sendMediaGroup(chatId, [
        InputMediaPhoto(InputFile.url('https://picsum.photos/seed/1/600')),
        InputMediaPhoto(
          InputFile.url('https://picsum.photos/seed/2/600'),
          caption: 'Second photo has a caption',
        ),
        InputMediaPhoto(InputFile.url('https://picsum.photos/seed/3/600')),
      ]);
    } else if (update.message?['photo'] != null) {
      // The user sent us a photo — Telegram gives several resolutions;
      // the last one in the list is the largest.
      final sizes = update.message!['photo'] as List;
      final largest = sizes.last as Map<String, dynamic>;
      final fileId = largest['file_id'] as String;

      // Download the actual bytes of that photo.
      final bytes = await bot.downloadFileById(fileId);
      await bot.sendMessage(
        chatId,
        'Thanks! I downloaded ${bytes.length} bytes of your photo.',
      );
    } else {
      await bot.sendMessage(
        chatId,
        'Try /photo_url, /photo_local, /photo_bytes, /album — or just send me a photo!',
      );
    }
  }
}
