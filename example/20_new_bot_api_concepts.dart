// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)
// ============================================================================
// 20 — NEWER BOT API CONCEPTS: checklists, rich messages, suggested posts,
//      ephemeral messages, guest queries, and guard-bot join requests
// ============================================================================
//
// Bot API versions 9.1 through 10.2 introduced a handful of features that
// don't fit naturally into the earlier numbered examples because they're
// genuinely different concepts, not just new parameters on familiar
// methods. This file is a guided tour of each, in isolation, so you can
// see the shape of the request/response for each one. A few of them only
// make sense in contexts this file can't fully simulate on its own (a
// connected business account, a guest-mode-enabled bot, a chat that's
// designated this bot as its "guard bot") — those sections say so and show
// the calls you'd make once that context exists.
//
// HOW TO RUN:
//   dart run example/20_new_bot_api_concepts.dart   (with a `.env` file)
// ============================================================================
import 'dart:developer';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    // ------------------------------------------------------------------
    // CHECKLISTS (Bot API 9.1) — sendChecklist / editMessageChecklist
    // ------------------------------------------------------------------
    // Checklists are a business-account-only message type: a titled list
    // of tasks the recipient can check off. Sending one requires a
    // `businessConnectionId`, which your bot receives via a
    // `business_connection` update once a user connects their Telegram
    // Business account to it (Settings > Business > Chatbots, on their
    // end). This snippet shows the call shape; wire it up to a real
    // `update.businessConnection?['id']` once you have one connected.
    if (update.text == '/checklist-demo') {
      const businessConnectionId = 'REPLACE_WITH_A_REAL_BUSINESS_CONNECTION_ID';
      final checklist = InputChecklist(
        'Trip packing list',
        const [
          InputChecklistTask(1, 'Passport'),
          InputChecklistTask(2, 'Charger'),
          InputChecklistTask(3, 'Sunscreen'),
        ],
        othersCanMarkTasksAsDone: true,
      );
      log('Would call: bot.sendChecklist($businessConnectionId, chatId, '
          'checklist "${checklist.title}")');
      // await bot.sendChecklist(businessConnectionId, update.chatId!, checklist);
      //
      // To edit it afterwards (e.g. after the message_id comes back):
      //   final updated = InputChecklist('Trip packing list', [
      //     const InputChecklistTask(1, 'Passport'),
      //     const InputChecklistTask(2, 'Charger'),
      //     const InputChecklistTask(3, 'Sunscreen'),
      //     const InputChecklistTask(4, 'Book'), // task added
      //   ]);
      //   await bot.editMessageChecklist(businessConnectionId, chatId, messageId, updated);
      continue;
    }

    // ------------------------------------------------------------------
    // RICH MESSAGES (Bot API 10.1/10.2) — sendRichMessage /
    // sendRichMessageDraft
    // ------------------------------------------------------------------
    // Rich messages are structured content — headings, lists, tables,
    // block quotes, embedded media — built from `InputRichBlock*` JSON
    // objects rather than a single plain-text caption. ptgb passes
    // `richMessage` through as raw `Json` (see `sendRichMessage`'s doc
    // comment for why), matching Telegram's `InputRichMessage` shape:
    // a `blocks` array of block objects. This is a minimal two-block
    // example — a heading followed by a paragraph.
    if (update.text == '/rich-demo') {
      final chatId = update.chatId!;
      final richMessage = {
        'blocks': [
          {
            'type': 'section_heading',
            'text': {'type': 'plain', 'text': 'Weekly update'},
          },
          {
            'type': 'paragraph',
            'text': {
              'type': 'plain',
              'text': 'Everything shipped on time this week.',
            },
          },
        ],
      };
      await bot.sendRichMessage(chatId, richMessage);
      // `sendRichMessageDraft` sends the same shape but marks it as a
      // still-being-generated preview — handy for streaming an AI
      // response block by block, the rich-content equivalent of
      // `sendMessageDraft` for plain text (see example/11 for that).
      continue;
    }

    // ------------------------------------------------------------------
    // SUGGESTED POSTS (Bot API 9.2) — approveSuggestedPost /
    // declineSuggestedPost
    // ------------------------------------------------------------------
    // In a channel's "direct messages" chat, users can suggest a post for
    // the channel; it arrives to the bot as an ordinary message with
    // `suggested_post_info` set. The bot (with the right admin rights)
    // approves or declines it — it isn't published until approved.
    final suggestedPostInfo =
        update.anyMessage?['suggested_post_info'] as Json?;
    if (suggestedPostInfo != null) {
      final chatId = update.chatId!;
      final messageId = update.messageId!;
      log('Suggested post received: $suggestedPostInfo');
      // Approve immediately:
      //   await bot.approveSuggestedPost(chatId, messageId);
      // Approve for a specific future time instead:
      //   await bot.approveSuggestedPost(chatId, messageId, sendDate: someUnixTime);
      // Or decline with a reason shown to the poster:
      //   await bot.declineSuggestedPost(chatId, messageId, comment: 'Not on-topic for this channel');
      await bot.approveSuggestedPost(chatId, messageId);
      continue;
    }

    // ------------------------------------------------------------------
    // EPHEMERAL MESSAGES (Bot API 10.2) — editEphemeralMessage* /
    // deleteEphemeralMessage
    // ------------------------------------------------------------------
    // An ephemeral message is visible only to the bot and one specific
    // user in a group, even though it was "sent to the chat" — useful for
    // per-user prompts in a shared space without spamming everyone else.
    // You create one by passing `receiverUserId` (and, if replying to a
    // callback query, `callbackQueryId`) to a handful of send* methods —
    // see `sendLivePhoto`'s doc comment for the pattern, which applies
    // the same way to `sendMessage` and friends. Once sent, Telegram gives
    // you an `ephemeral_message_id` (0 for the ordinary `message_id`,
    // since ephemeral messages don't have one) to edit or delete it with.
    if (update.text == '/ephemeral-demo') {
      final chatId = update.chatId!;
      final userId = update.userId!;
      // NOTE: sendMessage doesn't currently expose receiverUserId/
      // callbackQueryId as typed parameters — reach for the low-level
      // `bot.call` escape hatch to set them until a typed overload lands:
      final sent = await bot.call('sendMessage', {
        'chat_id': chatId,
        'text': 'Only you can see this message.',
        'receiver_user_id': userId,
      }) as Json;
      final ephemeralMessageId = sent['ephemeral_message_id'] as int;
      await Future<void>.delayed(const Duration(seconds: 3));
      await bot.editEphemeralMessageText(
        chatId,
        userId,
        ephemeralMessageId,
        'Still only you — but edited 3 seconds later.',
      );
      // await bot.deleteEphemeralMessage(chatId, userId, ephemeralMessageId);
      continue;
    }

    // ------------------------------------------------------------------
    // GUEST QUERIES (Bot API 10.0) — Update.guestMessage / answerGuestQuery
    // ------------------------------------------------------------------
    // Guest Mode lets a bot receive messages and reply in chats it isn't
    // a member of, if the chat summons it as a guest (and the bot has
    // `supports_guest_queries` enabled via @BotFather). Such messages
    // arrive as `update.guestMessage` instead of `update.message`; use
    // its `guest_query_id` (exposed as the `update.guestQueryId`
    // shortcut) to send exactly one reply back via `answerGuestQuery`.
    if (update.guestMessage != null) {
      final guestQueryId = update.guestQueryId!;
      log('Guest message: ${update.guestMessage!['text']}');
      await bot.answerGuestQuery(guestQueryId, {
        'type': 'article',
        'id': '1',
        'title': 'Hello from a guest bot',
        'input_message_content': {'message_text': 'Thanks for summoning me!'},
      });
      continue;
    }

    // ------------------------------------------------------------------
    // GUARD-BOT JOIN REQUESTS (Bot API 10.1) — answerChatJoinRequestQuery /
    // sendChatJoinRequestWebApp
    // ------------------------------------------------------------------
    // Compare this to example/13, which covers the *ordinary*
    // approve/decline-immediately flow via `approveChatJoinRequest`. If a
    // chat instead designates this bot as its "guard bot" (see
    // `ChatFullInfo.guard_bot`), join requests arrive with an extra
    // `query_id` field (exposed as `update.chatJoinRequestQueryId`) and
    // the bot has a 10-second window to resolve them differently — either
    // directly, or by first showing the requester a Mini App (e.g. to run
    // a captcha) before deciding.
    final chatJoinRequestQueryId = update.chatJoinRequestQueryId;
    if (chatJoinRequestQueryId != null) {
      // Resolve directly:
      //   await bot.answerChatJoinRequestQuery(chatJoinRequestQueryId, 'approve');
      //   await bot.answerChatJoinRequestQuery(chatJoinRequestQueryId, 'decline');
      //   await bot.answerChatJoinRequestQuery(chatJoinRequestQueryId, 'queue'); // let a human decide
      //
      // ...or show a Mini App first and decide based on what it reports back:
      //   await bot.sendChatJoinRequestWebApp(chatJoinRequestQueryId, {
      //     'url': 'https://example.com/verify',
      //   });
      log('Guard-bot join request query: $chatJoinRequestQueryId');
      await bot.answerChatJoinRequestQuery(chatJoinRequestQueryId, 'queue');
      continue;
    }

    if (update.text == '/start') {
      final chatId = update.chatId;
      if (chatId != null) {
        await bot.sendMessage(
          chatId,
          'Try /checklist-demo, /rich-demo, or /ephemeral-demo to see the '
          'newer Bot API concepts covered in this example.',
        );
      }
    }
  }
}
