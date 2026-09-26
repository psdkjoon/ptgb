# Changelog

## 3.1.0

### Changed
- Rewrote documentation across the whole library to be explanatory rather
  than just descriptive: every method on `Bot` and every public class now
  documents what it does, what values are accepted, what's returned, and
  includes a runnable `dart` usage example — not just a one-line summary
  of the signature. Related methods, classes, and enums are now
  cross-linked (e.g. `sendMessage` links to `Message.messageId`, which
  links to `deleteMessage`/`editMessageText`), so you can navigate the
  whole request/response lifecycle for a feature from any one entry point.
- Fixed several pre-existing doc inaccuracies found while doing the above:
  `Bot.getMe`, `Bot.getFile`, and `Bot.getMyStarBalance` all described
  their return value as "raw JSON" when they actually return typed
  wrappers (`User`, `TelegramFile`, `StarAmount`); `PreparedInlineMessage`
  pointed at a nonexistent `sendPreparedMessage` `Bot` method instead of
  explaining that its `id` is consumed by the Mini App frontend's own
  `Telegram.WebApp.shareMessage` call.
- No API surface changes — this release is documentation-only.

## 3.0.0

### Changed — BREAKING
- **Every method on `Bot`, and every constructor across the whole library
  (keyboards, media, inline query results, message content, permissions,
  stickers, checklists, business/story types), now takes named parameters
  only.** Positional parameters are gone entirely — including required
  ones. For example:
  ```dart
  // Before (2.x)
  await bot.sendMessage(chatId, 'Hello!');
  InlineKeyboardButton.callback('Yes', 'yes');

  // After (3.0.0)
  await bot.sendMessage(chatId: chatId, text: 'Hello!');
  InlineKeyboardButton.callback(text: 'Yes', data: 'yes');
  ```
  This is a breaking change for every call site in existing code — update
  each call to name its arguments. Internal JSON-wrapper types you don't
  normally construct yourself (`User`, `Chat`, `Message`, `Update`, and
  similar response types) are unaffected.
- Every `///` doc comment across the library was reviewed for clarity, and
  ones that lacked a usage example now have one, so the library is usable
  by someone with no prior Telegram Bot API experience.
- `penv`'s default `.env` template (used the first time `Bot()` can't find
  a `.env` file) is now a beginner-friendly, ptgb-specific template that
  explains exactly how to get a token from @BotFather, instead of a bare
  placeholder. Customize it with the new `dotEnvTemplate` parameter on
  `Bot()`.

### Added
- `BotStorage` (`lib/src/storage.dart`) — built-in, file-backed persistence
  for a bot's users, chats, and any custom per-user/per-chat data, powered
  by [`pdata`](https://pub.dev/packages/pdata). See `example/42_bot_storage.dart`
  and the "Saving users and chats" section of the README.
  - `saveUser`/`saveChat` — save or refresh a `User`/`Chat` record.
  - `getUser`/`getChat` — read back a single stored record (`StoredUser`/`StoredChat`).
  - `allUsers`/`allChats` — list every stored record.
  - `removeUser`/`removeChat` — delete a stored record.
  - `setUserData`/`getUserData` and `setChatData`/`getChatData` — attach
    and read arbitrary custom data per user/chat.
- `Bot()`'s `dotEnvTemplate` parameter, and `Bot.defaultDotEnvTemplate`, for
  customizing the starter `.env` content ptgb writes the first time no
  `.env` file exists.

### Dependencies
- Added `pdata: ^1.0.0`.

## 2.0.0

### Added
- `Update`'s payload getters (`.callbackQuery`, `.inlineQuery`,
  `.chosenInlineResult`, `.shippingQuery`, `.preCheckoutQuery`,
  `.chatJoinRequest`, `.myChatMember`/`.chatMember`, `.pollAnswer`,
  `.messageReaction`/`.messageReactionCount`, `.businessConnection`,
  `.deletedBusinessMessages`, `.purchasedPaidMedia`, `.chatBoost`,
  `.removedChatBoost`, `.subscription`) now return typed wrapper classes
  directly instead of raw `Json`: `CallbackQuery`, `InlineQuery`,
  `ChosenInlineResult`, `ShippingQuery`, `PreCheckoutQuery`,
  `ChatJoinRequest`, `ChatMemberUpdated`, `PollAnswer`,
  `MessageReactionUpdated`, `MessageReactionCountUpdated`,
  `BusinessConnection`, `BusinessMessagesDeleted`, `PaidMediaPurchased`,
  `ChatBoostUpdated`, `ChatBoostRemoved`, `ChatSubscriptionUpdated`
  (`lib/src/updates.dart`).
