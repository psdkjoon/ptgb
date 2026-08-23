import 'core.dart';

T? _wrapOrNull<T>(dynamic raw, T Function(Json) wrap) =>
    raw == null ? null : wrap(raw as Json);

List<T>? _wrapListOrNull<T>(dynamic raw, T Function(Json) wrap) =>
    (raw as List?)?.cast<Json>().map(wrap).toList();

List<T> _wrapList<T>(dynamic raw, T Function(Json) wrap) =>
    (raw as List? ?? const []).cast<Json>().map(wrap).toList();

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
/// fields like bio, permissions, and invite links on top of these), use
/// [ChatFullInfo] instead — this wrapper only covers the smaller `Chat`
/// shape embedded in messages and updates.
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

/// A photo's size variant, as found in [Message.photo] and various
/// thumbnail fields throughout the API.
class PhotoSize {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `PhotoSize` JSON object.
  const PhotoSize(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// Width in pixels.
  int get width => raw['width'] as int;

  /// Height in pixels.
  int get height => raw['height'] as int;

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;
}

/// A point on the map, as found in [Message.location], live location
/// updates, and inline query locations.
class Location {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Location` JSON object.
  const Location(this.raw);

  /// Longitude.
  double get longitude => (raw['longitude'] as num).toDouble();

  /// Latitude.
  double get latitude => (raw['latitude'] as num).toDouble();

  /// The radius of uncertainty for the location, in meters, if known.
  double? get horizontalAccuracy =>
      (raw['horizontal_accuracy'] as num?)?.toDouble();

  /// Time (seconds) this live location is valid for, if it's a live location.
  int? get livePeriod => raw['live_period'] as int?;

  /// Direction the user is moving in, in degrees, if known.
  int? get heading => raw['heading'] as int?;

  /// Maximum distance (meters) for proximity alerts about this live location.
  int? get proximityAlertRadius => raw['proximity_alert_radius'] as int?;
}

/// A generic file attached to a message, as found in [Message.document].
class Document {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Document` JSON object.
  const Document(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// A thumbnail preview of the file, if available.
  PhotoSize? get thumbnail => _wrapOrNull(raw['thumbnail'], PhotoSize.new);

  /// The original filename, as defined by the sender.
  String? get fileName => raw['file_name'] as String?;

  /// The file's MIME type, as defined by the sender.
  String? get mimeType => raw['mime_type'] as String?;

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;
}

/// A video attached to a message, as found in [Message.video].
class Video {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Video` JSON object.
  const Video(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// Width in pixels.
  int get width => raw['width'] as int;

  /// Height in pixels.
  int get height => raw['height'] as int;

  /// Duration in seconds.
  int get duration => raw['duration'] as int;

  /// A thumbnail preview of the video, if available.
  PhotoSize? get thumbnail => _wrapOrNull(raw['thumbnail'], PhotoSize.new);

  /// The original filename, as defined by the sender.
  String? get fileName => raw['file_name'] as String?;

  /// The file's MIME type, as defined by the sender.
  String? get mimeType => raw['mime_type'] as String?;

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;
}

/// An audio file attached to a message, as found in [Message.audio].
class Audio {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Audio` JSON object.
  const Audio(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// Duration in seconds.
  int get duration => raw['duration'] as int;

  /// Performer/artist name, as defined by the sender or file metadata.
  String? get performer => raw['performer'] as String?;

  /// Track title, as defined by the sender or file metadata.
  String? get title => raw['title'] as String?;

  /// The original filename, as defined by the sender.
  String? get fileName => raw['file_name'] as String?;

  /// The file's MIME type, as defined by the sender.
  String? get mimeType => raw['mime_type'] as String?;

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;

  /// The album art thumbnail, if available.
  PhotoSize? get thumbnail => _wrapOrNull(raw['thumbnail'], PhotoSize.new);
}

/// A voice message attached to a message, as found in [Message.voice].
class Voice {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Voice` JSON object.
  const Voice(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// Duration in seconds.
  int get duration => raw['duration'] as int;

  /// The file's MIME type, as defined by the sender.
  String? get mimeType => raw['mime_type'] as String?;

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;
}

/// A GIF or silent, looping H.264/MPEG-4 animation, as found in
/// [Message.animation].
class Animation {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Animation` JSON object.
  const Animation(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// Width in pixels.
  int get width => raw['width'] as int;

  /// Height in pixels.
  int get height => raw['height'] as int;

  /// Duration in seconds.
  int get duration => raw['duration'] as int;

  /// A thumbnail preview of the animation, if available.
  PhotoSize? get thumbnail => _wrapOrNull(raw['thumbnail'], PhotoSize.new);

  /// The original filename, as defined by the sender.
  String? get fileName => raw['file_name'] as String?;

  /// The file's MIME type, as defined by the sender.
  String? get mimeType => raw['mime_type'] as String?;

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;
}

/// A round "video message" bubble, as found in [Message.videoNote].
class VideoNote {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `VideoNote` JSON object.
  const VideoNote(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// Video width and height (video notes are always square).
  int get length => raw['length'] as int;

  /// Duration in seconds.
  int get duration => raw['duration'] as int;

  /// A thumbnail preview of the video note, if available.
  PhotoSize? get thumbnail => _wrapOrNull(raw['thumbnail'], PhotoSize.new);

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;
}

/// A shared phone contact, as found in [Message.contact].
class Contact {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Contact` JSON object.
  const Contact(this.raw);

  /// The contact's phone number.
  String get phoneNumber => raw['phone_number'] as String;

  /// The contact's first name.
  String get firstName => raw['first_name'] as String;

  /// The contact's last name, if set.
  String? get lastName => raw['last_name'] as String?;

  /// The contact's Telegram user ID, if they have an account.
  int? get userId => raw['user_id'] as int?;

  /// The contact's vCard, if attached.
  String? get vcard => raw['vcard'] as String?;
}

/// A shared venue (a location plus a name/address), as found in
/// [Message.venue].
class Venue {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Venue` JSON object.
  const Venue(this.raw);

