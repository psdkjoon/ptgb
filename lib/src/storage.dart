import 'dart:io';

import 'package:pdata/pdata.dart';

import 'core.dart';
import 'models.dart';

/// Built-in, file-backed persistence for a bot's users, chats, and any
/// other data you want to remember between runs — powered by
/// [pdata](https://pub.dev/packages/pdata), so it reads and writes plain
/// JSON/YAML/TOML files with zero extra dependencies.
///
/// This solves the most common "day one" problem when writing a bot: you
/// want to know who has talked to your bot before, look up a chat later,
/// or store a per-user setting (like a preferred language) — without
/// setting up a database.
///
/// ```dart
/// import 'package:ptgb/ptgb.dart';
///
/// void main() async {
///   final bot = Bot();
///   final storage = BotStorage(path: 'bot_data.json');
///   await storage.load();
///
///   await for (final update in bot.poll()) {
///     final user = update.from;
///     if (user != null) {
///       // Remembers this user (id, name, username, ...) the first time
///       // they're seen, and refreshes their info on every later message.
///       await storage.saveUser(user: user);
///     }
///
///     if (update.text == '/users') {
///       final count = storage.allUsers().length;
///       await bot.sendMessage(
///         chatId: update.chatId!,
///         text: 'I know $count user(s) so far!',
///       );
///     }
///   }
/// }
/// ```
///
/// Every write ([saveUser], [saveChat], [setUserData], [setChatData],
/// [removeUser], [removeChat]) immediately persists to disk at [path], so
/// you don't need to remember to call [save] yourself — it's exposed too,
/// in case you'd rather batch several changes and flush once.
///
/// Internally, users and chats are keyed by their numeric Telegram ID
/// ([Map<int, Json>]) rather than a stringified one — [path] only needs
/// string keys on disk, so that conversion happens once per [load]/[save]
/// instead of on every [saveUser]/[getUser]/[setUserData]/... call.
class BotStorage {
  /// The file this storage reads from and writes to. The format (JSON,
  /// YAML, or TOML) is guessed from the extension — see [PdataFormat].
  final String path;

  /// Overrides the format guessed from [path]'s extension. Leave `null` to
  /// guess from the extension (`.json`, `.yaml`/`.yml`, or `.toml`).
  final PdataFormat? format;

  /// Whether every mutating call ([saveUser], [saveChat], [setUserData],
  /// [setChatData], [removeUser], [removeChat]) writes to disk right away.
  /// Set this to `false` and call [save] yourself if you're making many
  /// changes at once and want to flush only at the end.
  final bool autoSave;

  final Map<int, Json> _users = {};
  final Map<int, Json> _chats = {};

  /// Creates a [BotStorage] backed by the file at [path]. Call [load]
  /// before reading or writing — this constructor doesn't touch disk.
  BotStorage({required this.path, this.format, this.autoSave = true});

  /// Reads [path] into memory, creating an empty store if the file doesn't
  /// exist yet. Call this once, right after creating the [BotStorage] and
  /// before your bot starts handling updates.
  ///
  /// ```dart
  /// final storage = BotStorage(path: 'bot_data.json');
  /// await storage.load();
  /// ```
  Future<void> load() async {
    final file = File(path);
    if (!await file.exists()) return;
    final raw = await pdataReadFileAsync(path, format: format);
    final data = (raw as Json?) ?? <String, dynamic>{};
    final users = data['users'] as Json? ?? <String, dynamic>{};
    final chats = data['chats'] as Json? ?? <String, dynamic>{};
    _users
      ..clear()
      ..addAll(users.map((k, v) => MapEntry(int.parse(k), v as Json)));
    _chats
      ..clear()
      ..addAll(chats.map((k, v) => MapEntry(int.parse(k), v as Json)));
  }

  /// Writes the current in-memory state to [path]. Called automatically by
  /// every mutating method when [autoSave] is `true` (the default) — you
  /// only need this yourself if you set [autoSave] to `false`.
  Future<void> save() async {
    await pdataWriteFileAsync(
      path,
      {
        'users': _users.map((id, value) => MapEntry(id.toString(), value)),
        'chats': _chats.map((id, value) => MapEntry(id.toString(), value)),
      },
      format: format,
    );
  }

  Future<void> _maybeSave() async {
    if (autoSave) await save();
  }

  /// Saves or updates [user] in storage, keyed by their [User.id]. Safe to
  /// call on every incoming update — the first call creates the record,
  /// every later call refreshes their name/username in place.
  ///
  /// Any custom data previously set with [setUserData] for this user is
  /// preserved.
  ///
  /// ```dart
  /// await for (final update in bot.poll()) {
  ///   if (update.from != null) await storage.saveUser(user: update.from!);
  /// }
  /// ```
  Future<void> saveUser({required User user}) async {
    final existingData =
        _users[user.id]?['data'] as Json? ?? <String, dynamic>{};
    _users[user.id] = {
      'id': user.id,
      'is_bot': user.isBot,
      'first_name': user.firstName,
      if (user.lastName != null) 'last_name': user.lastName,
      if (user.username != null) 'username': user.username,
      if (user.languageCode != null) 'language_code': user.languageCode,
      'data': existingData,
    };
    await _maybeSave();
  }

  /// Saves or updates [chat] in storage, keyed by their [Chat.id]. Works
  /// just like [saveUser], but for chats (private chats, groups,
  /// supergroups, and channels).
  ///
  /// ```dart
  /// await storage.saveChat(chat: update.message!.chat);
  /// ```
  Future<void> saveChat({required Chat chat}) async {
    final existingData =
        _chats[chat.id]?['data'] as Json? ?? <String, dynamic>{};
    _chats[chat.id] = {
      'id': chat.id,
      'type': chat.type,
      if (chat.title != null) 'title': chat.title,
      if (chat.username != null) 'username': chat.username,
      if (chat.firstName != null) 'first_name': chat.firstName,
      if (chat.lastName != null) 'last_name': chat.lastName,
      'data': existingData,
    };
    await _maybeSave();
  }