- `Message`'s content getters (`.photo`, `.location`, `.document`, `.video`,
  `.audio`, `.voice`, `.animation`, `.videoNote`, `.contact`, `.venue`,
  `.poll`, `.sticker`, `.invoice`, `.successfulPayment`, `.game`, `.dice`,
  `.webAppData`, ...) now return typed wrapper classes: `PhotoSize`,
  `Location`, `Document`, `Video`, `Audio`, `Voice`, `Animation`,
  `VideoNote`, `Contact`, `Venue`, `Poll`, `PollOption`, `Sticker`,
  `Invoice`, `SuccessfulPayment`, `OrderInfo`, `ShippingAddress`, `Game`,
  `Dice`, `WebAppData` (`lib/src/models.dart`). `newChatMembers` is now
  `List<User>` and `leftChatMember` is now `User?`.
- Every `Bot` method that used to return raw `Json`/`List<Json>` now
  returns a typed class/`List` of one, including: `Message` (`sendMessage`
  and every other `send*`/`forward*`/`editMessage*` method that returns a
  message), `MessageId` (`copyMessage`, `copyMessages`), `User` (`getMe`),
  `WebhookInfo`, `UserProfilePhotos`, `TelegramFile` (`getFile`,
  `uploadStickerFile` — named to avoid clashing with `dart:io`'s `File`),
  `ChatInviteLink`, `ChatFullInfo` (`getChat`), `ChatMember`
  (`getChatMember`, `getChatAdministrators`), `ForumTopic`, `BotName`,
  `BotDescription`, `BotShortDescription`, `MenuButton`,
  `ChatAdministratorRights` (now with a `.fromJson` factory),
  `SentWebAppMessage`, `PreparedInlineMessage`, `StarTransactions`,
  `StickerSet`, `UserChatBoosts`, `ChatBoost`, `StarAmount`, `OwnedGifts`,
  `OwnedGift`, `Gifts`, `Gift`, `Story`, `Poll` (`stopPoll`),
  `UserProfileAudios`, `List<BotCommand>` (`getMyCommands`).
- `editMessage*`/`setGameScore` (which Telegram may answer with either the
  edited `Message` or `true`, depending on whether you addressed the
  message by `chatId`/`messageId` or by `inlineMessageId`) now return
  `Future<Object>` holding one or the other, instead of `Future<dynamic>`.
- A full typed inline query result hierarchy
  (`lib/src/inline_query_result.dart`): `InlineQueryResult` (base) plus
  `InlineQueryResultArticle`, `..Photo`, `..Gif`, `..Mpeg4Gif`, `..Video`,
  `..Audio`, `..Voice`, `..Document`, `..Location`, `..Venue`,
  `..Contact`, `..Game`, `..Sticker`, and the `..Cached*` variants for
  every media type that supports a cached `file_id`. Plus a small
  `inlineQueryResults([...])` helper to convert a list to the JSON
  `answerInlineQuery` expects.
- A typed input message content hierarchy
  (`lib/src/input_message_content.dart`): `InputMessageContent` (base),
  `InputTextMessageContent`, `InputLocationMessageContent`,
  `InputVenueMessageContent`, `InputContactMessageContent`,
  `InputInvoiceMessageContent`.
- `keyboards.dart`: `LoginUrl` and `SwitchInlineQueryChosenChat` classes
  (for `InlineKeyboardButton.loginUrl`/`.switchInlineQueryChosenChat`),
  `InlineKeyboardButton.copyText` is now a plain `String?`,
  `KeyboardButtonPollType`, `KeyboardButtonRequestUsers`, and
  `KeyboardButtonRequestChat` classes (for `KeyboardButton.requestPoll`/
  `.requestUsers`/`.requestChat`).
- `WebAppInitData.user`/`.receiver` now return `User?`, and `.chat` returns
  `Chat?`, instead of raw `Json?`.

### Changed
- **Breaking:** `Bot.answerInlineQuery` now takes
  `List<InlineQueryResult>` instead of `List<Json>`.
  `Bot.savePreparedInlineMessage`, `Bot.answerWebAppQuery`, and
  `Bot.answerGuestQuery` now take a single `InlineQueryResult` instead of
  raw `Json`. `Bot.savePreparedKeyboardButton` now takes a typed
  `KeyboardButton` instead of raw `Json`.
- **Breaking:** every method listed above that used to return `Json` or
  `List<Json>` (or, for the `editMessage*` family, `dynamic`) now returns
  its typed counterpart. See "Added" above for the full method-to-type
  mapping, or `MIGRATING.md` for a migration walkthrough.
- **Breaking:** `Update`'s payload getters and `Message`'s content getters
  now return typed wrapper classes directly instead of raw `Json` — see
  "Added" above. `.raw` remains available on every wrapper for anything
  not covered by a getter.

## 1.1.1

### Added
- Typed getter: `GameHighScore` (`lib/src/models.dart`) — `position`, `user` (as `User`), `score`, matching the existing `User`/`Chat`/`Message` wrapper pattern. Fixes the last spot (`getGameHighScores` results) where a per-item value had no typed path.
- README: docs badge and a "Documentation" section linking the main wiki (`doc.psdkjoon.ir/ptgb`) plus mirrors (`doc.psdk.space/ptgb`, `doc.psdk.fun/ptgb`).

### Changed
- Examples updated to use existing `Update` shortcuts instead of manually indexing raw JSON: `13_invite_links_and_join_requests.dart` (`userId`/`chatId`/`username`), `05_polls_dice_reactions.dart` (`messageId`), `07_chat_and_forum_admin.dart` (`replyToMessage`), `34_business_account_profile.dart`/`35_business_stars_and_messages.dart`/`36_stories.dart` (`businessConnection`), `20_new_bot_api_concepts.dart` (`text`), and `30_games_and_high_scores.dart` (new `GameHighScore` wrapper).

## 1.1.0

### Added
- Bot API 7.6–10.2 methods: `sendPaidMedia`, `verifyUser`, `verifyChat`, `removeUserVerification`, `removeChatVerification`, `getMyStarBalance`, `sendChecklist`, `editMessageChecklist`, `approveSuggestedPost`, `declineSuggestedPost`, `setMyProfilePhoto`, `removeMyProfilePhoto`, `getUserProfileAudios`, `getManagedBotToken`, `replaceManagedBotToken`, `savePreparedKeyboardButton`, `sendLivePhoto`, `answerGuestQuery`, `sendRichMessage`, `sendRichMessageDraft`, `answerChatJoinRequestQuery`, `sendChatJoinRequestWebApp`, `editEphemeralMessageText`, `editEphemeralMessageMedia`, `editEphemeralMessageCaption`, `editEphemeralMessageReplyMarkup`, `deleteEphemeralMessage`, `getUserGifts`, `getChatGifts`, `sendMessageDraft`, `repostStory`
- `Update.subscription` and `UpdateType.subscription`
- `Update` shortcuts: `userId`, `messageId`, `username`, `firstName`, `chatType`, `caption`, `messageThreadId`, `replyToMessage`, `entities`, `guestMessage`, `guestQueryId`, `chatJoinRequestQueryId`
- Typed getters: `User`, `Chat`, `Message` (`lib/src/models.dart`)
- `InputPaidMedia` / `InputPaidMediaPhoto` / `InputPaidMediaVideo`
- `InputChecklist` / `InputChecklistTask`
- Optional `RateLimiter` (`lib/src/rate_limiter.dart`, pass via `Bot(rateLimiter: ...)`)
- `requestTimeout` parameter on `Bot` / `TelegramHttpClient` (default 35s)
- `onError` callback on `poll()` and `serveWebhook`
- `topics: [telegram, bot, api]` in `pubspec.yaml`
- Examples: `17_rate_limiting.dart`, `18_typed_message_helpers.dart`, `19_update_shortcuts_and_any_message.dart`, `20_new_bot_api_concepts.dart`

### Changed
- `poll()` now retries transient network errors with exponential backoff
- Non-JSON responses throw `TelegramApiException` instead of `FormatException`
- **Breaking:** `getBusinessAccountGifts` — `excludeLimited` replaced with `excludeLimitedUpgradable` / `excludeLimitedNonUpgradable`

## 1.0.0
- Initial release.