  /// The venue's location.
  Location get location => Location(raw['location'] as Json);

  /// The venue's name.
  String get title => raw['title'] as String;

  /// The venue's address.
  String get address => raw['address'] as String;

  /// Foursquare identifier of the venue, if known.
  String? get foursquareId => raw['foursquare_id'] as String?;

  /// Foursquare type of the venue, if known (e.g. `'arts_entertainment/default'`).
  String? get foursquareType => raw['foursquare_type'] as String?;

  /// Google Places identifier of the venue, if known.
  String? get googlePlaceId => raw['google_place_id'] as String?;

  /// Google Places type of the venue, if known.
  String? get googlePlaceType => raw['google_place_type'] as String?;
}

/// A single option within a [Poll].
class PollOption {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `PollOption` JSON object.
  const PollOption(this.raw);

  /// The option's label text.
  String get text => raw['text'] as String;

  /// How many voters chose this option.
  int get voterCount => raw['voter_count'] as int;

  /// Special entities in [text], as raw JSON.
  List<Json>? get textEntities => (raw['text_entities'] as List?)?.cast<Json>();
}

/// A native poll or quiz, as found in [Message.poll], `Update.poll`, and
/// returned by `Bot.stopPoll`.
class Poll {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Poll` JSON object.
  const Poll(this.raw);

  /// Unique poll identifier.
  String get id => raw['id'] as String;

  /// The poll's question text.
  String get question => raw['question'] as String;

  /// The poll's answer options.
  List<PollOption> get options => _wrapList(raw['options'], PollOption.new);

  /// Total number of users who voted.
  int get totalVoterCount => raw['total_voter_count'] as int;

  /// Whether the poll has been closed and no longer accepts votes.
  bool get isClosed => raw['is_closed'] as bool;

  /// Whether votes are anonymous.
  bool get isAnonymous => raw['is_anonymous'] as bool;

  /// `'regular'` or `'quiz'`.
  String get type => raw['type'] as String;

  /// Whether voters may pick more than one option.
  bool get allowsMultipleAnswers => raw['allows_multiple_answers'] as bool;

  /// For quiz polls, the 0-based index of the correct option, once revealed.
  int? get correctOptionId => raw['correct_option_id'] as int?;

  /// For quiz polls, the explanation shown after a voter answers.
  String? get explanation => raw['explanation'] as String?;

  /// Special entities in [explanation], as raw JSON.
  List<Json>? get explanationEntities =>
      (raw['explanation_entities'] as List?)?.cast<Json>();

  /// How many seconds the poll stays open for, if timed.
  int? get openPeriod => raw['open_period'] as int?;

  /// Unix timestamp of when the poll auto-closes, if timed.
  int? get closeDate => raw['close_date'] as int?;
}

/// A sticker, as found in [Message.sticker] and returned within
/// `StickerSet.stickers`.
class Sticker {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Sticker` JSON object.
  const Sticker(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// `'regular'`, `'mask'`, or `'custom_emoji'`.
  String get type => raw['type'] as String;

  /// Width in pixels.
  int get width => raw['width'] as int;

  /// Height in pixels.
  int get height => raw['height'] as int;

  /// Whether this is an animated (`.tgs`) sticker.
  bool get isAnimated => raw['is_animated'] as bool;

  /// Whether this is a video (`.webm`) sticker.
  bool get isVideo => raw['is_video'] as bool;

  /// A static thumbnail preview, if available.
  PhotoSize? get thumbnail => _wrapOrNull(raw['thumbnail'], PhotoSize.new);

  /// The emoji this sticker is associated with, if any.
  String? get emoji => raw['emoji'] as String?;

  /// The name of the sticker set this sticker belongs to, if any.
  String? get setName => raw['set_name'] as String?;

  /// Facial anchor position, for mask stickers, as raw JSON.
  Json? get maskPosition => raw['mask_position'] as Json?;

  /// Unique identifier of the custom emoji, for custom-emoji stickers.
  String? get customEmojiId => raw['custom_emoji_id'] as String?;

  /// Whether this custom-emoji sticker should be repainted to match text
  /// color, as with regular emoji.
  bool? get needsRepainting => raw['needs_repainting'] as bool?;

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;
}

/// A shipping address, as found in [ShippingQuery.shippingAddress] and
/// [OrderInfo.shippingAddress].
class ShippingAddress {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ShippingAddress` JSON object.
  const ShippingAddress(this.raw);

  /// Two-letter ISO 3166-1 alpha-2 country code.
  String get countryCode => raw['country_code'] as String;

  /// State, if applicable.
  String get state => raw['state'] as String;

  /// City.
  String get city => raw['city'] as String;

  /// First line of the address.
  String get streetLine1 => raw['street_line1'] as String;

  /// Second line of the address.
  String get streetLine2 => raw['street_line2'] as String;

  /// Postal/ZIP code.
  String get postCode => raw['post_code'] as String;
}

/// The order information a payer supplied, as found in
/// [PreCheckoutQuery.orderInfo] and [SuccessfulPayment.orderInfo].
class OrderInfo {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `OrderInfo` JSON object.
  const OrderInfo(this.raw);

  /// The payer's full name, if requested.
  String? get name => raw['name'] as String?;

  /// The payer's phone number, if requested.
  String? get phoneNumber => raw['phone_number'] as String?;

  /// The payer's email, if requested.
  String? get email => raw['email'] as String?;

  /// The payer's shipping address, if requested.
  ShippingAddress? get shippingAddress =>
      _wrapOrNull(raw['shipping_address'], ShippingAddress.new);
}

/// A completed invoice payment, as found in [Message.successfulPayment].
class SuccessfulPayment {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `SuccessfulPayment` JSON object.
  const SuccessfulPayment(this.raw);

  /// Three-letter ISO 4217 currency code, or `'XTR'` for Telegram Stars.
  String get currency => raw['currency'] as String;

  /// Total price in the smallest units of [currency].
  int get totalAmount => raw['total_amount'] as int;

  /// The bot-defined invoice payload.
  String get invoicePayload => raw['invoice_payload'] as String;

  /// Expiration date of the subscription this payment is for, if any.
  int? get subscriptionExpirationDate =>
      raw['subscription_expiration_date'] as int?;

  /// Whether this is a subscription payment.
  bool? get isRecurring => raw['is_recurring'] as bool?;

  /// Whether this is the first payment for a subscription.
  bool? get isFirstRecurring => raw['is_first_recurring'] as bool?;

  /// Identifier of the chosen shipping option, if applicable.
  String? get shippingOptionId => raw['shipping_option_id'] as String?;

  /// The order information supplied by the payer, if requested.
  OrderInfo? get orderInfo => _wrapOrNull(raw['order_info'], OrderInfo.new);

  /// Telegram's identifier for this payment.
  String get telegramPaymentChargeId =>
      raw['telegram_payment_charge_id'] as String;

  /// The payment provider's identifier for this payment.
  String get providerPaymentChargeId =>
      raw['provider_payment_charge_id'] as String;
}

/// Details of an invoice, as found in [Message.invoice].
class Invoice {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Invoice` JSON object.
  const Invoice(this.raw);

