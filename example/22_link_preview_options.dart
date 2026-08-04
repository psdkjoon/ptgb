// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 22 — LINK PREVIEW OPTIONS
// ============================================================================
//
// By default, Telegram auto-generates a preview card for the first URL it
// finds in a text message. `LinkPreviewOptions` lets you control (or
// disable) that behavior. This example shows:
//   - Disabling the preview entirely.
//   - Previewing a specific URL instead of the first one found.
//   - Showing the preview above the text instead of below it.
//   - Requesting a larger preview image.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/22_link_preview_options.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text == '/no_preview') {
      // `LinkPreviewOptions.disabled()` is a shortcut for
      // `LinkPreviewOptions(isDisabled: true)`.
      await bot.sendMessage(
        chatId,
        'Check the docs at https://core.telegram.org/bots/api — no preview card here.',
        linkPreviewOptions: LinkPreviewOptions.disabled(),
      );
    } else if (text == '/pick_preview') {
      // The message mentions one URL in passing but we want the preview to
      // come from a different, more relevant one.
      await bot.sendMessage(
        chatId,
        'See core.telegram.org for the full API — image below is unrelated:',
        linkPreviewOptions: const LinkPreviewOptions(url: 'https://dart.dev'),
      );
    } else if (text == '/big_preview_above') {
      await bot.sendMessage(
        chatId,
        'Big preview, shown above the text — https://dart.dev',
        linkPreviewOptions: const LinkPreviewOptions(
          preferLargeMedia: true,
          showAboveText: true,
        ),
      );
    } else {
      await bot.sendMessage(
        chatId,
        'Try /no_preview, /pick_preview, or /big_preview_above.',
      );
    }
  }
}
