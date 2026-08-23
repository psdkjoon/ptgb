import 'core.dart';
import 'models.dart';

/// A button press on an [InlineKeyboardButton.callback] button, as found in
/// `Update.callbackQuery`.
class CallbackQuery {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `CallbackQuery` JSON object.
  const CallbackQuery(this.raw);

  /// Unique identifier for this query. Pass to `Bot.answerCallbackQuery`.
  String get id => raw['id'] as String;

  /// The user who tapped the button.
  User get from => User(raw['from'] as Json);

  /// The message the button was attached to, if it's still accessible
  /// (older or inline-only messages may not include this), as raw JSON
  /// since it may be a full `Message` or an `InaccessibleMessage`.
  Json? get message => raw['message'] as Json?;

  /// Identifier of the inline message the button was attached to, if it
  /// was sent via an inline query result rather than a normal message.
  String? get inlineMessageId => raw['inline_message_id'] as String?;

  /// Identifier that's the same for every callback query from the same chat/message context.
  String get chatInstance => raw['chat_instance'] as String;

  /// The `callbackData` set on the button, if any.
  String? get data => raw['data'] as String?;

  /// The short name of the game to launch, for game-callback buttons.
  String? get gameShortName => raw['game_short_name'] as String?;
}

/// A user typing `@yourbot ...` in any chat's input field, as found in
/// `Update.inlineQuery`.
class InlineQuery {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `InlineQuery` JSON object.
  const InlineQuery(this.raw);

  /// Unique identifier for this query. Pass to `Bot.answerInlineQuery`.
  String get id => raw['id'] as String;

  /// The user who is typing the query.
  User get from => User(raw['from'] as Json);

  /// The text typed so far, after the bot's `@username`.
  String get query => raw['query'] as String;

  /// Pagination offset, as previously returned via `nextOffset` on a prior answer.
  String get offset => raw['offset'] as String;

  /// The type of chat the query is being typed from, if known.
  String? get chatType => raw['chat_type'] as String?;

  /// The user's approximate location, if the bot requested location access.
  Location? get location =>
      raw['location'] == null ? null : Location(raw['location'] as Json);
}

/// A user picking a result from an inline query, as found in
/// `Update.chosenInlineResult`. Requires the bot to have `inline_feedback`
/// enabled with @BotFather.
class ChosenInlineResult {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChosenInlineResult` JSON object.
  const ChosenInlineResult(this.raw);

  /// Identifier of the chosen result.
  String get resultId => raw['result_id'] as String;

  /// The user who picked the result.
  User get from => User(raw['from'] as Json);

  /// The user's approximate location, if the bot requested location access.
  Location? get location =>
      raw['location'] == null ? null : Location(raw['location'] as Json);

  /// Identifier of the sent inline message, if it has one (used to edit it later).
  String? get inlineMessageId => raw['inline_message_id'] as String?;

  /// The original query text that produced this result.
  String get query => raw['query'] as String;
}

/// A shipping address submitted for an invoice with flexible shipping
/// options, as found in `Update.shippingQuery`.
class ShippingQuery {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ShippingQuery` JSON object.
  const ShippingQuery(this.raw);

  /// Unique identifier for this query. Pass to `Bot.answerShippingQuery`.
  String get id => raw['id'] as String;

  /// The user who triggered the checkout.
  User get from => User(raw['from'] as Json);

  /// The bot-defined invoice payload.
  String get invoicePayload => raw['invoice_payload'] as String;

  /// The shipping address the user entered.
  ShippingAddress get shippingAddress =>
      ShippingAddress(raw['shipping_address'] as Json);
}

/// The final confirmation before a payment is captured, as found in
/// `Update.preCheckoutQuery`. Must be answered within 10 seconds.
class PreCheckoutQuery {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `PreCheckoutQuery` JSON object.
  const PreCheckoutQuery(this.raw);

  /// Unique identifier for this query. Pass to `Bot.answerPreCheckoutQuery`.
  String get id => raw['id'] as String;

  /// The user who triggered the checkout.
  User get from => User(raw['from'] as Json);

  /// Three-letter ISO 4217 currency code, or `'XTR'` for Telegram Stars.
  String get currency => raw['currency'] as String;

  /// Total price in the smallest units of [currency].
  int get totalAmount => raw['total_amount'] as int;

  /// The bot-defined invoice payload.
  String get invoicePayload => raw['invoice_payload'] as String;

  /// Identifier of the shipping option the user chose, if applicable.
  String? get shippingOptionId => raw['shipping_option_id'] as String?;

