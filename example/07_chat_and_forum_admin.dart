// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 07 — CHAT ADMINISTRATION AND FORUM TOPICS
// ============================================================================
//
// For bots that moderate groups/supergroups: muting/banning members,
// pinning messages, and managing forum topics (the "threads" feature in
// large supergroups). Your bot needs to be a group admin with the relevant
// permissions for most of these to work.
//
// HOW TO RUN:
//   Add this bot as an admin to a supergroup, then:
//   dart run example/07_chat_and_forum_admin.dart   (with a `.env` file)
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    final text = update.text;
    final chatId = update.chatId;
    if (text == null || chatId == null) continue;

    // Commands below expect a reply to the target user's message, e.g.
    // reply to someone's message with "/mute" to mute them.
    final repliedTo = update.replyToMessage;
    final targetUserId = (repliedTo?['from'] as Map?)?['id'] as int?;

    if (text == '/mute' && targetUserId != null) {
      // Restrict the user from sending anything, for 10 minutes.
      await bot.restrictChatMember(
        chatId,
        targetUserId,
        const ChatPermissions(canSendMessages: false),
        untilDate: DateTime.now()
                .add(const Duration(minutes: 10))
                .millisecondsSinceEpoch ~/
            1000,
      );
      await bot.sendMessage(chatId, 'Muted for 10 minutes.');
    } else if (text == '/unmute' && targetUserId != null) {
      // Restore the chat's default permissions for this user.
      await bot.restrictChatMember(
        chatId,
        targetUserId,
        const ChatPermissions(
          canSendMessages: true,
          canSendPhotos: true,
          canSendOtherMessages: true,
        ),
      );
      await bot.sendMessage(chatId, 'Unmuted.');
    } else if (text == '/pin') {
      final messageId = repliedTo?['message_id'] as int?;
      if (messageId != null) {
        await bot.pinChatMessage(chatId, messageId);
        await bot.sendMessage(chatId, 'Pinned.');
      }
    } else if (text == '/new_topic') {
      // Forum topics only work in supergroups with the "Topics" feature
      // enabled. This creates a new one with an orange icon.
      final topic = await bot.createForumTopic(
        chatId,
        'General Discussion',
        iconColor: 0xFF9500,
      );
      await bot.sendMessage(
        chatId,
        'Created topic "${topic['name']}" (id: ${topic['message_thread_id']}).',
      );
    } else if (text == '/chat_info') {
      final info = await bot.getChat(chatId);
      final memberCount = await bot.getChatMemberCount(chatId);
      await bot.sendMessage(
        chatId,
        'Chat: ${info['title'] ?? info['first_name']}\nMembers: $memberCount',
      );
    } else {
      await bot.sendMessage(
        chatId,
        'Reply to a user\'s message with /mute, /unmute, or /pin. '
        'Try /new_topic or /chat_info too.',
      );
    }
  }
}
