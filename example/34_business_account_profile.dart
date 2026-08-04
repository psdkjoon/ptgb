// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 34 — MANAGING A CONNECTED BUSINESS ACCOUNT'S PROFILE
// ============================================================================
//
// A Telegram user can connect their account to your bot via Business
// Connections, granting it permission to act on their behalf. Every
// business method takes a `businessConnectionId`, which arrives on the
// `business_connection` update once the user connects (see
// `Bot.getBusinessConnection`). This example shows the profile-editing
// subset:
//   - `setBusinessAccountName` / `setBusinessAccountUsername` /
//     `setBusinessAccountBio`
//   - `setBusinessAccountProfilePhoto` / `removeBusinessAccountProfilePhoto`
//   - `setBusinessAccountGiftSettings` — which gift types the account accepts.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. Connect a Business Account to this bot in Telegram's settings, then
//      note the `business_connection_id` from the resulting update.
//   3. dart run example/34_business_account_profile.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final businessConnectionId =
        update.raw['business_connection']?['id'] as String?;
    if (chatId == null || text == null) continue;

    if (businessConnectionId == null) {
      // Not every update carries a business connection — this example only
      // reacts to the connection event itself for simplicity.
      continue;
    }

    if (text == '/setup_business_profile') {
      await bot.setBusinessAccountName(
        businessConnectionId,
        'Acme Support',
        lastName: 'Desk',
      );
      await bot.setBusinessAccountUsername(
        businessConnectionId,
        username: 'acme_support',
      );
      await bot.setBusinessAccountBio(
        businessConnectionId,
        bio: 'Official support account — replies within 24h.',
      );
      await bot.setBusinessAccountProfilePhoto(
        businessConnectionId,
        InputProfilePhotoStatic(InputFile.path('example/assets/logo.png')),
      );
    } else if (text == '/remove_business_photo') {
      await bot.removeBusinessAccountProfilePhoto(businessConnectionId);
    } else if (text == '/gift_settings') {
      // Accept ordinary and limited gifts, but decline unique (one-of-a-kind)
      // gifts and gifted Premium subscriptions.
      await bot.setBusinessAccountGiftSettings(
        businessConnectionId,
        true,
        const AcceptedGiftTypes(
          unlimitedGifts: true,
          limitedGifts: true,
          uniqueGifts: false,
          premiumSubscription: false,
        ),
      );
    }
  }
}