  /// The order information supplied by the payer, if requested.
  OrderInfo? get orderInfo =>
      raw['order_info'] == null ? null : OrderInfo(raw['order_info'] as Json);
}

/// A request to join a chat that requires admin approval, as found in
/// `Update.chatJoinRequest`.
class ChatJoinRequest {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChatJoinRequest` JSON object.
  const ChatJoinRequest(this.raw);

  /// The chat the user wants to join.
  Chat get chat => Chat(raw['chat'] as Json);

  /// The user requesting to join.
  User get from => User(raw['from'] as Json);

  /// A global identifier for this user, valid across chats.
  int get userChatId => raw['user_chat_id'] as int;

  /// Unix timestamp the request was sent.
  int get date => raw['date'] as int;

  /// A bio the user attached to the request, if any.
  String? get bio => raw['bio'] as String?;

  /// The invite link used to make the request, if any.
  ChatInviteLink? get inviteLink => raw['invite_link'] == null
      ? null
      : ChatInviteLink(raw['invite_link'] as Json);

  /// Present when this request was routed to the bot as a "guard bot" —
  /// pass to `Bot.answerChatJoinRequestQuery`/`Bot.sendChatJoinRequestWebApp`.
  /// `null` for ordinary join requests handled with
  /// `approveChatJoinRequest`/`declineChatJoinRequest`.
  String? get queryId => raw['query_id'] as String?;
}

/// A change in a chat member's status, as found in `Update.myChatMember`/`Update.chatMember`.
class ChatMemberUpdated {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChatMemberUpdated` JSON object.
  const ChatMemberUpdated(this.raw);

  /// The chat the member's status changed in.
  Chat get chat => Chat(raw['chat'] as Json);

  /// The admin (or the member themself) who performed the action.
  User get from => User(raw['from'] as Json);

  /// Unix timestamp of the change.
  int get date => raw['date'] as int;

  /// The member's previous status.
  ChatMember get oldChatMember => ChatMember(raw['old_chat_member'] as Json);

  /// The member's new status.
  ChatMember get newChatMember => ChatMember(raw['new_chat_member'] as Json);

  /// The invite link used to join, if the user joined via one.
  ChatInviteLink? get inviteLink => raw['invite_link'] == null
      ? null
      : ChatInviteLink(raw['invite_link'] as Json);

  /// Whether the user joined via a join request that was approved.
  bool? get viaJoinRequest => raw['via_join_request'] as bool?;

  /// Whether the user joined via a chat folder invite link.
  bool? get viaChatFolderInviteLink =>
      raw['via_chat_folder_invite_link'] as bool?;
}

/// A user's answer to a non-anonymous poll the bot sent, as found in
/// `Update.pollAnswer`.
class PollAnswer {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `PollAnswer` JSON object.
  const PollAnswer(this.raw);

  /// Identifier of the poll being answered.
  String get pollId => raw['poll_id'] as String;

  /// The chat that voted anonymously on behalf of, if applicable.
  Chat? get voterChat =>
      raw['voter_chat'] == null ? null : Chat(raw['voter_chat'] as Json);

  /// The user who voted, if not an anonymous chat vote.
  User? get user => raw['user'] == null ? null : User(raw['user'] as Json);

  /// The 0-based indices of the options this voter chose. Empty if the
  /// voter retracted their vote.
  List<int> get optionIds => (raw['option_ids'] as List).cast<int>();
}

/// A change in a user's reaction on a message, as found in
/// `Update.messageReaction`. Requires the bot to have subscribed to this update type.
class MessageReactionUpdated {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `MessageReactionUpdated` JSON object.
  const MessageReactionUpdated(this.raw);

  /// The chat containing the message.
  Chat get chat => Chat(raw['chat'] as Json);

  /// Identifier of the message whose reactions changed.
  int get messageId => raw['message_id'] as int;

  /// The user who changed their reaction, if not anonymous.
  User? get user => raw['user'] == null ? null : User(raw['user'] as Json);

  /// The chat that changed its reaction anonymously, if applicable.
  Chat? get actorChat =>
      raw['actor_chat'] == null ? null : Chat(raw['actor_chat'] as Json);

  /// Unix timestamp of the change.
  int get date => raw['date'] as int;

  /// The reaction types previously set by this user/chat, as raw JSON.
  List<Json> get oldReaction => (raw['old_reaction'] as List).cast<Json>();

  /// The reaction types now set by this user/chat, as raw JSON.
  List<Json> get newReaction => (raw['new_reaction'] as List).cast<Json>();
}

