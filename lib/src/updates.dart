import 'core.dart';

/// A single incoming Telegram update, as yielded by [Bot.poll] or delivered
/// to [Bot.serveWebhook].
///
/// An update carries exactly one of many possible payload types (a new
/// message, a button press, a poll answer, ...). Rather than exposing a
/// giant typed union, `ptgb` gives you the [raw] JSON plus a set of
/// convenient nullable getters for each payload type — check whichever ones
/// are relevant to your bot, or use the [anyMessage]/[chat]/[from]/[text]/
/// [callbackData] shortcuts that look across the common cases for you.
///
/// ```dart
/// await for (final update in bot.poll()) {
///   if (update.message != null) {
///     print('New message: ${update.text}');
///   } else if (update.callbackQuery != null) {
///     print('Button pressed: ${update.callbackData}');
///   }
/// }
/// ```
class Update {
  /// The raw JSON payload for this update, exactly as Telegram sent it.
  final Json raw;

  /// Wraps a raw update JSON object.
  const Update(this.raw);

  /// The unique, monotonically increasing ID of this update.
  int get updateId => raw['update_id'] as int;

  /// A new incoming message, of any kind — text, photo, sticker, etc.
  Json? get message => raw['message'] as Json?;

  /// A message that was edited after being sent.
  Json? get editedMessage => raw['edited_message'] as Json?;

  /// A new post in a channel the bot administers.
  Json? get channelPost => raw['channel_post'] as Json?;

  /// A channel post that was edited after being sent.
  Json? get editedChannelPost => raw['edited_channel_post'] as Json?;

  /// A Telegram Business account was connected to, or its settings changed.
  Json? get businessConnection => raw['business_connection'] as Json?;

  /// A new message in a connected Telegram Business account's chat.
  Json? get businessMessage => raw['business_message'] as Json?;

  /// A message in a connected Telegram Business account's chat was edited.
  Json? get editedBusinessMessage => raw['edited_business_message'] as Json?;

  /// Messages were deleted in a connected Telegram Business account's chat.
  Json? get deletedBusinessMessages =>
      raw['deleted_business_messages'] as Json?;

  /// A new message from a guest — an unauthenticated user browsing via
  /// [Guest Mode](https://core.telegram.org/bots/features#guest-bots) —
  /// received in a chat the bot is not a member of. Use its
  /// `guest_query_id` field with [Bot.answerGuestQuery] to reply.
  Json? get guestMessage => raw['guest_message'] as Json?;

  /// A user changed their reaction on a message (requires the bot to have subscribed to this update type).
  Json? get messageReaction => raw['message_reaction'] as Json?;

  /// The anonymous aggregate reaction counts on a message changed.
  Json? get messageReactionCount => raw['message_reaction_count'] as Json?;

  /// A user typed `@yourbot ...` in any chat's input field.
  Json? get inlineQuery => raw['inline_query'] as Json?;

  /// A user picked a result from an inline query.
  Json? get chosenInlineResult => raw['chosen_inline_result'] as Json?;

  /// A user tapped an inline keyboard button with `callbackData` set.
  Json? get callbackQuery => raw['callback_query'] as Json?;

  /// A shipping address was provided for an invoice with flexible shipping options.
  Json? get shippingQuery => raw['shipping_query'] as Json?;

  /// The final confirmation before a payment is captured — must be answered within 10 seconds.
  Json? get preCheckoutQuery => raw['pre_checkout_query'] as Json?;

  /// A user completed a purchase of paid media the bot posted.
  Json? get purchasedPaidMedia => raw['purchased_paid_media'] as Json?;

  /// A poll's state changed (new votes, or it was stopped).
  Json? get poll => raw['poll'] as Json?;

  /// A user changed their answer in a non-anonymous poll the bot sent.
  Json? get pollAnswer => raw['poll_answer'] as Json?;

  /// The bot's own membership status changed in a chat (added, removed, promoted, etc).
  Json? get myChatMember => raw['my_chat_member'] as Json?;

  /// A chat member's status changed (requires the bot to have subscribed to this update type).
  Json? get chatMember => raw['chat_member'] as Json?;

  /// A user requested to join a chat that requires admin approval.
  Json? get chatJoinRequest => raw['chat_join_request'] as Json?;

  /// A chat received a new boost.
  Json? get chatBoost => raw['chat_boost'] as Json?;

  /// A boost was removed from a chat.
  Json? get removedChatBoost => raw['removed_chat_boost'] as Json?;

  /// A user's Telegram Stars subscription to the bot's content was created, renewed, expired, or cancelled.
  Json? get subscription => raw['subscription'] as Json?;

  /// The first non-null message-like payload on this update — checks
  /// [message], [editedMessage], [channelPost], [editedChannelPost],
  /// [businessMessage], [editedBusinessMessage], and [guestMessage] in
  /// that order.
  Json? get anyMessage =>
      message ??
      editedMessage ??
      channelPost ??
      editedChannelPost ??
      businessMessage ??
      editedBusinessMessage ??
      guestMessage;

  /// The chat this update relates to, looked up across [anyMessage],
  /// [callbackQuery], [myChatMember], [chatMember], and [chatJoinRequest].
  Json? get chat =>
      (anyMessage?['chat'] as Json?) ??
      (callbackQuery?['message'] as Json?)?['chat'] as Json? ??
      (myChatMember?['chat'] as Json?) ??
      (chatMember?['chat'] as Json?) ??
      (chatJoinRequest?['chat'] as Json?);

  /// Shortcut for `chat?['id']` — the ID of the chat this update relates to, ready to pass to `chatId` parameters.
  int? get chatId => chat?['id'] as int?;