  /// The invoice's title.
  String get title => raw['title'] as String;

  /// The invoice's description.
  String get description => raw['description'] as String;

  /// A bot-defined start parameter usable to generate this invoice again.
  String get startParameter => raw['start_parameter'] as String;

  /// Three-letter ISO 4217 currency code, or `'XTR'` for Telegram Stars.
  String get currency => raw['currency'] as String;

  /// Total price in the smallest units of [currency].
  int get totalAmount => raw['total_amount'] as int;
}

/// The result of an animated dice/emoji roll, as found in [Message.dice].
class Dice {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Dice` JSON object.
  const Dice(this.raw);

  /// The emoji used for the roll (e.g. `'🎲'`).
  String get emoji => raw['emoji'] as String;

  /// The rolled value. Range depends on [emoji]; see [DiceEmoji].
  int get value => raw['value'] as int;
}

/// A Telegram Game, as found in [Message.game].
class Game {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Game` JSON object.
  const Game(this.raw);

  /// The game's title.
  String get title => raw['title'] as String;

  /// The game's description.
  String get description => raw['description'] as String;

  /// Photos shown on the game's info page.
  List<PhotoSize> get photo => _wrapList(raw['photo'], PhotoSize.new);

  /// A short in-game description or high-score text, if any.
  String? get text => raw['text'] as String?;

