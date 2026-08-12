// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 36 — POSTING, EDITING, AND REPOSTING STORIES
// ============================================================================
//
// Bots can post Telegram Stories on behalf of a connected Business
// Account. This example shows:
//   - `postStory` — publishing a new photo/video story.
//   - `editStory` — replacing an existing story's content or caption.
//   - `deleteStory` — removing one early.
//   - `repostStory` — reposting a story from one connected account to
//     another (both must be connected to this bot, and the source story
//     must have been posted/reposted by this bot).
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. Connect a Business Account to this bot in Telegram's settings.
//   3. dart run example/36_stories.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final businessConnectionId =
        update.businessConnection?['id'] as String?;
    if (chatId == null || text == null || businessConnectionId == null)
      continue;

    if (text == '/post_story') {
      // `activePeriod` (in seconds) is how long the story stays up — must
      // be one of 6h, 12h, 24h, or 48h.
      final story = await bot.postStory(
        businessConnectionId,
        InputStoryContentPhoto(InputFile.path('example/assets/story.jpg')),
        24 * 3600,
        caption: 'Posted via ptgb!',
      );
      await bot.sendMessage(chatId, 'Story posted: ${story['id']}');
    } else if (text.startsWith('/edit_story ')) {
      final storyId = int.parse(text.substring('/edit_story '.length));
      await bot.editStory(
        businessConnectionId,
        storyId,
        InputStoryContentPhoto(
          InputFile.path('example/assets/story_updated.jpg'),
        ),
        caption: 'Updated caption!',
      );
      await bot.sendMessage(chatId, 'Story $storyId updated.');
    } else if (text.startsWith('/delete_story ')) {
      final storyId = int.parse(text.substring('/delete_story '.length));
      await bot.deleteStory(businessConnectionId, storyId);
      await bot.sendMessage(chatId, 'Story $storyId deleted.');
    } else {
      await bot.sendMessage(
        chatId,
        'Try /post_story, /edit_story <id>, or /delete_story <id>.',
      );
    }
  }
}
