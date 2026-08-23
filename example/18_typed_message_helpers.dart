// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)
// ============================================================================
// 18 — TYPED User / Chat / Message HELPERS
// ============================================================================
//
// `Update`'s own getters (`.message`, `.chat`, `.from`, `.text`, ...) return
// typed wrapper classes directly — `Update.message` is already a `Message`,
// `Message.from` is already a `User`, and so on, all the way down into
// content fields like `.photo`, `.location`, and `.poll`.
//
// `.raw` is always available on every wrapper for anything not covered by
// a getter — these are just thin, read-only views over the same underlying
// JSON, so wrapping (or re-wrapping) one is always cheap.
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
    final message = update.message;
    if (message == null) continue;

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

    // Content types (photos, polls, locations, service messages, ...) are
    // typed too, not just the top-level message.
    final photo = message.photo;
    if (photo != null && photo.isNotEmpty) {
      final biggest = photo.last; // Telegram lists sizes smallest-to-largest.
      await bot.sendMessage(
        message.chat.id,
        'Got a photo! Largest size is ${biggest.width}x${biggest.height}, '
        'file_id ${biggest.fileId}.',
      );
    }

    // If a field doesn't have a typed getter yet, `.raw` is always there —
    // e.g. `message.raw['some_new_field']`.
  }
}