  /// Special entities in [text], as raw JSON.
  List<Json>? get textEntities => (raw['text_entities'] as List?)?.cast<Json>();

  /// An animation demonstrating the game, if any.
  Animation? get animation => _wrapOrNull(raw['animation'], Animation.new);
}

/// Data sent to the bot by a Web App via its button's `web_app` field, as
/// found in [Message.webAppData].
class WebAppData {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `WebAppData` JSON object.
  const WebAppData(this.raw);

  /// The data, as passed by `Telegram.WebApp.sendData` in the Mini App.
  String get data => raw['data'] as String;

  /// The text of the `web_app` keyboard button, for context.
  String get buttonText => raw['button_text'] as String;
}

/// Just a message's identifier, returned by `Bot.copyMessage`.
class MessageId {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `MessageId` JSON object.
  const MessageId(this.raw);

  /// The copied message's new identifier in the destination chat.
  int get messageId => raw['message_id'] as int;

  @override
  String toString() => 'MessageId($messageId)';
}

/// A forum topic, as returned by `Bot.createForumTopic`.
class ForumTopic {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ForumTopic` JSON object.
  const ForumTopic(this.raw);

  /// Identifier of the topic's root message, used as `messageThreadId`
  /// elsewhere in the API.
  int get messageThreadId => raw['message_thread_id'] as int;

  /// The topic's name.
  String get name => raw['name'] as String;

  /// The topic icon's color, as an RGB integer.
  int get iconColor => raw['icon_color'] as int;

  /// Unique identifier of the topic icon's custom emoji, if set.
  String? get iconCustomEmojiId => raw['icon_custom_emoji_id'] as String?;
}

/// One of the bot's registered `/` commands, as returned by `Bot.getMyCommands`.
class BotCommand {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `BotCommand` JSON object.
  const BotCommand(this.raw);

  /// The command text, without the leading `/`.
  String get command => raw['command'] as String;

  /// The command's description, shown in clients' command menus.
  String get description => raw['description'] as String;
}

/// A thin, read-only typed wrapper around a raw Telegram `Message` JSON
/// object — the shape found in `Update.message` and its siblings
/// (`editedMessage`, `channelPost`, `businessMessage`, ...).
///
/// This follows the same philosophy as [Update]'s own getters: scalar
/// fields and the most commonly used nested objects ([from], [chat],
/// [replyToMessage]) are typed, and every content type (photos, documents,
/// polls, service messages, ...) is now typed as well — the same way you'd
/// use [Update]'s own shortcuts. Construct one from any `Message`-shaped
/// [Json] you already have, e.g. `Message(update.message!)`.
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

  /// The available sizes of this message's photo, if any.
  List<PhotoSize>? get photo => _wrapListOrNull(raw['photo'], PhotoSize.new);

  /// This message's animation (GIF/H.264 without sound), if any.
  Animation? get animation => _wrapOrNull(raw['animation'], Animation.new);

  /// This message's audio file, if any.
  Audio? get audio => _wrapOrNull(raw['audio'], Audio.new);

  /// This message's generic file, if any.
  Document? get document => _wrapOrNull(raw['document'], Document.new);

  /// This message's video, if any.
  Video? get video => _wrapOrNull(raw['video'], Video.new);

  /// This message's round "video message", if any.
  VideoNote? get videoNote => _wrapOrNull(raw['video_note'], VideoNote.new);

  /// This message's voice note, if any.
  Voice? get voice => _wrapOrNull(raw['voice'], Voice.new);

  /// This message's sticker, if any.
  Sticker? get sticker => _wrapOrNull(raw['sticker'], Sticker.new);

  /// Raw `Story` JSON, if this message forwards a story.
  Json? get story => raw['story'] as Json?;

  /// This message's shared contact, if any.
  Contact? get contact => _wrapOrNull(raw['contact'], Contact.new);

  /// This message's animated dice/emoji roll, if any.
  Dice? get dice => _wrapOrNull(raw['dice'], Dice.new);

  /// This message's game, if any.
  Game? get game => _wrapOrNull(raw['game'], Game.new);

  /// This message's native poll, if any.
  Poll? get poll => _wrapOrNull(raw['poll'], Poll.new);

  /// This message's checklist, as raw JSON, if any.
  Json? get checklist => raw['checklist'] as Json?;

  /// This message's shared venue, if any.
  Venue? get venue => _wrapOrNull(raw['venue'], Venue.new);

  /// This message's shared location, if any.
  Location? get location => _wrapOrNull(raw['location'], Location.new);

  /// This message's invoice, for invoice messages.
  Invoice? get invoice => _wrapOrNull(raw['invoice'], Invoice.new);

  /// The completed payment, sent to the bot when a payment finishes.
  SuccessfulPayment? get successfulPayment =>
      _wrapOrNull(raw['successful_payment'], SuccessfulPayment.new);

  /// New members added to the chat.
  List<User>? get newChatMembers =>
      _wrapListOrNull(raw['new_chat_members'], User.new);

  /// A member that left (or was removed from) the chat.
  User? get leftChatMember => _wrapOrNull(raw['left_chat_member'], User.new);

  /// The chat's new title, for title-change service messages.
  String? get newChatTitle => raw['new_chat_title'] as String?;

  /// The chat's new photo, for photo-change service messages.
  List<PhotoSize>? get newChatPhoto =>
      _wrapListOrNull(raw['new_chat_photo'], PhotoSize.new);

  /// Whether the chat photo was deleted, for that service message.
  bool get deleteChatPhoto => raw['delete_chat_photo'] as bool? ?? false;

  /// The current inline keyboard attached to this message, as raw JSON.
  Json? get replyMarkup => raw['reply_markup'] as Json?;

  /// Data sent for Web App button presses, if any.
  WebAppData? get webAppData =>
      _wrapOrNull(raw['web_app_data'], WebAppData.new);

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

/// A single entry on a game's leaderboard, as found in the list returned by
/// `Bot.getGameHighScores`.
class GameHighScore {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `GameHighScore` JSON object.
  const GameHighScore(this.raw);

  /// This player's position on the leaderboard.
  int get position => raw['position'] as int;

  /// The player this score belongs to.
  User get user => User(raw['user'] as Json);

  /// The player's score.
  int get score => raw['score'] as int;

  @override
  String toString() => 'GameHighScore(#$position ${user.fullName}: $score)';
}

// ---------------------------------------------------------------------------
// Bot method response types
// ---------------------------------------------------------------------------

/// The current webhook status, as returned by `Bot.getWebhookInfo`.
class WebhookInfo {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `WebhookInfo` JSON object.
  const WebhookInfo(this.raw);

  /// The configured webhook URL, empty if webhooks are disabled.
  String get url => raw['url'] as String;

  /// Whether a self-signed certificate was uploaded for this webhook.
  bool get hasCustomCertificate => raw['has_custom_certificate'] as bool;

  /// Number of updates awaiting delivery.
  int get pendingUpdateCount => raw['pending_update_count'] as int;

  /// The currently used webhook IP address, if known.
  String? get ipAddress => raw['ip_address'] as String?;

  /// Unix timestamp of the most recent delivery error, if any.
  int? get lastErrorDate => raw['last_error_date'] as int?;

  /// A human-readable description of the most recent delivery error, if any.
  String? get lastErrorMessage => raw['last_error_message'] as String?;

  /// Unix timestamp of the most recent internal server synchronization error, if any.
  int? get lastSynchronizationErrorDate =>
      raw['last_synchronization_error_date'] as int?;

  /// The configured maximum number of simultaneous webhook connections, if set.
  int? get maxConnections => raw['max_connections'] as int?;

  /// The update types this webhook is subscribed to, if restricted.
  List<String>? get allowedUpdates =>
      (raw['allowed_updates'] as List?)?.cast<String>();
}

/// A page of a user's profile photos, as returned by `Bot.getUserProfilePhotos`.
class UserProfilePhotos {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `UserProfilePhotos` JSON object.
  const UserProfilePhotos(this.raw);

  /// Total number of profile photos the target user has.
  int get totalCount => raw['total_count'] as int;

  /// The requested photos, each as a list of available sizes.
  List<List<PhotoSize>> get photos => (raw['photos'] as List)
      .map((sizes) => _wrapList<PhotoSize>(sizes, PhotoSize.new))
      .toList();
}

/// A file's download location, as returned by `Bot.getFile`. Named
/// `TelegramFile` (rather than `File`) to avoid clashing with `dart:io`'s
/// [File].
class TelegramFile {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `File` JSON object.
  const TelegramFile(this.raw);

  /// Identifier usable to download or resend this specific file.
  String get fileId => raw['file_id'] as String;

  /// Identifier that's consistent across bots for the same file content.
  String get fileUniqueId => raw['file_unique_id'] as String;

  /// File size in bytes, if known.
  int? get fileSize => raw['file_size'] as int?;

  /// The path usable with [Bot.downloadFile] or the file base URL, valid
  /// for at least an hour after this response.
  String? get filePath => raw['file_path'] as String?;
}

/// An additional (non-primary) chat invite link, as returned by
/// `Bot.createChatInviteLink` and friends.
class ChatInviteLink {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChatInviteLink` JSON object.
  const ChatInviteLink(this.raw);