/// The anonymous aggregate reaction counts on a message changed, as found in
/// `Update.messageReactionCount`.
class MessageReactionCountUpdated {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `MessageReactionCountUpdated` JSON object.
  const MessageReactionCountUpdated(this.raw);

  /// The chat containing the message.
  Chat get chat => Chat(raw['chat'] as Json);

  /// Identifier of the message whose reaction counts changed.
  int get messageId => raw['message_id'] as int;

  /// Unix timestamp of the change.
  int get date => raw['date'] as int;

  /// The current aggregate reaction counts, as raw JSON.
  List<Json> get reactions => (raw['reactions'] as List).cast<Json>();
}

/// A Telegram Business account was connected to, or its settings changed,
/// as found in `Update.businessConnection`.
class BusinessConnection {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `BusinessConnection` JSON object.
  const BusinessConnection(this.raw);

  /// Unique identifier of this business connection.
  String get id => raw['id'] as String;

  /// The business account's owner.
  User get user => User(raw['user'] as Json);

  /// The business account's chat identifier.
  int get userChatId => raw['user_chat_id'] as int;

  /// Unix timestamp the connection was established.
  int get date => raw['date'] as int;

  /// The rights granted to the bot on this account, as raw JSON.
  Json? get rights => raw['rights'] as Json?;

  /// Whether the connection is currently enabled.
  bool get isEnabled => raw['is_enabled'] as bool;
}

/// Messages were deleted in a connected Telegram Business account's chat,
/// as found in `Update.deletedBusinessMessages`.
class BusinessMessagesDeleted {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `BusinessMessagesDeleted` JSON object.
  const BusinessMessagesDeleted(this.raw);

  /// Identifier of the business connection the deletion happened on.
  String get businessConnectionId => raw['business_connection_id'] as String;

  /// Information about the chat the messages were deleted from.
  Chat get chat => Chat(raw['chat'] as Json);

  /// Identifiers of the deleted messages.
  List<int> get messageIds => (raw['message_ids'] as List).cast<int>();
}

/// A user completed a purchase of paid media the bot posted, as found in
/// `Update.purchasedPaidMedia`.
class PaidMediaPurchased {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `PaidMediaPurchased` JSON object.
  const PaidMediaPurchased(this.raw);

  /// The user who purchased the media.
  User get from => User(raw['from'] as Json);

  /// The bot-defined payload of the paid media that was purchased.
  String get paidMediaPayload => raw['paid_media_payload'] as String;
}

/// A chat received a new boost, as found in `Update.chatBoost`.
class ChatBoostUpdated {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChatBoostUpdated` JSON object.
  const ChatBoostUpdated(this.raw);

  /// The boosted chat.
  Chat get chat => Chat(raw['chat'] as Json);

  /// The boost that was added.
  ChatBoost get boost => ChatBoost(raw['boost'] as Json);
}

/// A boost was removed from a chat, as found in `Update.removedChatBoost`.
class ChatBoostRemoved {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChatBoostRemoved` JSON object.
  const ChatBoostRemoved(this.raw);

  /// The chat the boost was removed from.
  Chat get chat => Chat(raw['chat'] as Json);

  /// Unique identifier of the boost that was removed.
  String get boostId => raw['boost_id'] as String;

  /// Unix timestamp the boost was removed.
  int get removeDate => raw['remove_date'] as int;

  /// How the removed boost had been obtained, as raw JSON.
  Json get source => raw['source'] as Json;
}

/// A user's Telegram Stars subscription to the bot's content changed
/// status (created, renewed, expired, or cancelled), as found in
/// `Update.subscription`.
class ChatSubscriptionUpdated {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw subscription-update JSON object.
  const ChatSubscriptionUpdated(this.raw);

  /// The chat the subscription applies to, if present.
  Chat? get chat => raw['chat'] == null ? null : Chat(raw['chat'] as Json);

  /// The subscribing user, if present.
  User? get user => raw['user'] == null ? null : User(raw['user'] as Json);
}

