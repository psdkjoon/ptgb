import 'core.dart';

/// A thin, read-only typed wrapper around a raw Telegram `User` JSON object
/// — the shape found in [Message.from], `Update.from`, `ChatMember.user`,
/// and many other places throughout the API.
///
/// Wrapping is optional and lossless: construct one from any `User`-shaped
/// [Json] you already have (`User(update.from!)`), and [raw] is always
/// available underneath for any field not covered by a getter here.
class User {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `User` JSON object.
  const User(this.raw);

  /// Unique identifier for this user or bot.
  int get id => raw['id'] as int;

  /// Whether this user represents a bot.
  bool get isBot => raw['is_bot'] as bool;

  /// The user's or bot's first name.
  String get firstName => raw['first_name'] as String;

  /// The user's or bot's last name, if set.
  String? get lastName => raw['last_name'] as String?;

  /// The user's or bot's `@username`, if set.
  String? get username => raw['username'] as String?;

  /// IETF language tag of the user's Telegram client, if known (not
  /// necessarily their actual spoken language).
  String? get languageCode => raw['language_code'] as String?;

  /// Whether this user is a Telegram Premium subscriber.
  bool? get isPremium => raw['is_premium'] as bool?;

  /// Whether this user added the bot to their attachment menu.
  bool? get addedToAttachmentMenu => raw['added_to_attachment_menu'] as bool?;

  /// (Bot-only, via `getMe`) Whether the bot can be invited to groups.
  bool? get canJoinGroups => raw['can_join_groups'] as bool?;

  /// (Bot-only, via `getMe`) Whether privacy mode is disabled, so the bot
  /// receives every message sent to a group it's in.
  bool? get canReadAllGroupMessages =>
      raw['can_read_all_group_messages'] as bool?;

  /// (Bot-only, via `getMe`) Whether the bot supports inline queries.
  bool? get supportsInlineQueries => raw['supports_inline_queries'] as bool?;

  /// (Bot-only, via `getMe`) Whether the bot can be connected to a Telegram
  /// Business account.
  bool? get canConnectToBusiness => raw['can_connect_to_business'] as bool?;

  /// (Bot-only, via `getMe`) Whether the bot has a main Mini App.
  bool? get hasMainWebApp => raw['has_main_web_app'] as bool?;

  /// [firstName], plus [lastName] appended if set — a convenient display name.
  String get fullName => lastName == null ? firstName : '$firstName $lastName';

  @override
  String toString() =>
      'User($id, ${username != null ? '@$username' : fullName})';
}

/// A thin, read-only typed wrapper around a raw Telegram `Chat` JSON object
/// — the shape found in [Message.chat], `Update.chat`, etc.
///
/// For the richer `ChatFullInfo` shape returned by `Bot.getChat` (which adds
/// fields like bio, permissions, and invite links on top of these), keep
/// using the raw [Json] returned by that call — this wrapper only covers
/// the smaller `Chat` shape embedded in messages and updates.
class Chat {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Chat` JSON object.
  const Chat(this.raw);

  /// Unique identifier for this chat.
  int get id => raw['id'] as int;

  /// The chat's type: `'private'`, `'group'`, `'supergroup'`, or `'channel'`.
  String get type => raw['type'] as String;

  /// The chat's title, for groups/supergroups/channels.
  String? get title => raw['title'] as String?;

  /// The chat's `@username`, if it has a public one.
  String? get username => raw['username'] as String?;

  /// First name of the other party, for private chats.
  String? get firstName => raw['first_name'] as String?;

  /// Last name of the other party, for private chats.
  String? get lastName => raw['last_name'] as String?;

  /// Whether this supergroup is a forum (has topics enabled).
  bool? get isForum => raw['is_forum'] as bool?;

  /// Whether this is a one-on-one chat with a user.
  bool get isPrivate => type == 'private';

  /// Whether this is a basic (non-super) group.
  bool get isGroup => type == 'group';

  /// Whether this is a supergroup.
  bool get isSupergroup => type == 'supergroup';

  /// Whether this is a channel.
  bool get isChannel => type == 'channel';

  @override
  String toString() => 'Chat($id, $type${title != null ? ': $title' : ''})';
}

/// A thin, read-only typed wrapper around a raw Telegram `Message` JSON
/// object — the shape found in `Update.message` and its siblings
/// (`editedMessage`, `channelPost`, `businessMessage`, ...).
///
/// This follows the same philosophy as [Update]'s own getters: scalar
/// fields and the most commonly used nested objects ([from], [chat],
/// [replyToMessage]) are typed, but content types with many different
/// shapes (photos, documents, polls, service messages, ...) are left as raw
/// [Json]/`List<Json>` — pull the fields you need off them directly, the
/// same way you would off [Update.anyMessage]. Construct one from any
/// `Message`-shaped [Json] you already have, e.g. `Message(update.message!)`.
class Message {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Message` JSON object.
  const Message(this.raw);

  /// Unique message identifier inside [chat]. `0` for some scheduled or
  /// ephemeral messages that don't have a real identifier yet.
  int get messageId => raw['message_id'] as int;

  /// If the message is in a forum topic, the identifier of that topic's root message.
  int? get messageThreadId => raw['message_thread_id'] as int?;

  /// The user who sent this message. Missing for messages sent on behalf of
  /// a chat (see [senderChat]) or for anonymous admin posts.
  User? get from => _wrapOrNull(raw['from'], User.new);

  /// The chat on whose behalf this message was sent, for messages sent as a
  /// channel or by an anonymous group admin.
  Chat? get senderChat => _wrapOrNull(raw['sender_chat'], Chat.new);

  /// Unix timestamp of when the message was sent.
  int get date => raw['date'] as int;

