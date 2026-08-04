// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)
// ============================================================================
// 18 — TYPED User / Chat / Message HELPERS
// ============================================================================
//
// `Update`'s own getters (`.message`, `.chat`, `.from`, `.text`, ...) return
// raw `Json` — fast, zero-overhead, and exactly what earlier examples use.
//
// If you'd rather work with typed getters instead of `map['field'] as
// SomeType` everywhere, wrap that raw JSON in `User`, `Chat`, or `Message`.
// These are read-only wrappers around the same JSON — nothing is copied or
// re-fetched, and `.raw` is always there for anything not covered by a
// getter. Like `Update` itself, deeply-nested content (photos, polls,
// service messages, ...) stays raw JSON rather than being fully modeled.
//
// Note: `User`, `Chat`, and `Message` are common names. If another package
// you're using also exports classes with these names, import ptgb with a
// prefix to disambiguate, e.g. `import 'package:ptgb/ptgb.dart' as ptgb;`.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/18_typed_message_helpers.dart
// ============================================================================
import 'dart:developer';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final rawMessage = update.message;
    if (rawMessage == null) continue;

    // Wrap the raw JSON. This is just a view over `rawMessage` — cheap to
    // create, and safe to throw away and re-wrap as often as you like.
    final message = Message(rawMessage);

    // Typed getters instead of `rawMessage['from']?['first_name']`.
    final sender = message.from;
    log('Message ${message.messageId} from ${sender?.fullName ?? 'unknown'} '
        'in ${message.chat.type} chat "${message.chat.title ?? message.chat.id}"');

    if (message.text == '/whoami') {
      final user = sender;
      if (user == null) {
        await bot.sendMessage(message.chat.id, "I can't tell who sent that.");
        continue;
      }
      await bot.sendMessage(
        message.chat.id,
        'You are ${user.fullName}'
        '${user.username != null ? ' (@${user.username})' : ''}, '
        'user ID ${user.id}, writing in a ${message.chat.type} chat.',
      );
      continue;
    }

    // Content-type fields that can have many different shapes (photos,
    // polls, service messages, ...) are still raw JSON — pull fields off
    // them the same way you would off `update.anyMessage`.
    final photo = message.photo;
    if (photo != null && photo.isNotEmpty) {
      final biggest = photo.last; // Telegram lists sizes smallest-to-largest.
      await bot.sendMessage(
        message.chat.id,
        'Got a photo! Largest size is ${biggest['width']}x${biggest['height']}, '
        'file_id ${biggest['file_id']}.',
      );
    }
  }
}
