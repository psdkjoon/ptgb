// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 25 — LOCATIONS, VENUES, AND LIVE LOCATION
// ============================================================================
//
// This example shows the three location-flavored send methods:
//   - `sendLocation` — a static pin, or a "live" one that updates in place.
//   - `sendVenue` — a location with a name and address attached (a place,
//     not just coordinates).
//   - `editMessageLiveLocation` / `stopMessageLiveLocation` — updating (and
//     eventually freezing) a live location after it's been sent.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/25_locations_and_venues.dart
// ============================================================================

import 'dart:async';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text == '/where') {
      // A plain static pin — Berlin's Brandenburg Gate, for example.
      await bot.sendLocation(chatId, 52.5163, 13.3777);
    } else if (text == '/venue') {
      // A venue adds a name/address card under the pin.
      await bot.sendVenue(
        chatId,
        52.5163,
        13.3777,
        'Brandenburg Gate',
        'Pariser Platz, 10117 Berlin, Germany',
      );
    } else if (text == '/live') {
      // `livePeriod` (in seconds, 60–86400) marks this as a live location
      // that recipients see updating in real time as you call
      // `editMessageLiveLocation` on it.
      final sent = await bot.sendLocation(
        chatId,
        52.5163,
        13.3777,
        livePeriod: 300,
      );
      final messageId = sent['message_id'] as int;

      await bot.sendMessage(
        chatId,
        'Live location started — I\'ll "move" it a few times.',
      );

      // Simulate movement: nudge the coordinates every few seconds.
      var lat = 52.5163;
      var lon = 13.3777;
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(seconds: 5));
        lat += 0.001;
        lon += 0.001;
        await bot.editMessageLiveLocation(
          lat,
          lon,
          chatId: chatId,
          messageId: messageId,
        );
      }

      // Freeze it in its final position so it stops being "live" before
      // `livePeriod` naturally expires.
      await bot.stopMessageLiveLocation(chatId: chatId, messageId: messageId);
      await bot.sendMessage(chatId, 'Live location stopped.');
    } else {
      await bot.sendMessage(chatId, 'Try /where, /venue, or /live.');
    }
  }
}
