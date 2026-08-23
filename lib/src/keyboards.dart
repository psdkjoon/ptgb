import 'core.dart';
import 'enums.dart';

/// Base type for anything you can pass to a message's `replyMarkup`
/// parameter: an [InlineKeyboardMarkup], [ReplyKeyboardMarkup],
/// [ReplyKeyboardRemove], or [ForceReply].
abstract class ReplyMarkup {
  /// Converts this markup to the JSON shape Telegram's API expects.
  Json toJson();
}

/// Configures a "Login with Telegram" button (see Telegram's [Login Widget
/// docs](https://core.telegram.org/widgets/login)), used with
/// [InlineKeyboardButton.loginUrl].
class LoginUrl {
  /// The URL opened after the user authorizes, with auth data appended as
  /// query params (and validated per the login widget docs) or passed via
  /// `tgAuthResult` in the fragment.
  final String url;

  /// The name shown to the user in the authorization prompt, if different
  /// from the bot's.
  final String? forwardText;

  /// Username of a bot with a `domain` linked to [url]'s domain, if
  /// different from the bot sending the button.
  final String? botUsername;

  /// Whether to request the user's permission to send them messages.
  final bool? requestWriteAccess;

  /// Creates login URL parameters targeting [url].
  const LoginUrl(
    this.url, {
    this.forwardText,
    this.botUsername,
    this.requestWriteAccess,
  });

  /// Converts this to the JSON shape Telegram's API expects.
  Json toJson() => {
        'url': url,
        if (forwardText != null) 'forward_text': forwardText,
        if (botUsername != null) 'bot_username': botUsername,
        if (requestWriteAccess != null)
          'request_write_access': requestWriteAccess,
      };
}

/// Like [InlineKeyboardButton.switchInlineQuery], but restricted to
/// specific chat types the user is prompted to pick from, used with
/// [InlineKeyboardButton.switchInlineQueryChosenChat].
class SwitchInlineQueryChosenChat {
  /// The text inserted after `@yourbot` in the chosen chat's input field.
  final String? query;

  /// Whether private chats with users (non-bots) can be chosen.
  final bool? allowUserChats;

  /// Whether private chats with bots can be chosen.
  final bool? allowBotChats;

  /// Whether group and supergroup chats can be chosen.
  final bool? allowGroupChats;

  /// Whether channel chats can be chosen.
  final bool? allowChannelChats;

  /// The identifier of a prepared inline message (from
  /// `Bot.savePreparedInlineMessage`) to share instead of [query], if set.
  final String? preparedInlineMessageId;

  /// Creates chosen-chat restrictions for a switch-inline-query button.
  const SwitchInlineQueryChosenChat({
    this.query,
    this.allowUserChats,
    this.allowBotChats,
    this.allowGroupChats,
    this.allowChannelChats,
    this.preparedInlineMessageId,
  });

  /// Converts this to the JSON shape Telegram's API expects.
  Json toJson() => {
        if (query != null) 'query': query,
        if (allowUserChats != null) 'allow_user_chats': allowUserChats,
        if (allowBotChats != null) 'allow_bot_chats': allowBotChats,
        if (allowGroupChats != null) 'allow_group_chats': allowGroupChats,
        if (allowChannelChats != null) 'allow_channel_chats': allowChannelChats,
        if (preparedInlineMessageId != null)
          'prepared_inline_message_id': preparedInlineMessageId,
      };
}

/// A single button inside an [InlineKeyboardMarkup].
///
/// Exactly one of [url], [callbackData], [webAppUrl], [loginUrl],
/// [switchInlineQuery], [switchInlineQueryCurrentChat],
/// [switchInlineQueryChosenChat], [copyText], or [pay] should be set —
/// they represent mutually exclusive button behaviors. Prefer the named
/// factories ([InlineKeyboardButton.url], [.callback], [.webApp], [.pay])
/// for the common cases.
class InlineKeyboardButton {
  /// The label shown on the button.
  final String text;

  /// Opens this URL when tapped.
  final String? url;

  /// Sent back to your bot as a callback query when tapped (max 64 bytes).
  /// Handle it via the update's callback query and answer with [Bot.answerCallbackQuery].
  final String? callbackData;

  /// Opens a Telegram Web App at this URL when tapped.
  final String? webAppUrl;

  /// Configures a "Login with Telegram" button.
  final LoginUrl? loginUrl;

  /// Prompts the user to pick a chat, then inserts `@yourbot <query>` in its input field.
  final String? switchInlineQuery;