  /// The invite link itself.
  String get inviteLink => raw['invite_link'] as String;

  /// The admin who created this link.
  User get creator => User(raw['creator'] as Json);

  /// Whether joins via this link must be approved by an admin.
  bool get createsJoinRequest => raw['creates_join_request'] as bool;

  /// Whether this is the chat's primary invite link.
  bool get isPrimary => raw['is_primary'] as bool;

  /// Whether this link has been revoked.
  bool get isRevoked => raw['is_revoked'] as bool;

  /// A friendly name for this link, if set.
  String? get name => raw['name'] as String?;

  /// Unix timestamp when this link expires, if set.
  int? get expireDate => raw['expire_date'] as int?;

  /// Maximum number of users that can join via this link, if limited.
  int? get memberLimit => raw['member_limit'] as int?;

  /// Number of join requests awaiting approval via this link, if any.
  int? get pendingJoinRequestCount => raw['pending_join_request_count'] as int?;

  /// The Telegram Stars subscription period this link charges for, if it's a subscription link.
  int? get subscriptionPeriod => raw['subscription_period'] as int?;

  /// The Telegram Stars price of the subscription, if it's a subscription link.
  int? get subscriptionPrice => raw['subscription_price'] as int?;
}

/// The full details of a chat, as returned by `Bot.getChat`. Richer than
/// the [Chat] shape embedded in messages and updates.
class ChatFullInfo {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChatFullInfo` JSON object.
  const ChatFullInfo(this.raw);

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

  /// The chat's photo, if set, as raw JSON (`small_file_id`/`big_file_id` pairs).
  Json? get photo => raw['photo'] as Json?;

  /// The chat's bio, for private chats.
  String? get bio => raw['bio'] as String?;

  /// The chat's description, for groups/supergroups/channels.
  String? get description => raw['description'] as String?;

  /// The chat's primary invite link, if the bot is an admin with access to it.
  String? get inviteLink => raw['invite_link'] as String?;

  /// Default permissions for non-admin members, for groups/supergroups.
  Json? get permissions => raw['permissions'] as Json?;

  /// Whether joining this chat requires admin approval.
  bool? get joinToSendMessages => raw['join_to_send_messages'] as bool?;

  /// Whether users must request to join.
  bool? get joinByRequest => raw['join_by_request'] as bool?;

  @override
  String toString() =>
      'ChatFullInfo($id, $type${title != null ? ': $title' : ''})';
}

/// A chat member's status and permissions, as returned by
/// `Bot.getChatMember`/`Bot.getChatAdministrators` and found in
/// [ChatMemberUpdated.oldChatMember]/[ChatMemberUpdated.newChatMember].
///
/// The exact set of extra fields present depends on [status] (Telegram
/// models this as a union of several `ChatMember*` shapes) — [raw] gives
/// you access to whichever ones apply.
class ChatMember {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChatMember` JSON object.
  const ChatMember(this.raw);

