import 'core.dart';

/// Base type for anything you can pass to a message's `replyMarkup`
/// parameter: an [InlineKeyboardMarkup], [ReplyKeyboardMarkup],
/// [ReplyKeyboardRemove], or [ForceReply].
abstract class ReplyMarkup {
  /// Converts this markup to the JSON shape Telegram's API expects.
  Json toJson();
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

  /// Configures a "Login with Telegram" button (see Telegram's Login Widget docs).
  final Json? loginUrl;

  /// Prompts the user to pick a chat, then inserts `@yourbot <query>` in its input field.
  final String? switchInlineQuery;

  /// Inserts `@yourbot <query>` into the *current* chat's input field.
  final String? switchInlineQueryCurrentChat;

  /// Like [switchInlineQuery], but restricted to specific chat types.
  final Json? switchInlineQueryChosenChat;

  /// Copies this text to the user's clipboard when tapped.
  final Json? copyText;

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

  /// Converts this button to the JSON shape Telegram's API expects.
  Json toJson() => {
        'text': text,
        if (url != null) 'url': url,
        if (callbackData != null) 'callback_data': callbackData,
        if (webAppUrl != null) 'web_app': {'url': webAppUrl},
        if (loginUrl != null) 'login_url': loginUrl,
        if (switchInlineQuery != null) 'switch_inline_query': switchInlineQuery,
        if (switchInlineQueryCurrentChat != null)
          'switch_inline_query_current_chat': switchInlineQueryCurrentChat,
        if (switchInlineQueryChosenChat != null)
          'switch_inline_query_chosen_chat': switchInlineQueryChosenChat,
        if (copyText != null) 'copy_text': copyText,
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
  final Json? requestPoll;

  /// If set, tapping the button opens a list for the user to pick one or more users to share.
  final Json? requestUsers;

  /// If set, tapping the button opens a list for the user to pick a chat to share.
  final Json? requestChat;

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
        if (requestPoll != null) 'request_poll': requestPoll,
        if (requestUsers != null) 'request_users': requestUsers,
        if (requestChat != null) 'request_chat': requestChat,
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