  /// Inserts `@yourbot <query>` into the *current* chat's input field.
  final String? switchInlineQueryCurrentChat;

  /// Like [switchInlineQuery], but restricted to specific chat types.
  final SwitchInlineQueryChosenChat? switchInlineQueryChosenChat;

  /// Copies this text to the user's clipboard when tapped.
  final String? copyText;

  /// Marks this as the "Pay" button on an invoice message.
  final bool? pay;

  /// Creates a button with full control over every field. Prefer a named
  /// factory constructor for common cases.
  const InlineKeyboardButton({
    required this.text,
    this.url,
    this.callbackData,
    this.webAppUrl,
    this.loginUrl,
    this.switchInlineQuery,
    this.switchInlineQueryCurrentChat,
    this.switchInlineQueryChosenChat,
    this.copyText,
    this.pay,
  });

  /// A button that opens [url] when tapped.
  factory InlineKeyboardButton.url(String text, String url) =>
      InlineKeyboardButton(text: text, url: url);

  /// A button that sends [data] back to your bot as a callback query.
  factory InlineKeyboardButton.callback(String text, String data) =>
      InlineKeyboardButton(text: text, callbackData: data);

  /// A button that opens a Telegram Web App at [url].
  factory InlineKeyboardButton.webApp(String text, String url) =>
      InlineKeyboardButton(text: text, webAppUrl: url);

  /// The "Pay" button used on invoice messages.
  factory InlineKeyboardButton.pay(String text) =>
      InlineKeyboardButton(text: text, pay: true);

  /// A button that copies [copyText] to the user's clipboard when tapped.
  factory InlineKeyboardButton.copy(String text, String copyText) =>
      InlineKeyboardButton(text: text, copyText: copyText);

  /// Converts this button to the JSON shape Telegram's API expects.
  Json toJson() => {
        'text': text,
        if (url != null) 'url': url,
        if (callbackData != null) 'callback_data': callbackData,
        if (webAppUrl != null) 'web_app': {'url': webAppUrl},
        if (loginUrl != null) 'login_url': loginUrl!.toJson(),
        if (switchInlineQuery != null) 'switch_inline_query': switchInlineQuery,
        if (switchInlineQueryCurrentChat != null)
          'switch_inline_query_current_chat': switchInlineQueryCurrentChat,
        if (switchInlineQueryChosenChat != null)
          'switch_inline_query_chosen_chat':
              switchInlineQueryChosenChat!.toJson(),
        if (copyText != null) 'copy_text': {'text': copyText},
        if (pay != null) 'pay': pay,
      };
}

/// An inline keyboard attached below a message, made of rows of [InlineKeyboardButton]s.
///
/// ```dart
/// InlineKeyboardMarkup([
///   [InlineKeyboardButton.callback('Yes', 'yes'), InlineKeyboardButton.callback('No', 'no')],
///   [InlineKeyboardButton.url('Docs', 'https://core.telegram.org/bots/api')],
/// ])
/// ```
class InlineKeyboardMarkup implements ReplyMarkup {
  /// The button grid — each inner list is one row.
  final List<List<InlineKeyboardButton>> rows;

  /// Creates a keyboard from explicit [rows].
  const InlineKeyboardMarkup(this.rows);

  /// Shortcut for a keyboard with a single [row] of buttons.
  factory InlineKeyboardMarkup.single(List<InlineKeyboardButton> row) =>
      InlineKeyboardMarkup([row]);

  /// Shortcut for stacking [buttons] one per row (a vertical list of buttons).
  factory InlineKeyboardMarkup.column(List<InlineKeyboardButton> buttons) =>
      InlineKeyboardMarkup(buttons.map((b) => [b]).toList());

  @override
  Json toJson() => {
        'inline_keyboard':
            rows.map((r) => r.map((b) => b.toJson()).toList()).toList(),
      };
}

/// Configures a poll-request [KeyboardButton] — tapping it asks the user to
/// create and send a poll, optionally restricted to a [type].
class KeyboardButtonPollType {
  /// Restricts the poll to `'quiz'` or `'regular'`; leave `null` to let the
  /// user choose either.
  final PollType? type;

  /// Creates poll-request parameters, optionally restricted to [type].
  const KeyboardButtonPollType({this.type});

  /// Converts this to the JSON shape Telegram's API expects.
  Json toJson() => {if (type != null) 'type': type!.value};
}

/// Configures a users-request [KeyboardButton] — tapping it opens a list for
/// the user to pick one or more users to share with the bot.
class KeyboardButtonRequestUsers {
  /// Identifier for this request, reused in the `UsersShared` service
  /// message so you can tell multiple such buttons apart.
  final int requestId;