  /// One of `'creator'`, `'administrator'`, `'member'`, `'restricted'`,
  /// `'left'`, or `'kicked'`.
  String get status => raw['status'] as String;

  /// The member this status applies to.
  User get user => User(raw['user'] as Json);

  /// Whether the user's presence in the chat is hidden (owner/admin only).
  bool? get isAnonymous => raw['is_anonymous'] as bool?;

  /// A custom title shown instead of "Owner"/"Admin", if set.
  String? get customTitle => raw['custom_title'] as String?;

  /// Unix timestamp until which the restriction/ban applies, for restricted/kicked members.
  int? get untilDate => raw['until_date'] as int?;

  /// Whether this admin can be demoted/edited by the bot.
  bool? get canBeEdited => raw['can_be_edited'] as bool?;

  /// Whether this member is a member of the chat at all (`false` for restricted-but-not-in-chat).
  bool? get isMember => raw['is_member'] as bool?;
}

/// The bot's display name, as returned by `Bot.getMyName`.
class BotName {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `BotName` JSON object.
  const BotName(this.raw);

  /// The bot's display name.
  String get name => raw['name'] as String;
}

/// The bot's profile description, as returned by `Bot.getMyDescription`.
class BotDescription {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `BotDescription` JSON object.
  const BotDescription(this.raw);