  /// The stored record for the user with the given [userId], or `null` if
  /// that user has never been saved via [saveUser].
  ///
  /// ```dart
  /// final record = storage.getUser(userId: update.userId!);
  /// print(record?.firstName);
  /// ```
  StoredUser? getUser({required int userId}) {
    final raw = _users[userId];
    return raw == null ? null : StoredUser(raw);
  }

  /// The stored record for the chat with the given [chatId], or `null` if
  /// that chat has never been saved via [saveChat].
  StoredChat? getChat({required int chatId}) {
    final raw = _chats[chatId];
    return raw == null ? null : StoredChat(raw);
  }

  /// Every user ever saved via [saveUser], most recently added last.
  ///
  /// ```dart
  /// for (final user in storage.allUsers()) {
  ///   print('${user.firstName} (${user.id})');
  /// }
  /// ```
  List<StoredUser> allUsers() =>
      _users.values.map(StoredUser.new).toList(growable: false);

  /// Every chat ever saved via [saveChat], most recently added last.
  List<StoredChat> allChats() =>
      _chats.values.map(StoredChat.new).toList(growable: false);

  /// Removes the user with the given [userId] from storage entirely,
  /// including any data set via [setUserData]. Returns `true` if a user
  /// was actually removed.
  Future<bool> removeUser({required int userId}) async {
    final removed = _users.remove(userId) != null;
    if (removed) await _maybeSave();
    return removed;
  }

  /// Removes the chat with the given [chatId] from storage entirely,
  /// including any data set via [setChatData]. Returns `true` if a chat
  /// was actually removed.
  Future<bool> removeChat({required int chatId}) async {
    final removed = _chats.remove(chatId) != null;
    if (removed) await _maybeSave();
    return removed;
  }

  /// Stores an arbitrary [value] under [key], scoped to the user with the
  /// given [userId] — handy for things like a preferred language, a
  /// per-user counter, or onboarding progress. [userId] must already have
  /// been saved via [saveUser].
  ///
  /// ```dart
  /// await storage.setUserData(userId: update.userId!, key: 'language', value: 'en');
  /// ```
  ///
  /// Throws a [StateError] if [userId] hasn't been saved yet — call
  /// [saveUser] first.
  Future<void> setUserData({
    required int userId,
    required String key,
    required dynamic value,
  }) async {
    final record = _users[userId];
    if (record == null) {
      throw StateError(
        'No stored user with id $userId; call saveUser() first.',
      );
    }
    (record['data'] as Json)[key] = value;
    await _maybeSave();
  }

  /// Reads back a value previously set with [setUserData] for [userId],
  /// or `null` if [userId] isn't stored or [key] was never set.
  ///
  /// ```dart
  /// final language = storage.getUserData(userId: update.userId!, key: 'language') ?? 'en';
  /// ```
  dynamic getUserData({required int userId, required String key}) =>
      (_users[userId]?['data'] as Json?)?[key];

  /// Stores an arbitrary [value] under [key], scoped to the chat with the
  /// given [chatId] — handy for per-chat settings like a group's
  /// configured timezone or feature toggles. [chatId] must already have
  /// been saved via [saveChat].
  ///
  /// Throws a [StateError] if [chatId] hasn't been saved yet — call
  /// [saveChat] first.
  Future<void> setChatData({
    required int chatId,
    required String key,
    required dynamic value,
  }) async {
    final record = _chats[chatId];
    if (record == null) {
      throw StateError(
        'No stored chat with id $chatId; call saveChat() first.',
      );
    }
    (record['data'] as Json)[key] = value;
    await _maybeSave();
  }

  /// Reads back a value previously set with [setChatData] for [chatId], or
  /// `null` if [chatId] isn't stored or [key] was never set.
  dynamic getChatData({required int chatId, required String key}) =>
      (_chats[chatId]?['data'] as Json?)?[key];
}

/// A read-only view of a user record saved via [BotStorage.saveUser].
class StoredUser {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw stored-user JSON object. You normally get one of these
  /// from [BotStorage.getUser] or [BotStorage.allUsers] instead of
  /// constructing it directly.
  const StoredUser(this.raw);

  /// The user's Telegram ID, matching [User.id].
  int get id => raw['id'] as int;

  /// Whether this user is a bot.
  bool get isBot => raw['is_bot'] as bool;

  /// The user's first name, as of the last [BotStorage.saveUser] call.
  String get firstName => raw['first_name'] as String;

  /// The user's last name, if set.
  String? get lastName => raw['last_name'] as String?;

  /// The user's `@username`, if set.
  String? get username => raw['username'] as String?;

  /// IETF language tag of the user's Telegram client, if known.
  String? get languageCode => raw['language_code'] as String?;

  /// Any custom data set for this user via [BotStorage.setUserData].
  Json get data => raw['data'] as Json? ?? const {};
}

/// A read-only view of a chat record saved via [BotStorage.saveChat].
class StoredChat {
  /// The raw JSON this wrapper reads from.
  final Json raw;

  /// Wraps a raw stored-chat JSON object. You normally get one of these
  /// from [BotStorage.getChat] or [BotStorage.allChats] instead of
  /// constructing it directly.
  const StoredChat(this.raw);

  /// The chat's Telegram ID, matching [Chat.id].
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

  /// Whether this is a one-on-one chat with a user.
  bool get isPrivate => type == 'private';

  /// Any custom data set for this chat via [BotStorage.setChatData].
  Json get data => raw['data'] as Json? ?? const {};
}