  /// Restricts picking to bot accounts (`true`) or non-bot users (`false`); unset allows either.
  final bool? userIsBot;

  /// Restricts picking to Telegram Premium users (`true`) or non-Premium
  /// users (`false`); unset allows either.
  final bool? userIsPremium;

  /// Maximum number of users that can be picked at once (1-10, default 1).
  final int? maxQuantity;

  /// Whether to include each picked user's first/last name in the result.
  final bool? requestName;

  /// Whether to include each picked user's `@username` in the result.
  final bool? requestUsername;

  /// Whether to include each picked user's profile photo in the result.
  final bool? requestPhoto;

  /// Creates users-request parameters, identified by [requestId].
  const KeyboardButtonRequestUsers(
    this.requestId, {
    this.userIsBot,
    this.userIsPremium,
    this.maxQuantity,
    this.requestName,
    this.requestUsername,
    this.requestPhoto,
  });

  /// Converts this to the JSON shape Telegram's API expects.
  Json toJson() => {
        'request_id': requestId,
        if (userIsBot != null) 'user_is_bot': userIsBot,
        if (userIsPremium != null) 'user_is_premium': userIsPremium,
        if (maxQuantity != null) 'max_quantity': maxQuantity,
        if (requestName != null) 'request_name': requestName,
        if (requestUsername != null) 'request_username': requestUsername,
        if (requestPhoto != null) 'request_photo': requestPhoto,
      };
}

/// Configures a chat-request [KeyboardButton] — tapping it opens a list for
/// the user to pick a chat to share with the bot.
class KeyboardButtonRequestChat {
  /// Identifier for this request, reused in the `ChatShared` service
  /// message so you can tell multiple such buttons apart.
  final int requestId;

  /// Restricts picking to channels (`true`) or non-channel chats (`false`); unset allows either.
  final bool chatIsChannel;

  /// Restricts picking to forum-enabled chats (`true`) or non-forum chats (`false`); unset allows either.
  final bool? chatIsForum;

  /// Restricts to chats with (`true`) or without (`false`) a public username; unset allows either.
  final bool? chatHasUsername;

  /// Restricts picking to chats owned by the requesting user.
  final bool? chatIsCreated;

  /// The specific admin rights the bot must have in the picked chat, as raw JSON.
  final Json? botAdministratorRights;

  /// The specific admin rights the user must have in the picked chat, as raw JSON.
  final Json? userAdministratorRights;

  /// Restricts picking to chats the bot is already a member of.
  final bool? botIsMember;

  /// Whether to include the picked chat's title in the result.
  final bool? requestTitle;

  /// Whether to include the picked chat's `@username` in the result.
  final bool? requestUsername;

  /// Whether to include the picked chat's photo in the result.
  final bool? requestPhoto;

  /// Creates chat-request parameters, identified by [requestId]. [chatIsChannel]
  /// selects whether the picker offers channels or ordinary chats.
  const KeyboardButtonRequestChat(
    this.requestId,
    this.chatIsChannel, {
    this.chatIsForum,
    this.chatHasUsername,
    this.chatIsCreated,
    this.botAdministratorRights,
    this.userAdministratorRights,
    this.botIsMember,
    this.requestTitle,
    this.requestUsername,
    this.requestPhoto,
  });

  /// Converts this to the JSON shape Telegram's API expects.
  Json toJson() => {
        'request_id': requestId,
        'chat_is_channel': chatIsChannel,
        if (chatIsForum != null) 'chat_is_forum': chatIsForum,
        if (chatHasUsername != null) 'chat_has_username': chatHasUsername,
        if (chatIsCreated != null) 'chat_is_created': chatIsCreated,
        if (botAdministratorRights != null)
          'bot_administrator_rights': botAdministratorRights,
        if (userAdministratorRights != null)
          'user_administrator_rights': userAdministratorRights,
        if (botIsMember != null) 'bot_is_member': botIsMember,
        if (requestTitle != null) 'request_title': requestTitle,
        if (requestUsername != null) 'request_username': requestUsername,
        if (requestPhoto != null) 'request_photo': requestPhoto,
      };
}

/// A single button inside a [ReplyKeyboardMarkup] (the custom keyboard that
/// replaces the device's own keyboard, as opposed to an inline keyboard).
class KeyboardButton {
  /// The label shown on the button, and the text sent as a regular message when tapped.
  final String text;

  /// If set, tapping the button asks the user to share their phone contact.
  final bool? requestContact;

