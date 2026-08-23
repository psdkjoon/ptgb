// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 19 — UPDATE SHORTCUTS AND THE anyMessage FALLBACK
// ============================================================================
//
// Every earlier example reaches into an `Update` via one specific getter,
// like `update.message` or `update.callbackQuery`. This example is about
// the two things that make that easier day-to-day:
//
//   1. `Update`'s direct-access shortcuts — `userId`, `messageId`,
//      `username`, `firstName`, `chatType`, `caption`, `messageThreadId`,
//      `replyToMessage`, and `entities` — which look across whichever
//      payload type the update actually carries (a plain message, an
//      edited one, a channel post, ...) so you don't have to null-check
//      five different fields yourself.
//
//   2. `anyMessage` — the typed `Message` for whichever message-like
//      payload is present on the update (checked in the order: `message`,
//      `editedMessage`, `channelPost`, `editedChannelPost`,
//      `businessMessage`, `editedBusinessMessage`, `guestMessage`). Every
//      shortcut above is really just a null-safe read off `anyMessage`,
//      and you can do the same for any typed getter ptgb ships on
//      `Message` — photos, locations, documents, contacts, and so on all
//      live there.
//
// HOW TO RUN:
//   dart run example/19_update_shortcuts_and_any_message.dart   (with a `.env` file)
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    if (chatId == null) continue;

    // --- Part 1: the direct-access shortcuts ---------------------------
    //
    // These all read from `anyMessage` (or `from`/`chat`) under the hood,
    // so they work the same whether the update is a fresh message, an
    // edited one, or a channel post — you don't need a different code
    // path for each.
    if (update.text == '/whoami') {
      final lines = [
        'userId: ${update.userId}',
        'username: ${update.username ?? '(none set)'}',
        'firstName: ${update.firstName}',
        'chatType: ${update.chatType}',
        'messageId: ${update.messageId}',
      ];
      // `messageThreadId` is only non-null in forum supergroups / bots
      // with topic mode enabled in private chats.
      if (update.messageThreadId != null) {
        lines.add('messageThreadId: ${update.messageThreadId}');
      }
      // `replyToMessage` and `entities` are also just shortcuts — try
      // replying to another message with /whoami, or sending a message
      // containing a URL or @mention, to see them populate.
      if (update.replyToMessage != null) {
        lines.add('replying to message ${update.replyToMessage!.messageId}');
      }
      if (update.entities != null) {
        final types = update.entities!.map((e) => e['type']).join(', ');
        lines.add('entities: $types');
      }
      await bot.sendMessage(chatId, lines.join('\n'));
      continue;
    }

    // `caption` is the shortcut version of `anyMessage?.caption` — it
    // covers photos, videos, documents, etc. all at once.
    if (update.caption != null) {
      await bot.sendMessage(chatId, 'Nice caption: "${update.caption}"');
      continue;
    }

    // --- Part 2: anyMessage as a typed fallback ------------------------
    //
    // ptgb only ships direct `Update` shortcuts for the fields most bots
    // need day-to-day. For everything else, read the typed getter
    // straight off `anyMessage` — exactly like you'd read any other
    // field on a `Message`.
    final msg = update.anyMessage;
    if (msg == null) continue;

    // Photos: `photo` is a list of `PhotoSize`s (same image at several
    // resolutions) — the last entry is the largest.
    final photoSizes = msg.photo;
    if (photoSizes != null && photoSizes.isNotEmpty) {
      final largest = photoSizes.last;
      await bot.sendMessage(
        chatId,
        'Got a photo! Largest size: '
        '${largest.width}x${largest.height}, file_id: ${largest.fileId}',
      );
      continue;
    }

    // Locations: plain `latitude`/`longitude` getters.
    final location = msg.location;
    if (location != null) {
      await bot.sendMessage(
        chatId,
        'Location received: ${location.latitude}, ${location.longitude}',
      );
      continue;
    }

    // Documents: `fileName` and `mimeType` live alongside the usual `fileId`.
    final document = msg.document;
    if (document != null) {
      await bot.sendMessage(
        chatId,
        'Document: ${document.fileName} (${document.mimeType})',
      );
      continue;
    }

    // Contacts: shared straight from the user's address book.
    final contact = msg.contact;
    if (contact != null) {
      await bot.sendMessage(
        chatId,
        'Contact: ${contact.firstName} — ${contact.phoneNumber}',
      );
      continue;
    }

    if (update.text == '/start') {
      await bot.sendMessage(
        chatId,
        'Try /whoami, send a caption on a photo, or share a photo, '
        'location, document, or contact to see anyMessage in action.',
      );
    }
  }
}
