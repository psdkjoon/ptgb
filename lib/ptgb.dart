/// `ptgb` — a full, pure-Dart Telegram Bot API client.
///
/// Import this file to get everything you need: the [Bot] class plus every
/// supporting type (keyboards, media, permissions, enums, updates,
/// built-in [BotStorage] persistence, ...).
///
/// ```dart
/// import 'package:ptgb/ptgb.dart';
///
/// void main() async {
///   // Loads the token from a `.env` file (TOKEN=...) next to your script.
///   // Pass `Bot(token: '...')` directly if you'd rather manage it yourself.
///   final bot = Bot();
///   await for (final update in bot.poll()) {
///     if (update.text == '/start') {
///       await bot.sendMessage(chatId: update.chatId!, text: 'Hello from ptgb!');
///     }
///   }
/// }
/// ```
///
/// Want to remember your bot's users and chats between runs without
/// setting up a database? See [BotStorage] — a built-in, file-backed
/// store for users, chats, and any custom per-user/per-chat data you want
/// to keep.
///
/// ## Where to look next
///
/// - **Sending things**: every Bot API method — `sendMessage`, `sendPhoto`,
///   `editMessageText`, `deleteMessage`, `banChatMember`, and ~140 more —
///   is a typed method directly on [Bot]. Start reading at [Bot.sendMessage].
/// - **Reading what a message/click contains**: incoming events all arrive
///   as an [Update] from [Bot.poll]/[Bot.getUpdates] or your webhook
///   handler. It has direct shortcuts (`update.text`, `update.chatId`,
///   `update.callbackData`, ...) so you rarely need to dig into
///   `update.message` yourself — see [Update].
/// - **Buttons**: [InlineKeyboardMarkup] (buttons attached to a message,
///   handled via [Bot.answerCallbackQuery]) and [ReplyKeyboardMarkup]
///   (buttons that replace the user's keyboard).
/// - **Sending files/photos/etc.**: [InputFile] describes where the bytes
///   come from (local path, URL, raw bytes, or a `file_id` you already
///   have); [InputMedia] describes one item in an album sent with
///   [Bot.sendMediaGroup].
/// - **Fixed-choice fields** (parse mode, chat member status, dice emoji,
///   ...) are all typed enums — see the enums exported from
///   `src/enums.dart`, e.g. [ParseMode], [ChatAction], [DiceEmoji].
/// - **Errors**: a failed call throws a [TelegramApiException] carrying
///   Telegram's `error_code` and `description` — see [Bot.call].
///
/// See the `example/` folder in the package for a full set of runnable
/// examples, from a minimal echo bot up to a "god mode" bot exercising
/// keyboards, media, payments, stickers, forums, and webhooks.
library;

export 'src/bot.dart';
export 'src/storage.dart';
