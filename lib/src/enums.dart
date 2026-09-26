/// Controls how Telegram parses formatting syntax (bold, italic, links, ...)
/// inside a message's text or caption.
///
/// Pass one of these to the `parseMode` parameter of methods like
/// [Bot.sendMessage] or [Bot.sendPhoto]. [markdownV2] is the modern,
/// recommended Markdown flavor — [markdown] (legacy Markdown) is kept only
/// for backwards compatibility and has more formatting limitations.
///
/// ```dart
/// await bot.sendMessage(
///   chatId: chatId,
///   text: '*Bold*, _italic_ and a [link](https://example.com)',
///   parseMode: ParseMode.markdownV2,
/// );
///
/// await bot.sendMessage(
///   chatId: chatId,
///   text: '<b>Bold</b> and <a href="https://example.com">a link</a>',
///   parseMode: ParseMode.html,
/// );
/// ```
///
/// Whichever mode you pick, special characters in *user-supplied* text
/// (like a username someone typed) must be escaped by you, or Telegram
/// will reject the message with a `400 Bad Request: can't parse entities`
/// error — see [TelegramApiException]. If you'd rather not deal with
/// escaping at all, either leave [parseMode] unset ([none]) or build the
/// formatting with `entities` instead of markup syntax.
enum ParseMode {
  /// No special formatting — text is sent and displayed as-is. Omits the
  /// `parse_mode` field entirely, so there's nothing to escape.
  none,

  /// Legacy Markdown formatting. Prefer [markdownV2] for new bots — this
  /// mode is kept only so old messages/behavior keep working.
  markdown,

  /// Telegram's modern MarkdownV2 formatting syntax: `*bold*`, `_italic_`,
  /// `` `code` ``, ```` ```pre``` ````, `[text](url)`, `||spoiler||`, etc.
  /// Requires escaping the characters `_ * [ ] ( ) ~ ` > # + - = | { } . !`
  /// wherever they appear as literal text rather than syntax.
  markdownV2,

  /// HTML-flavored formatting (`<b>`, `<i>`, `<a href="...">`,
  /// `<code>`, `<pre>`, `<tg-spoiler>`, etc). Requires escaping `<`, `>`
  /// and `&` as `&lt;`, `&gt;`, `&amp;` wherever they appear as literal
  /// text rather than a tag.
  html;

  /// The literal string Telegram's API expects for this parse mode, or
  /// `null` for [none] (meaning: omit the `parse_mode` field entirely).
  String? get value => switch (this) {
        ParseMode.none => null,
        ParseMode.markdown => 'Markdown',
        ParseMode.markdownV2 => 'MarkdownV2',
        ParseMode.html => 'HTML',
      };
}

/// The status shown to users while a bot is "doing something", via
/// [Bot.sendChatAction] — e.g. the classic "Bot is typing..." indicator.
///
/// The indicator is shown for up to 5 seconds, or until the bot's next
/// message arrives in that chat, whichever is sooner — so for anything
/// that takes longer (like generating an AI reply), re-send the action
/// every ~4 seconds while you work:
///
/// ```dart
/// await bot.sendChatAction(chatId: chatId, action: ChatAction.typing);
/// final reply = await generateSlowReply(prompt); // however long this takes
/// await bot.sendMessage(chatId: chatId, text: reply);
/// ```
///
/// Pick the action that matches what you're about to send —
/// [uploadPhoto] before [Bot.sendPhoto], [recordVoice]/[uploadVoice]
/// before [Bot.sendVoice], and so on — so the indicator the user sees
/// actually matches what shows up next.
enum ChatAction {
  /// Shows "typing...". Use before [Bot.sendMessage].
  typing,

  /// Shows "sending photo...". Use before [Bot.sendPhoto].
  uploadPhoto,

  /// Shows "recording video...". Use before [Bot.sendVideo] if you're
  /// capturing the video live rather than uploading an existing file.
  recordVideo,

  /// Shows "sending video...". Use before [Bot.sendVideo].
  uploadVideo,

  /// Shows "recording voice message...". Use before [Bot.sendVoice] if
  /// you're recording live.
  recordVoice,

  /// Shows "sending voice message...". Use before [Bot.sendVoice].
  uploadVoice,

  /// Shows "sending file...". Use before [Bot.sendDocument].
  uploadDocument,

  /// Shows "choosing a sticker...". Use before [Bot.sendSticker].
  chooseSticker,

  /// Shows "finding location...". Use before [Bot.sendLocation] or
  /// [Bot.sendVenue].
  findLocation,

  /// Shows "recording a video note...". Use before [Bot.sendVideoNote] if
  /// you're recording live.
  recordVideoNote,

  /// Shows "sending a video note...". Use before [Bot.sendVideoNote].
  uploadVideoNote;

  /// The literal string Telegram's API expects for this action.
  String get value => switch (this) {
        ChatAction.typing => 'typing',
        ChatAction.uploadPhoto => 'upload_photo',
        ChatAction.recordVideo => 'record_video',
        ChatAction.uploadVideo => 'upload_video',
        ChatAction.recordVoice => 'record_voice',
        ChatAction.uploadVoice => 'upload_voice',
        ChatAction.uploadDocument => 'upload_document',
        ChatAction.chooseSticker => 'choose_sticker',
        ChatAction.findLocation => 'find_location',
        ChatAction.recordVideoNote => 'record_video_note',
        ChatAction.uploadVideoNote => 'upload_video_note',
      };
}