  /// If set, tapping the button asks the user to share their current location.
  final bool? requestLocation;

  /// If set, tapping the button asks the user to create and send a poll.
  final KeyboardButtonPollType? requestPoll;

  /// If set, tapping the button opens a list for the user to pick one or more users to share.
  final KeyboardButtonRequestUsers? requestUsers;

  /// If set, tapping the button opens a list for the user to pick a chat to share.
  final KeyboardButtonRequestChat? requestChat;

  /// If set, tapping the button opens a Telegram Web App at this URL instead of sending a message.
  final String? webAppUrl;

  /// Creates a keyboard button. Only one of [requestContact], [requestLocation],
  /// [requestPoll], [requestUsers], [requestChat], or [webAppUrl] should be
  /// set at a time.
  const KeyboardButton(
    this.text, {
    this.requestContact,
    this.requestLocation,
    this.requestPoll,
    this.requestUsers,
    this.requestChat,
    this.webAppUrl,
  });

  /// Converts this button to the JSON shape Telegram's API expects.
  Json toJson() => {
        'text': text,
        if (requestContact != null) 'request_contact': requestContact,
        if (requestLocation != null) 'request_location': requestLocation,
        if (requestPoll != null) 'request_poll': requestPoll!.toJson(),
        if (requestUsers != null) 'request_users': requestUsers!.toJson(),
        if (requestChat != null) 'request_chat': requestChat!.toJson(),
        if (webAppUrl != null) 'web_app': {'url': webAppUrl},
      };
}

/// A custom keyboard that replaces the user's device keyboard, made of rows
/// of [KeyboardButton]s. Unlike [InlineKeyboardMarkup], tapping a plain-text
/// button here sends its text as a normal chat message rather than a
/// silent callback query.
class ReplyKeyboardMarkup implements ReplyMarkup {
  /// The button grid — each inner list is one row.
  final List<List<KeyboardButton>> keyboard;

  /// Keeps the keyboard visible even after a button is tapped, instead of the default of hiding it.
  final bool? isPersistent;

  /// Shrinks the keyboard to fit its buttons instead of using the full screen height.
  final bool? resizeKeyboard;

  /// Hides the keyboard again as soon as one button is used.
  final bool? oneTimeKeyboard;

  /// Placeholder text shown in the message input field while this keyboard is active.
  final String? inputFieldPlaceholder;

  /// Shows this keyboard only to specific users targeted by the message (see Telegram docs on `selective`).
  final bool? selective;

  /// Creates a reply keyboard from [keyboard]'s rows of buttons.
  const ReplyKeyboardMarkup(
    this.keyboard, {
    this.isPersistent,
    this.resizeKeyboard,
    this.oneTimeKeyboard,
    this.inputFieldPlaceholder,
    this.selective,
  });

  @override
  Json toJson() => {
        'keyboard':
            keyboard.map((r) => r.map((b) => b.toJson()).toList()).toList(),
        if (isPersistent != null) 'is_persistent': isPersistent,
        if (resizeKeyboard != null) 'resize_keyboard': resizeKeyboard,
        if (oneTimeKeyboard != null) 'one_time_keyboard': oneTimeKeyboard,
        if (inputFieldPlaceholder != null)
          'input_field_placeholder': inputFieldPlaceholder,
        if (selective != null) 'selective': selective,
      };
}

/// Removes any active custom [ReplyKeyboardMarkup], reverting the user to
/// their device's default keyboard.
class ReplyKeyboardRemove implements ReplyMarkup {
  /// Removes the keyboard only for specific targeted users (see Telegram docs on `selective`).
  final bool selective;

  /// Creates a request to remove the current custom keyboard.
  const ReplyKeyboardRemove({this.selective = false});

  @override
  Json toJson() => {
        'remove_keyboard': true,
        if (selective) 'selective': true,
      };
}

/// Forces Telegram clients to show a "reply" UI to the user, as if they'd
/// tapped reply on the bot's message — useful for prompting free-text input
/// without a custom keyboard.
class ForceReply implements ReplyMarkup {
  /// Forces the reply UI only for specific targeted users (see Telegram docs on `selective`).
  final bool selective;

  /// Placeholder text shown in the message input field.
  final String? inputFieldPlaceholder;

  /// Creates a force-reply request.
  const ForceReply({this.selective = false, this.inputFieldPlaceholder});

  @override
  Json toJson() => {
        'force_reply': true,
        if (selective) 'selective': true,
        if (inputFieldPlaceholder != null)
          'input_field_placeholder': inputFieldPlaceholder,
      };
}