  /// The bot's profile description.
  String get description => raw['description'] as String;
}

/// The bot's short description, as returned by `Bot.getMyShortDescription`.
class BotShortDescription {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `BotShortDescription` JSON object.
  const BotShortDescription(this.raw);

  /// The bot's short description.
  String get shortDescription => raw['short_description'] as String;
}

/// The menu button configured for a chat, as returned by `Bot.getChatMenuButton`.
class MenuButton {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `MenuButton` JSON object.
  const MenuButton(this.raw);

  /// One of `'default'`, `'commands'`, or `'web_app'`.
  String get type => raw['type'] as String;

  /// The button's label, for `'web_app'` buttons.
  String? get text => raw['text'] as String?;

  /// The Web App this button opens, as raw JSON, for `'web_app'` buttons.
  Json? get webApp => raw['web_app'] as Json?;
}

/// Confirms an inline query answer was delivered to a Web App, as returned
/// by `Bot.answerWebAppQuery`.
class SentWebAppMessage {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `SentWebAppMessage` JSON object.
  const SentWebAppMessage(this.raw);

  /// Identifier of the sent inline message, if it has one.
  String? get inlineMessageId => raw['inline_message_id'] as String?;
}

/// A pre-uploaded inline message result, as returned by
/// `Bot.savePreparedInlineMessage`/`Bot.savePreparedKeyboardButton`.
class PreparedInlineMessage {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `PreparedInlineMessage` JSON object.
  const PreparedInlineMessage(this.raw);

  /// Identifier of the prepared message, usable in `sendPreparedMessage`.
  String get id => raw['id'] as String;

  /// Unix timestamp after which this prepared message expires.
  int get expirationDate => raw['expiration_date'] as int;
}

/// A single Telegram Stars transaction, as found in [StarTransactions.transactions].
class StarTransaction {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `StarTransaction` JSON object.
  const StarTransaction(this.raw);

  /// Unique identifier of the transaction.
  String get id => raw['id'] as String;

  /// Integer amount of Telegram Stars transferred (positive for incoming).
  int get amount => raw['amount'] as int;

  /// The nanostar (10^-9 star) component of [amount], if any.
  int? get nanostarAmount => raw['nanostar_amount'] as int?;

  /// Unix timestamp of the transaction.
  int get date => raw['date'] as int;

  /// The counterparty that sent the Stars, as raw JSON, for incoming transactions.
  Json? get source => raw['source'] as Json?;

  /// The counterparty that received the Stars, as raw JSON, for outgoing transactions.
  Json? get receiver => raw['receiver'] as Json?;
}

/// A page of the bot's Telegram Stars transaction history, as returned by
/// `Bot.getStarTransactions`.
class StarTransactions {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `StarTransactions` JSON object.
  const StarTransactions(this.raw);

  /// The transactions in this page.
  List<StarTransaction> get transactions =>
      _wrapList(raw['transactions'], StarTransaction.new);
}

/// A named sticker set and its stickers, as returned by `Bot.getStickerSet`.
class StickerSet {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `StickerSet` JSON object.
  const StickerSet(this.raw);

  /// The set's unique name (as registered with @BotFather).
  String get name => raw['name'] as String;

  /// The set's display title.
  String get title => raw['title'] as String;

  /// `'regular'`, `'mask'`, or `'custom_emoji'`.
  String get stickerType => raw['sticker_type'] as String;

  /// Every sticker in the set.
  List<Sticker> get stickers => _wrapList(raw['stickers'], Sticker.new);

  /// The set's thumbnail, if any.
  PhotoSize? get thumbnail => _wrapOrNull(raw['thumbnail'], PhotoSize.new);
}

/// A single boost applied to a chat, as found in [UserChatBoosts.boosts]
/// and [ChatBoostUpdated.boost].
class ChatBoost {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `ChatBoost` JSON object.
  const ChatBoost(this.raw);

  /// Unique identifier of this boost.
  String get boostId => raw['boost_id'] as String;

  /// Unix timestamp the boost was added.
  int get addDate => raw['add_date'] as int;

  /// Unix timestamp the boost will expire, unless renewed.
  int get expirationDate => raw['expiration_date'] as int;

  /// How the boost was obtained, as raw JSON (`'premium'`, `'gift_code'`, or `'giveaway'` source).
  Json get source => raw['source'] as Json;
}

/// The boosts a user has applied to a chat, as returned by `Bot.getUserChatBoosts`.
class UserChatBoosts {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `UserChatBoosts` JSON object.
  const UserChatBoosts(this.raw);