/// A single incoming Telegram update, as yielded by [Bot.poll] or delivered
/// to [Bot.serveWebhook].
///
/// An update carries exactly one of many possible payload types (a new
/// message, a button press, a poll answer, ...). `ptgb` gives you the
/// [raw] JSON plus a set of convenient nullable getters — now returning
/// typed wrappers directly rather than raw JSON — for each payload type.
/// Check whichever ones are relevant to your bot, or use the
/// [anyMessage]/[chat]/[from]/[text]/[callbackData] shortcuts that look
/// across the common cases for you.
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
  Message? get message => _msg(raw['message']);

  /// A message that was edited after being sent.
  Message? get editedMessage => _msg(raw['edited_message']);

  /// A new post in a channel the bot administers.
  Message? get channelPost => _msg(raw['channel_post']);

  /// A channel post that was edited after being sent.
  Message? get editedChannelPost => _msg(raw['edited_channel_post']);

  /// A Telegram Business account was connected to, or its settings changed.
  BusinessConnection? get businessConnection =>
      raw['business_connection'] == null
          ? null
          : BusinessConnection(raw['business_connection'] as Json);

  /// A new message in a connected Telegram Business account's chat.
  Message? get businessMessage => _msg(raw['business_message']);

  /// A message in a connected Telegram Business account's chat was edited.
  Message? get editedBusinessMessage => _msg(raw['edited_business_message']);

  /// Messages were deleted in a connected Telegram Business account's chat.
  BusinessMessagesDeleted? get deletedBusinessMessages =>
      raw['deleted_business_messages'] == null
          ? null
          : BusinessMessagesDeleted(raw['deleted_business_messages'] as Json);

  /// A new message from a guest — an unauthenticated user browsing via
  /// [Guest Mode](https://core.telegram.org/bots/features#guest-bots) —
  /// received in a chat the bot is not a member of. Use its
  /// `guestQueryId` field with [Bot.answerGuestQuery] to reply.
  Message? get guestMessage => _msg(raw['guest_message']);

  /// A user changed their reaction on a message (requires the bot to have subscribed to this update type).
  MessageReactionUpdated? get messageReaction => raw['message_reaction'] == null
      ? null
      : MessageReactionUpdated(raw['message_reaction'] as Json);

  /// The anonymous aggregate reaction counts on a message changed.
  MessageReactionCountUpdated? get messageReactionCount =>
      raw['message_reaction_count'] == null
          ? null
          : MessageReactionCountUpdated(
              raw['message_reaction_count'] as Json,
            );

  /// A user typed `@yourbot ...` in any chat's input field.
  InlineQuery? get inlineQuery => raw['inline_query'] == null
      ? null
      : InlineQuery(raw['inline_query'] as Json);

  /// A user picked a result from an inline query.
  ChosenInlineResult? get chosenInlineResult =>
      raw['chosen_inline_result'] == null
          ? null
          : ChosenInlineResult(raw['chosen_inline_result'] as Json);

  /// A user tapped an inline keyboard button with `callbackData` set.
  CallbackQuery? get callbackQuery => raw['callback_query'] == null
      ? null
      : CallbackQuery(raw['callback_query'] as Json);

  /// A shipping address was provided for an invoice with flexible shipping options.
  ShippingQuery? get shippingQuery => raw['shipping_query'] == null
      ? null
      : ShippingQuery(raw['shipping_query'] as Json);

  /// The final confirmation before a payment is captured — must be answered within 10 seconds.
  PreCheckoutQuery? get preCheckoutQuery => raw['pre_checkout_query'] == null
      ? null
      : PreCheckoutQuery(raw['pre_checkout_query'] as Json);

  /// A user completed a purchase of paid media the bot posted.
  PaidMediaPurchased? get purchasedPaidMedia =>
      raw['purchased_paid_media'] == null
          ? null
          : PaidMediaPurchased(raw['purchased_paid_media'] as Json);

  /// A poll's state changed (new votes, or it was stopped).
  Poll? get poll => raw['poll'] == null ? null : Poll(raw['poll'] as Json);

  /// A user changed their answer in a non-anonymous poll the bot sent.
  PollAnswer? get pollAnswer => raw['poll_answer'] == null
      ? null
      : PollAnswer(raw['poll_answer'] as Json);

  /// The bot's own membership status changed in a chat (added, removed, promoted, etc).
  ChatMemberUpdated? get myChatMember => raw['my_chat_member'] == null
      ? null
      : ChatMemberUpdated(raw['my_chat_member'] as Json);

  /// A chat member's status changed (requires the bot to have subscribed to this update type).
  ChatMemberUpdated? get chatMember => raw['chat_member'] == null
      ? null
      : ChatMemberUpdated(raw['chat_member'] as Json);

  /// A user requested to join a chat that requires admin approval.
  ChatJoinRequest? get chatJoinRequest => raw['chat_join_request'] == null
      ? null
      : ChatJoinRequest(raw['chat_join_request'] as Json);

  /// A chat received a new boost.
  ChatBoostUpdated? get chatBoost => raw['chat_boost'] == null
      ? null
      : ChatBoostUpdated(raw['chat_boost'] as Json);

  /// A boost was removed from a chat.
  ChatBoostRemoved? get removedChatBoost => raw['removed_chat_boost'] == null
      ? null
      : ChatBoostRemoved(raw['removed_chat_boost'] as Json);

  /// A user's Telegram Stars subscription to the bot's content was created, renewed, expired, or cancelled.
  ChatSubscriptionUpdated? get subscription => raw['subscription'] == null
      ? null
      : ChatSubscriptionUpdated(raw['subscription'] as Json);

  static Message? _msg(dynamic raw) =>
      raw == null ? null : Message(raw as Json);

  /// The first non-null message-like payload on this update — checks
  /// [message], [editedMessage], [channelPost], [editedChannelPost],
  /// [businessMessage], [editedBusinessMessage], and [guestMessage] in
  /// that order.
  Message? get anyMessage =>
      message ??
      editedMessage ??
      channelPost ??
      editedChannelPost ??
      businessMessage ??
      editedBusinessMessage ??
      guestMessage;

  /// The chat this update relates to, looked up across [anyMessage],
  /// [callbackQuery], [myChatMember], [chatMember], and [chatJoinRequest].
  Chat? get chat {
    final cbChatJson = callbackQuery?.message?['chat'] as Json?;
    return anyMessage?.chat ??
        (cbChatJson == null ? null : Chat(cbChatJson)) ??
        myChatMember?.chat ??
        chatMember?.chat ??
        chatJoinRequest?.chat;
  }

  /// Shortcut for `chat?.id` — the ID of the chat this update relates to, ready to pass to `chatId` parameters.
  int? get chatId => chat?.id;

  /// The user who triggered this update, looked up across every relevant payload type.
  User? get from =>
      anyMessage?.from ??
      callbackQuery?.from ??
      inlineQuery?.from ??
      chosenInlineResult?.from ??
      shippingQuery?.from ??
      preCheckoutQuery?.from ??
      myChatMember?.from ??
      chatMember?.from ??
      chatJoinRequest?.from;

  /// Shortcut for `anyMessage?.messageId` — the ID of the message this
  /// update relates to, ready to pass to `messageId` parameters.
  int? get messageId => anyMessage?.messageId;

  /// Shortcut for `from?.id` — the ID of the user who triggered this
  /// update, ready to pass to `userId` parameters.
  int? get userId => from?.id;

  /// Shortcut for `from?.username`, if the triggering user has one set.
  String? get username => from?.username;

  /// Shortcut for `from?.firstName` — the triggering user's first name.
  String? get firstName => from?.firstName;

  /// Shortcut for `chat?.type` — `'private'`, `'group'`, `'supergroup'`,
  /// or `'channel'`.
  String? get chatType => chat?.type;

  /// Shortcut for the text of [anyMessage], if any.
  String? get text => anyMessage?.text;

  /// Shortcut for `anyMessage?.caption` — the caption on a media
  /// message, if any.
  String? get caption => anyMessage?.caption;

  /// Shortcut for `anyMessage?.messageThreadId` — the forum topic or
  /// message thread this update belongs to, if any.
  int? get messageThreadId => anyMessage?.messageThreadId;

  /// Shortcut for `anyMessage?.replyToMessage` — the message this
  /// update is a reply to, if any.
  Message? get replyToMessage => anyMessage?.replyToMessage;

  /// Shortcut for `anyMessage?.entities` (or `captionEntities` when
  /// there's no plain-text `entities` field) — the special entities
  /// (mentions, URLs, bot commands, ...) found in the message's text or
  /// caption, if any, as raw JSON.
  List<Json>? get entities =>
      anyMessage?.entities ?? anyMessage?.captionEntities;

  /// Shortcut for the `data` payload of [callbackQuery], if any.
  String? get callbackData => callbackQuery?.data;

  /// Shortcut for `guestMessage?.raw['guest_query_id']` — pass this straight
  /// to [Bot.answerGuestQuery] to reply to the guest.
  String? get guestQueryId => raw['guest_message'] == null
      ? null
      : (raw['guest_message'] as Json)['guest_query_id'] as String?;

  /// Shortcut for `chatJoinRequest?.queryId` — present when this join
  /// request was routed to the bot as a "guard bot" (see
  /// `ChatFullInfo.guard_bot`) and must be resolved within 10 seconds via
  /// [Bot.answerChatJoinRequestQuery] or [Bot.sendChatJoinRequestWebApp].
  /// `null` for ordinary join requests handled with
  /// `approveChatJoinRequest`/`declineChatJoinRequest`.
  String? get chatJoinRequestQueryId => chatJoinRequest?.queryId;
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
