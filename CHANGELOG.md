# Changelog

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
