/// Controls how Telegram parses formatting syntax (bold, italic, links, ...)
/// inside a message's text or caption.
///
/// Pass one of these to the `parseMode` parameter of methods like
/// [Bot.sendMessage] or [Bot.sendPhoto]. [markdownV2] is the modern,
/// recommended Markdown flavor — [markdown] (legacy Markdown) is kept only
/// for backwards compatibility and has more formatting limitations.
enum ParseMode {
  /// No special formatting — text is sent and displayed as-is.
  none,

  /// Legacy Markdown formatting. Prefer [markdownV2] for new bots.
  markdown,

  /// Telegram's modern MarkdownV2 formatting syntax.
  markdownV2,

  /// HTML-flavored formatting (`<b>`, `<i>`, `<a href="...">`, etc).
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
enum ChatAction {
  /// Shows "typing...".
  typing,

  /// Shows "sending photo...".
  uploadPhoto,

  /// Shows "recording video...".
  recordVideo,

  /// Shows "sending video...".
  uploadVideo,

  /// Shows "recording voice message...".
  recordVoice,

  /// Shows "sending voice message...".
  uploadVoice,

  /// Shows "sending file...".
  uploadDocument,

  /// Shows "choosing a sticker...".
  chooseSticker,

  /// Shows "finding location...".
  findLocation,

  /// Shows "recording a video note...".
  recordVideoNote,

  /// Shows "sending a video note...".
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
/// server-side and reports it back in the sent message.
enum DiceEmoji {
  /// 🎲 A six-sided die (values 1-6).
  dice,

  /// 🎯 A dartboard (values 1-6).
  dart,

  /// 🏀 A basketball hoop (values 1-5).
  basketball,

  /// ⚽ A football/soccer goal (values 1-5).
  football,

  /// 🎳 Bowling pins (values 1-6).
  bowling,

  /// 🎰 A slot machine (values 1-64).
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
enum PollType {
  /// A normal poll where options are just opinions (none are "correct").
  regular,

  /// A quiz poll with exactly one correct option, revealed after voting.
  quiz;

  /// The literal string Telegram's API expects for this poll type.
  String get value => switch (this) {
        PollType.regular => 'regular',
        PollType.quiz => 'quiz',
      };
}

/// The technical format of a sticker file used with [InputSticker].
enum StickerFormat {
  /// A static `.webp` image.
  static,

  /// An animated `.tgs` (Lottie) sticker.
  animated,

  /// An animated `.webm` video sticker.
  video;

  /// The literal string Telegram's API expects (identical to the enum name).
  String get value => name;
}

/// The category a sticker set belongs to.
enum StickerType {
  /// A normal sticker, usable directly in chats.
  regular,

  /// A mask sticker, meant to be overlaid on faces in photos.
  mask,

  /// A custom emoji sticker, usable as a custom emoji in text.
  customEmoji;

  /// The literal string Telegram's API expects for this sticker type.
  String get value => switch (this) {
        StickerType.regular => 'regular',
        StickerType.mask => 'mask',
        StickerType.customEmoji => 'custom_emoji',
      };
}

/// The facial anchor point a mask sticker is positioned relative to.
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
