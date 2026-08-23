// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 28 — BOT PROFILE, DESCRIPTION, AND MENU BUTTON
// ============================================================================
//
// Beyond the commands list (`02_commands_and_text.dart`), a bot has a
// handful of other profile-like settings you can manage at runtime:
//   - `setMyName` — the display name shown in chat headers.
//   - `setMyDescription` — shown on the bot's empty "start" screen.
//   - `setMyShortDescription` — shown in shares/forwards and profile previews.
//   - `setChatMenuButton` — the button next to the message input field;
//     can open a Web App instead of the default commands menu.
//
// All of these accept an optional `languageCode`/per-chat scope, letting
// you localize or customize per-chat — this example only sets the defaults.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/28_bot_profile_and_menu.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text == '/setup_profile') {
      await bot.setMyName(name: 'Demo Bot');
      await bot.setMyDescription(
        description: 'A demo bot showing off ptgb profile-management methods.',
      );
      await bot.setMyShortDescription(shortDescription: 'ptgb profile demo');
      await bot.sendMessage(
        chatId,
        'Profile updated — check my chat header and start screen.',
      );
    } else if (text == '/read_profile') {
      final name = await bot.getMyName();
      final description = await bot.getMyDescription();
      final shortDescription = await bot.getMyShortDescription();
      await bot.sendMessage(
        chatId,
        'Name: ${name.name}\n'
        'Description: ${description.description}\n'
        'Short description: ${shortDescription.shortDescription}',
      );
    } else if (text == '/web_app_menu') {
      // Replaces the default "Menu" button (which normally opens the
      // commands list) with one that launches a Web App directly.
      await bot.setChatMenuButton(
        chatId: chatId,
        menuButton: {
          'type': 'web_app',
          'text': 'Open App',
          'web_app': {'url': 'https://your-mini-app.example.com'},
        },
      );
      await bot.sendMessage(chatId, 'Menu button now opens the Web App.');
    } else if (text == '/reset_menu') {
      // `{'type': 'default'}` restores the standard commands-menu button.
      await bot
          .setChatMenuButton(chatId: chatId, menuButton: {'type': 'default'});
      await bot.sendMessage(chatId, 'Menu button reset to default.');
    } else {
      await bot.sendMessage(
        chatId,
        'Try /setup_profile, /read_profile, /web_app_menu, or /reset_menu.',
      );
    }
  }
}
