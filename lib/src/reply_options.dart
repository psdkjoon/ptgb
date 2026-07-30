import 'core.dart';
import 'enums.dart';

/// Controls how the automatic link preview attached to a text message
/// behaves, passed to [Bot.sendMessage]'s `linkPreviewOptions`.
class LinkPreviewOptions {
  /// Disables the link preview entirely.
  final bool? isDisabled;

  /// Shows a preview for this specific URL instead of the first link found in the text.
  final String? url;

  /// Shrinks the preview's media, when there's a choice of preview sizes.
  final bool? preferSmallMedia;

  /// Enlarges the preview's media, when there's a choice of preview sizes.
  final bool? preferLargeMedia;

  /// Shows the preview above the message text instead of below it.
  final bool? showAboveText;

  /// Creates link preview options. Leave a field `null` to use Telegram's default behavior.
  const LinkPreviewOptions({
    this.isDisabled,
    this.url,
    this.preferSmallMedia,
    this.preferLargeMedia,
    this.showAboveText,
  });

  /// Shortcut that disables the link preview entirely.
  factory LinkPreviewOptions.disabled() => const LinkPreviewOptions(isDisabled: true);

  /// Converts these options to the JSON shape Telegram's API expects.
  Json toJson() => {
        if (isDisabled != null) 'is_disabled': isDisabled,
        if (url != null) 'url': url,
        if (preferSmallMedia != null) 'prefer_small_media': preferSmallMedia,
        if (preferLargeMedia != null) 'prefer_large_media': preferLargeMedia,
        if (showAboveText != null) 'show_above_text': showAboveText,
      };
}

/// Describes the message a new message is replying to, passed to
/// `sendMessage`/`sendPhoto`/etc's `replyParameters`.
///
/// More flexible than the plain `replyToMessageId` shortcut: it also
/// supports replying across chats via [chatId] and quoting a specific
/// [quote] excerpt of the original message.
class ReplyParameters {
  /// The ID of the message being replied to.
  final int messageId;

  /// The chat the replied-to message is in, if different from the chat the
  /// reply is being sent to (e.g. replying to a message forwarded from
  /// another chat).
  final Object? chatId;

  /// If the replied-to message doesn't exist, send anyway as a normal message instead of failing.
  final bool? allowSendingWithoutReply;

  /// A specific excerpt of the original message to quote, instead of quoting the whole thing.
  final String? quote;

  /// The parse mode applied to [quote].
  final ParseMode? quoteParseMode;

  /// Special entities (bold, links, etc) within [quote].
  final List<Json>? quoteEntities;

  /// The character offset of [quote] within the original message's text, if it appears more than once.
  final int? quotePosition;

  /// Creates reply parameters targeting [messageId].
  const ReplyParameters(
    this.messageId, {
    this.chatId,
    this.allowSendingWithoutReply,
    this.quote,
    this.quoteParseMode,
    this.quoteEntities,
    this.quotePosition,
  });

  /// Converts these parameters to the JSON shape Telegram's API expects.
  Json toJson() => {
        'message_id': messageId,
        if (chatId != null) 'chat_id': chatId,
        if (allowSendingWithoutReply != null)
          'allow_sending_without_reply': allowSendingWithoutReply,
        if (quote != null) 'quote': quote,
        if (quoteParseMode != null) 'quote_parse_mode': quoteParseMode!.value,
        if (quoteEntities != null) 'quote_entities': quoteEntities,
        if (quotePosition != null) 'quote_position': quotePosition,
      };
}
