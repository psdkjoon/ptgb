# Changelog

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
