// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 31 — PROFILE PHOTOS AND FILE DOWNLOADS
// ============================================================================
//
// `04_media_and_files.dart` covers downloading a file the bot just
// received. This example covers two related but distinct things:
//   - `getUserProfilePhotos` — fetching a *user's* profile picture(s),
//     unrelated to any message they've sent.
//   - `downloadFileById` — a shortcut that resolves a `file_id` straight to
//     bytes, skipping the manual `getFile` + `downloadFile` two-step.
//   - `setMyProfilePhoto` / `removeMyProfilePhoto` — managing the *bot's*
//     own profile picture.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/31_profile_photos_and_downloads.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final userId = update.userId;
    if (chatId == null || text == null || userId == null) continue;

    if (text == '/my_photo') {
      final photos = await bot.getUserProfilePhotos(userId, limit: 1);
      final total = photos.totalCount;
      if (total == 0) {
        await bot.sendMessage(chatId, 'You don\'t have a profile photo set.');
        continue;
      }

      // Each entry in `photos` is itself a list of sizes of the same photo;
      // grab the largest size (last in the list) of the most recent photo.
      final sizes = photos.photos.first;
      final largest = sizes.last;
      final fileId = largest.fileId;

      // `downloadFileById` combines `getFile` (resolving the file path)
      // and `downloadFile` (fetching the bytes) into one call.
      final bytes = await bot.downloadFileById(fileId);
      await bot.sendPhoto(
        chatId,
        InputFile.bytes(bytes, filename: 'profile.jpg'),
      );
    } else if (text == '/set_my_photo') {
      // Sets the *bot's own* avatar from a local file.
      await bot.setMyProfilePhoto(
        InputProfilePhotoStatic(InputFile.path('example/assets/logo.png')),
      );
      await bot.sendMessage(chatId, 'Updated my profile photo.');
    } else if (text == '/remove_my_photo') {
      await bot.removeMyProfilePhoto();
      await bot.sendMessage(chatId, 'Removed my profile photo.');
    } else {
      await bot.sendMessage(
        chatId,
        'Try /my_photo, /set_my_photo, or /remove_my_photo.',
      );
    }
  }
}