  /// The user's boosts applied to the chat.
  List<ChatBoost> get boosts => _wrapList(raw['boosts'], ChatBoost.new);
}

/// A precise Telegram Stars amount, as returned by `Bot.getMyStarBalance`
/// and `Bot.getBusinessAccountStarBalance`.
class StarAmount {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `StarAmount` JSON object.
  const StarAmount(this.raw);

  /// Integer amount of Telegram Stars.
  int get amount => raw['amount'] as int;

  /// The nanostar (10^-9 star) component of [amount], if any.
  int? get nanostarAmount => raw['nanostar_amount'] as int?;
}

/// A gift owned by a user or business account, as found in [OwnedGifts.gifts].
class OwnedGift {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `OwnedGift` JSON object.
  const OwnedGift(this.raw);

  /// `'regular'` or `'unique'`.
  String get type => raw['type'] as String;

  /// Unique identifier of this specific owned gift instance, usable with
  /// gift-management methods, if it can still be managed.
  String? get ownedGiftId => raw['owned_gift_id'] as String?;

  /// The user who sent the gift, if not anonymous.
  User? get senderUser => _wrapOrNull(raw['sender_user'], User.new);

  /// Unix timestamp the gift was sent.
  int? get sendDate => raw['send_date'] as int?;

  /// A message attached to the gift, if any.
  String? get text => raw['text'] as String?;

  /// Whether the gift is displayed publicly on the owner's profile.
  bool? get isPrivate => raw['is_private'] as bool?;

  /// Whether the gift is saved to the owner's profile.
  bool? get isSaved => raw['is_saved'] as bool?;

  /// Whether the gift can be upgraded to a unique gift.
  bool? get canBeUpgraded => raw['can_be_upgraded'] as bool?;

  /// Whether the gift was refunded.
  bool? get wasRefunded => raw['was_refunded'] as bool?;

  /// The Telegram Stars value if converted, for regular gifts.
  int? get convertStarCount => raw['convert_star_count'] as int?;

  /// The Telegram Stars cost of upgrading this gift, if prepaid.
  int? get prepaidUpgradeStarCount => raw['prepaid_upgrade_star_count'] as int?;
}

/// A page of gifts owned by a user or business account, as returned by
/// `Bot.getBusinessAccountGifts`/`Bot.getUserGifts`/`Bot.getChatGifts`.
class OwnedGifts {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `OwnedGifts` JSON object.
  const OwnedGifts(this.raw);

  /// Total number of gifts owned.
  int get totalCount => raw['total_count'] as int;

  /// The requested page of gifts.
  List<OwnedGift> get gifts => _wrapList(raw['gifts'], OwnedGift.new);

  /// A cursor to request the next page with, if there is one.
  String? get nextOffset => raw['next_offset'] as String?;
}

/// A gift available for anyone to purchase and send, as found in [Gifts.gifts].
class Gift {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Gift` JSON object.
  const Gift(this.raw);

  /// Unique identifier of this gift.
  String get id => raw['id'] as String;

  /// The sticker shown for this gift.
  Sticker get sticker => Sticker(raw['sticker'] as Json);

  /// The Telegram Stars price to buy this gift.
  int get starCount => raw['star_count'] as int;

  /// The Telegram Stars price to upgrade this gift to a unique one, if upgradable.
  int? get upgradeStarCount => raw['upgrade_star_count'] as int?;

  /// Total number of this gift that can ever be sent, for limited gifts.
  int? get totalCount => raw['total_count'] as int?;

  /// Number of this gift still available to send, for limited gifts.
  int? get remainingCount => raw['remaining_count'] as int?;
}

/// The catalog of gifts purchasable to send, as returned by `Bot.getAvailableGifts`.
class Gifts {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Gifts` JSON object.
  const Gifts(this.raw);

  /// The available gifts.
  List<Gift> get gifts => _wrapList(raw['gifts'], Gift.new);
}

/// A Telegram Story, as returned by `Bot.postStory`/`Bot.editStory`/`Bot.repostStory`.
class Story {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `Story` JSON object.
  const Story(this.raw);

  /// The chat that posted the story.
  Chat get chat => Chat(raw['chat'] as Json);

  /// Unique identifier of the story within [chat].
  int get id => raw['id'] as int;
}

/// The audio files a user has added to their profile, as returned by
/// `Bot.getUserProfileAudios`.
class UserProfileAudios {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw `UserProfileAudios` JSON object.
  const UserProfileAudios(this.raw);

  /// Total number of profile audios the target user has.
  int get totalCount => raw['total_count'] as int;

  /// The requested audios, as raw JSON.
  List<Json> get audios => (raw['audios'] as List? ?? const []).cast<Json>();
}