/// The animated emoji shown by [Bot.sendDice]. Telegram computes the result
/// server-side (the bot cannot choose or predict it) and reports it back
/// in `Message.dice.value` of the sent message — read it right off the
/// return value of [Bot.sendDice]:
///
/// ```dart
/// final sent = await bot.sendDice(chatId: chatId, emoji: DiceEmoji.dice);
/// final rolled = sent.dice!.value; // 1-6, decided by Telegram, not you
/// await bot.sendMessage(chatId: chatId, text: 'You rolled a $rolled!');
/// ```
enum DiceEmoji {
  /// 🎲 A six-sided die. `Message.dice.value` is `1`-`6`.
  dice,

  /// 🎯 A dartboard. `Message.dice.value` is `1`-`6` (6 = bullseye).
  dart,

  /// 🏀 A basketball hoop. `Message.dice.value` is `1`-`5` (4-5 = score).
  basketball,

  /// ⚽ A football/soccer goal. `Message.dice.value` is `1`-`5` (3-5 = goal).
  football,

  /// 🎳 Bowling pins. `Message.dice.value` is `1`-`6` (6 = strike).
  bowling,

  /// 🎰 A slot machine. `Message.dice.value` is `1`-`64`, encoding the
  /// three reels (`64` is the jackpot, three sevens).
  slotMachine;

  /// The literal emoji character Telegram's API expects.
  String get value => switch (this) {
        DiceEmoji.dice => '🎲',
        DiceEmoji.dart => '🎯',
        DiceEmoji.basketball => '🏀',
        DiceEmoji.football => '⚽',
        DiceEmoji.bowling => '🎳',
        DiceEmoji.slotMachine => '🎰',
      };
}

/// Whether a poll sent via [Bot.sendPoll] is a plain vote or a quiz with a
/// single correct answer.
///
/// ```dart
/// // A plain opinion poll — any number of correct answers, or none.
/// await bot.sendPoll(
///   chatId: chatId,
///   question: 'Favorite season?',
///   options: ['Spring', 'Summer', 'Autumn', 'Winter'],
///   type: PollType.regular,
/// );
///
/// // A quiz — exactly one option is graded correct, and voters see
/// // "correct"/"incorrect" feedback immediately after voting.
/// await bot.sendPoll(
///   chatId: chatId,
///   question: 'Capital of France?',
///   options: ['London', 'Paris', 'Berlin'],
///   type: PollType.quiz,
///   correctOptionId: 1,
/// );
/// ```
enum PollType {
  /// A normal poll where options are just opinions (none are "correct").
  /// Optionally set `allowsMultipleAnswers` on [Bot.sendPoll] to let voters
  /// pick more than one option.
  regular,

  /// A quiz poll with exactly one correct option (`correctOptionId` on
  /// [Bot.sendPoll]), revealed to each voter right after they answer.
  quiz;

  /// The literal string Telegram's API expects for this poll type.
  String get value => switch (this) {
        PollType.regular => 'regular',
        PollType.quiz => 'quiz',
      };
}

/// The technical file format of a sticker used with `InputSticker`
/// (see [Bot.addStickerToSet]/[Bot.createNewStickerSet]/[Bot.replaceStickerInSet]).
///
/// Pick the value that matches the file you're uploading — Telegram
/// validates the actual bytes against this, so a mismatch (e.g. uploading
/// a `.webm` but declaring [static]) is rejected with a
/// [TelegramApiException].
enum StickerFormat {
  /// A static `.webp` image, up to 512×512px.
  static,

  /// An animated `.tgs` (Lottie/After Effects) sticker.
  animated,

  /// An animated `.webm` video sticker (VP9, up to 3 seconds, 512×512px).
  video;

  /// The literal string Telegram's API expects (identical to the enum name).
  String get value => name;
}

/// The category a sticker set belongs to, used when creating one with
/// [Bot.createNewStickerSet].
enum StickerType {
  /// A normal sticker, usable directly in chats — the common case.
  regular,

  /// A mask sticker, meant to be overlaid on faces in photos. Each sticker
  /// in the set can carry a `maskPosition` (see [MaskPositionPoint])
  /// telling clients where to anchor it on a detected face.
  mask,

  /// A custom emoji sticker, usable as a custom emoji inside text (see
  /// `MessageEntity`'s `custom_emoji` entities) rather than as a
  /// standalone sticker message.
  customEmoji;

  /// The literal string Telegram's API expects for this sticker type.
  String get value => switch (this) {
        StickerType.regular => 'regular',
        StickerType.mask => 'mask',
        StickerType.customEmoji => 'custom_emoji',
      };
}

/// The facial anchor point a mask sticker (see [StickerType.mask]) is
/// positioned relative to, expressed together with an x/y offset and
/// scale (Telegram's `MaskPosition` object, built alongside this enum
/// wherever a mask sticker's position is set).
enum MaskPositionPoint {
  /// Anchored to the forehead.
  forehead,

  /// Anchored to the eyes.
  eyes,

  /// Anchored to the mouth.
  mouth,

  /// Anchored to the chin.
  chin;

  /// The literal string Telegram's API expects for this anchor point.
  String get value => switch (this) {
        MaskPositionPoint.forehead => 'forehead',
        MaskPositionPoint.eyes => 'eyes',
        MaskPositionPoint.mouth => 'mouth',
        MaskPositionPoint.chin => 'chin',
      };
}