  /// The user who triggered this update, looked up across every relevant payload type.
  Json? get from =>
      (anyMessage?['from'] as Json?) ??
      (callbackQuery?['from'] as Json?) ??
      (inlineQuery?['from'] as Json?) ??
      (chosenInlineResult?['from'] as Json?) ??
      (shippingQuery?['from'] as Json?) ??
      (preCheckoutQuery?['from'] as Json?) ??
      (myChatMember?['from'] as Json?) ??
      (chatMember?['from'] as Json?) ??
      (chatJoinRequest?['from'] as Json?);

  /// Shortcut for `anyMessage?['message_id']` — the ID of the message this
  /// update relates to, ready to pass to `messageId` parameters.
  int? get messageId => anyMessage?['message_id'] as int?;

  /// Shortcut for `from?['id']` — the ID of the user who triggered this
  /// update, ready to pass to `userId` parameters.
  int? get userId => from?['id'] as int?;

  /// Shortcut for `from?['username']`, if the triggering user has one set.
  String? get username => from?['username'] as String?;

  /// Shortcut for `from?['first_name']` — the triggering user's first name.
  String? get firstName => from?['first_name'] as String?;

  /// Shortcut for `chat?['type']` — `'private'`, `'group'`, `'supergroup'`,
  /// or `'channel'`.
  String? get chatType => chat?['type'] as String?;

  /// Shortcut for the text of [anyMessage], if any.
  String? get text => anyMessage?['text'] as String?;

  /// Shortcut for `anyMessage?['caption']` — the caption on a media
  /// message, if any.
  String? get caption => anyMessage?['caption'] as String?;

  /// Shortcut for `anyMessage?['message_thread_id']` — the forum topic or
  /// message thread this update belongs to, if any.
  int? get messageThreadId => anyMessage?['message_thread_id'] as int?;

  /// Shortcut for `anyMessage?['reply_to_message']` — the message this
  /// update is a reply to, if any, as raw JSON.
  Json? get replyToMessage => anyMessage?['reply_to_message'] as Json?;

  /// Shortcut for `anyMessage?['entities']` (or `caption_entities` when
  /// there's no plain-text `entities` field) — the special entities
  /// (mentions, URLs, bot commands, ...) found in the message's text or
  /// caption, if any.
  List<Json>? get entities =>
      (anyMessage?['entities'] as List?)?.cast<Json>() ??
      (anyMessage?['caption_entities'] as List?)?.cast<Json>();

  /// Shortcut for the `data` payload of [callbackQuery], if any.
  String? get callbackData => callbackQuery?['data'] as String?;

  /// Shortcut for `guestMessage?['guest_query_id']` — pass this straight
  /// to [Bot.answerGuestQuery] to reply to the guest.
  String? get guestQueryId => guestMessage?['guest_query_id'] as String?;

  /// Shortcut for `chatJoinRequest?['query_id']` — present when this join
  /// request was routed to the bot as a "guard bot" (see
  /// `ChatFullInfo.guard_bot`) and must be resolved within 10 seconds via
  /// [Bot.answerChatJoinRequestQuery] or [Bot.sendChatJoinRequestWebApp].
  /// `null` for ordinary join requests handled with
  /// `approveChatJoinRequest`/`declineChatJoinRequest`.
  String? get chatJoinRequestQueryId => chatJoinRequest?['query_id'] as String?;
}

/// The set of update payload types a bot can subscribe to, used with
/// [Bot.getUpdates]' and [Bot.poll]'s `allowedUpdates` parameter to control
/// which updates Telegram sends.
enum UpdateType {
  message,
  editedMessage,
  channelPost,
  editedChannelPost,
  businessConnection,
  businessMessage,
  editedBusinessMessage,
  deletedBusinessMessages,
  guestMessage,
  messageReaction,
  messageReactionCount,
  inlineQuery,
  chosenInlineResult,
  callbackQuery,
  shippingQuery,
  preCheckoutQuery,
  purchasedPaidMedia,
  poll,
  pollAnswer,
  myChatMember,
  chatMember,
  chatJoinRequest,
  chatBoost,
  removedChatBoost,
  subscription;

  /// The literal string Telegram's API expects for this update type.
  String get value => switch (this) {
        UpdateType.message => 'message',
        UpdateType.editedMessage => 'edited_message',
        UpdateType.channelPost => 'channel_post',
        UpdateType.editedChannelPost => 'edited_channel_post',
        UpdateType.businessConnection => 'business_connection',
        UpdateType.businessMessage => 'business_message',
        UpdateType.editedBusinessMessage => 'edited_business_message',
        UpdateType.deletedBusinessMessages => 'deleted_business_messages',
        UpdateType.guestMessage => 'guest_message',
        UpdateType.messageReaction => 'message_reaction',
        UpdateType.messageReactionCount => 'message_reaction_count',
        UpdateType.inlineQuery => 'inline_query',
        UpdateType.chosenInlineResult => 'chosen_inline_result',
        UpdateType.callbackQuery => 'callback_query',
        UpdateType.shippingQuery => 'shipping_query',
        UpdateType.preCheckoutQuery => 'pre_checkout_query',
        UpdateType.purchasedPaidMedia => 'purchased_paid_media',
        UpdateType.poll => 'poll',
        UpdateType.pollAnswer => 'poll_answer',
        UpdateType.myChatMember => 'my_chat_member',
        UpdateType.chatMember => 'chat_member',
        UpdateType.chatJoinRequest => 'chat_join_request',
        UpdateType.chatBoost => 'chat_boost',
        UpdateType.removedChatBoost => 'removed_chat_boost',
        UpdateType.subscription => 'subscription',
      };
}
