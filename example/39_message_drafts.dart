// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 39 — MESSAGE DRAFTS
// ============================================================================
//
// `sendMessageDraft` and `sendRichMessageDraft` pre-fill a chat's message
// input field with text, without actually sending a message — useful for
// bots that suggest a reply for a human to review and send themselves
// (e.g. a customer-support co-pilot), rather than posting on their behalf.
//
// HOW TO RUN:
//   1. Create a file named `.env` next to this script containing:
//        TOKEN=123456:ABC-your-token-here
//   2. dart run example/39_message_drafts.dart
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();
  var nextDraftId = 1;

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text.startsWith('/suggest ')) {
      final suggestion = text.substring('/suggest '.length);

      // `draftId` is a locally-chosen identifier for this draft — pick a
      // fresh one each time you replace the draft's content, so you don't
      // accidentally overwrite a draft the user is mid-way through editing.
      await bot.sendMessageDraft(chatId, nextDraftId++, text: suggestion);
      await bot.sendMessage(
        chatId,
        'Drafted a reply for you — check the input field.',
      );
    } else if (text == '/suggest_rich') {
      // The rich-message equivalent, for a draft built from blocks rather
      // than plain text — see 20_new_bot_api_concepts.dart for the block format.
      await bot.sendRichMessageDraft(
        chatId,
        {
          'blocks': [
            {
              'type': 'text',
              'text':
                  'Here\'s a suggested reply — feel free to edit before sending.',
            },
          ],
        },
      );
    } else {
      await bot.sendMessage(chatId, 'Try /suggest <text> or /suggest_rich.');
    }
  }
}
