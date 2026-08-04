// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)
// ============================================================================
// 32 — CHAT BOOSTS AND THIRD-PARTY VERIFICATION
// ============================================================================
//
// Two unrelated-but-niche features grouped here because both are about a
// bot vouching for or reporting on an account:
//   - `getUserChatBoosts` — how many "boost slots" a user has applied to a
//     given chat (Telegram's Premium-powered channel/group boosting).
//   - `verifyUser` / `verifyChat` / `removeUserVerification` /
//     `removeChatVerification` — an official verification badge your bot
//     can grant on behalf of an approved organization. This requires prior
//     approval from Telegram (see https://telegram.org/verify) — without
//     it, these calls will fail even with correct code.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/32_chat_boosts_and_verification.dart
// ============================================================================
import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final userId = update.userId;
    if (chatId == null || text == null || userId == null) continue;

    if (text == '/my_boosts') {
      final boosts = await bot.getUserChatBoosts(chatId, userId);
      final count = (boosts['boosts'] as List).length;
      await bot.sendMessage(
        chatId,
        count == 0
            ? 'You haven\'t boosted this chat.'
            : 'You\'ve applied $count boost(s) to this chat — thank you!',
      );
    } else if (text == '/verify_me') {
      // Only works for bots with Telegram-granted verification approval.
      try {
        await bot.verifyUser(
          userId,
          customDescription: 'Verified community member',
        );
        await bot.sendMessage(chatId, 'You now have a verification badge.');
      } on TelegramApiException catch (e) {
        await bot.sendMessage(chatId, 'Could not verify: ${e.description}');
      }
    } else if (text == '/unverify_me') {
      try {
        await bot.removeUserVerification(userId);
        await bot.sendMessage(chatId, 'Verification badge removed.');
      } on TelegramApiException catch (e) {
        await bot.sendMessage(
          chatId,
          'Could not remove verification: ${e.description}',
        );
      }
    } else {
      await bot.sendMessage(
        chatId,
        'Try /my_boosts, /verify_me, or /unverify_me.',
      );
    }
  }
}