  /// The chat this message belongs to.
  Chat get chat => Chat(raw['chat'] as Json);

  /// For replies, the message being replied to (only up to a few levels deep — see the Bot API docs on reply chains).
  Message? get replyToMessage =>
      _wrapOrNull(raw['reply_to_message'], Message.new);

  /// Identifier of the connected Telegram Business account this message
  /// belongs to, if any.
  String? get businessConnectionId => raw['business_connection_id'] as String?;

  /// Unix timestamp of the last edit, if this message was edited.
  int? get editDate => raw['edit_date'] as int?;

  /// Whether the message can't be forwarded or saved.
  bool get hasProtectedContent =>
      raw['has_protected_content'] as bool? ?? false;

  /// The unique identifier of a media message group this message belongs to
  /// (for albums sent via `sendMediaGroup`).
  String? get mediaGroupId => raw['media_group_id'] as String?;

  /// For channel posts, the author's custom signature.
  String? get authorSignature => raw['author_signature'] as String?;

  /// The message's text content, for text messages.
  String? get text => raw['text'] as String?;

  /// Special entities in [text] (bold, links, mentions, ...), as raw JSON.
  List<Json>? get entities => (raw['entities'] as List?)?.cast<Json>();

  /// The caption for media messages (photo, video, document, ...).
  String? get caption => raw['caption'] as String?;

  /// Special entities in [caption], as raw JSON.
  List<Json>? get captionEntities =>
      (raw['caption_entities'] as List?)?.cast<Json>();

  /// Whether the media has a spoiler blur applied.
  bool get hasMediaSpoiler => raw['has_media_spoiler'] as bool? ?? false;

  /// Raw `PhotoSize[]` JSON, if this message has a photo.
  List<Json>? get photo => (raw['photo'] as List?)?.cast<Json>();

  /// Raw `Animation` JSON, if this message has an animation (GIF/H.264 without sound).
  Json? get animation => raw['animation'] as Json?;

  /// Raw `Audio` JSON, if this message has an audio file.
  Json? get audio => raw['audio'] as Json?;

  /// Raw `Document` JSON, if this message has a generic file.
  Json? get document => raw['document'] as Json?;

  /// Raw `Video` JSON, if this message has a video.
  Json? get video => raw['video'] as Json?;

  /// Raw `VideoNote` JSON, if this message has a round "video message".
  Json? get videoNote => raw['video_note'] as Json?;

  /// Raw `Voice` JSON, if this message has a voice note.
  Json? get voice => raw['voice'] as Json?;

  /// Raw `Sticker` JSON, if this message has a sticker.
  Json? get sticker => raw['sticker'] as Json?;

  /// Raw `Story` JSON, if this message forwards a story.
  Json? get story => raw['story'] as Json?;

  /// Raw `Contact` JSON, if this message shares a contact.
  Json? get contact => raw['contact'] as Json?;

  /// Raw `Dice` JSON, if this message is an animated dice/emoji roll.
  Json? get dice => raw['dice'] as Json?;

  /// Raw `Game` JSON, if this message is a game.
  Json? get game => raw['game'] as Json?;

  /// Raw `Poll` JSON, if this message contains a native poll.
  Json? get poll => raw['poll'] as Json?;

  /// Raw `Checklist` JSON, if this message contains a checklist.
  Json? get checklist => raw['checklist'] as Json?;

  /// Raw `Venue` JSON, if this message shares a venue.
  Json? get venue => raw['venue'] as Json?;

  /// Raw `Location` JSON, if this message shares a location.
  Json? get location => raw['location'] as Json?;

  /// Raw `Invoice` JSON, for invoice messages.
  Json? get invoice => raw['invoice'] as Json?;

  /// Raw `SuccessfulPayment` JSON, sent to the bot when a payment completes.
  Json? get successfulPayment => raw['successful_payment'] as Json?;

  /// New members added to the chat, as raw `User[]` JSON.
  List<Json>? get newChatMembers =>
      (raw['new_chat_members'] as List?)?.cast<Json>();

  /// A member that left (or was removed from) the chat, as raw `User` JSON.
  Json? get leftChatMember => raw['left_chat_member'] as Json?;

  /// The chat's new title, for title-change service messages.
  String? get newChatTitle => raw['new_chat_title'] as String?;

  /// The chat's new photo, as raw `PhotoSize[]` JSON, for photo-change
  /// service messages.
  List<Json>? get newChatPhoto =>
      (raw['new_chat_photo'] as List?)?.cast<Json>();

  /// Whether the chat photo was deleted, for that service message.
  bool get deleteChatPhoto => raw['delete_chat_photo'] as bool? ?? false;

  /// The current inline keyboard attached to this message, as raw JSON.
  Json? get replyMarkup => raw['reply_markup'] as Json?;

  /// Raw JSON for Web App data sent via a Mini App's button, if any.
  Json? get webAppData => raw['web_app_data'] as Json?;

  /// The first non-null "this message actually has content" check —
  /// convenient for `if (message.hasContent)` style guards, without
  /// enumerating every possible field yourself.
  bool get hasContent =>
      text != null ||
      photo != null ||
      video != null ||
      document != null ||
      audio != null ||
      voice != null ||
      videoNote != null ||
      sticker != null ||
      animation != null ||
      contact != null ||
      location != null ||
      venue != null ||
      poll != null ||
      dice != null ||
      game != null ||
      invoice != null ||
      successfulPayment != null ||
      checklist != null ||
      story != null;

  @override
  String toString() => 'Message($messageId in ${chat.id})';
}

T? _wrapOrNull<T>(dynamic raw, T Function(Json) wrap) =>
    raw == null ? null : wrap(raw as Json);
