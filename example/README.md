# ptgb examples — basic to god mode

Every file here is a complete, runnable Dart program. They're numbered in
the order you should read/run them if you're new to `ptgb` or to Telegram
bots in general — each one introduces a new concept on top of the last.

## Setup (do this once)

1. Message [@BotFather](https://t.me/BotFather) on Telegram, send `/newbot`,
   and copy the token it gives you.
2. Create a file named `.env` in the **root of this package** (next to
   `pubspec.yaml`) containing:
   ```
   TOKEN=123456:ABC-your-token-here
   ```
   `.env` is already in `.gitignore` — never commit your real token.
3. Run any example from the package root:
   ```bash
   dart run example/01_basic_echo_bot.dart
   ```

`ptgb_example.dart` is the same minimal echo bot shown on the pub.dev
package page. It passes the token directly (`Bot(token: '...')`) so the
snippet is fully self-contained with no setup — handy to see that this
initialization method exists, but **don't do this in a real project**.
Every other example here (starting with `01_basic_echo_bot.dart`) loads
the token from `.env` instead, which is the approach to actually use.

## The examples, in order

| File | What it teaches |
|---|---|
| `ptgb_example.dart` | The absolute minimum: create a `Bot`, poll, reply. |
| `01_basic_echo_bot.dart` | Same idea, fully commented line-by-line. |
| `02_commands_and_text.dart` | Loading the token from `.env`, `/command` routing, `setMyCommands`. |
| `03_keyboards.dart` | Inline keyboards, reply keyboards, callback queries. |
| `04_media_and_files.dart` | Sending photos by URL/path/bytes, albums, downloading received files. |
| `05_polls_dice_reactions.dart` | Native polls, quizzes, animated dice, message reactions. |
| `06_callback_queries_and_editing.dart` | A live-editing counter — `editMessageText` in action. |
| `07_chat_and_forum_admin.dart` | Muting/unmuting members, pinning, forum topics. |
| `08_inline_queries.dart` | Inline mode (`@yourbot ...` in any chat) using typed `InlineQueryResult*` classes. |
| `09_payments_and_stars.dart` | Selling something with Telegram Stars, the full invoice → checkout → success flow. |
| `10_webhook_server.dart` | Switching from polling to a production-style webhook server. |
| `11_god_mode_bot.dart` | **Everything above, combined** into one polished, menu-driven bot. Start here if you just want to see what's possible, then dip into the earlier files for the details. |
| `12_web_app_verification.dart` | Verifying a Telegram Mini App's signed `initData`. |
| `13_invite_links_and_join_requests.dart` | Invite links that require bot approval to join — `createChatInviteLink`, `chatJoinRequest` updates. |
| `14_sticker_sets.dart` | The multi-step flow for creating and adding to a sticker set. |
| `15_error_handling_and_retries.dart` | Handling `TelegramApiException`: rate limits (429), blocked chats (403), and retry/backoff. |
| `16_custom_env_config.dart` | Overriding the `.env` filename and key via `dotFileName`/`envKey`. |
| `17_rate_limiting.dart` | Automatically pacing outgoing requests with the optional `RateLimiter`. |
| `18_typed_message_helpers.dart` | Typed `User`/`Chat`/`Message` getters — now the default for every `Update`/`Message` field. |
| `19_update_shortcuts_and_any_message.dart` | `Update`'s direct-access shortcuts (`userId`, `messageId`, `username`, ...) and the `anyMessage` typed fallback for photos, locations, documents, and contacts. |
| `20_new_bot_api_concepts.dart` | The newest Bot API concepts: checklists, rich messages, suggested posts, ephemeral messages, guest queries, and guard-bot join requests. |
| `21_reply_parameters_and_quoting.dart` | `ReplyParameters` in depth: plain replies, quoting a specific excerpt, and `allowSendingWithoutReply`. |
| `22_link_preview_options.dart` | Disabling, redirecting, and resizing a text message's link preview with `LinkPreviewOptions`. |
| `23_advanced_reactions.dart` | `ReactionType.emoji`/`.customEmoji`/`.paid`, multiple reactions at once, and clearing reactions. |
| `24_forwarding_and_copying.dart` | `forwardMessage`/`forwardMessages` vs `copyMessage`/`copyMessages` — attribution vs. no attribution. |
| `25_locations_and_venues.dart` | `sendLocation`, `sendVenue`, and updating/stopping a live location. |
| `26_contacts_and_chat_actions.dart` | `sendContact` and the "typing..."/"sending photo..." status indicator via `sendChatAction`. |
| `27_chat_permissions_and_promotion.dart` | `ChatPermissions`, `restrictChatMember`, `promoteChatMember`, and `setChatAdministratorCustomTitle`. |
| `28_bot_profile_and_menu.dart` | `setMyName`/`setMyDescription`/`setMyShortDescription` and swapping the chat menu button for a Web App. |
| `29_default_admin_rights.dart` | Pre-filling the admin rights checklist shown when someone adds your bot, via `setMyDefaultAdministratorRights`. |
| `30_games_and_high_scores.dart` | `sendGame`, `setGameScore`, and `getGameHighScores` for Telegram Games. |
| `31_profile_photos_and_downloads.dart` | Reading a user's `getUserProfilePhotos`, `downloadFileById`, and managing the bot's own avatar. |
| `32_chat_boosts_and_verification.dart` | `getUserChatBoosts` and the official `verifyUser`/`verifyChat` badge methods. |
| `33_gifts.dart` | Browsing the gift catalog and sending gifts / gifted Premium with `sendGift`/`giftPremiumSubscription`. |
| `34_business_account_profile.dart` | Editing a connected Business Account's name, username, bio, photo, and gift settings. |
| `35_business_stars_and_messages.dart` | A connected Business Account's Star balance/transfers and marking/deleting its messages. |
| `36_stories.dart` | Posting, editing, and deleting Telegram Stories via a Business Connection. |
| `37_prepared_messages.dart` | Pre-registering reusable typed inline results and keyboard buttons with `savePreparedInlineMessage`/`savePreparedKeyboardButton`. |
| `38_subscription_invite_links.dart` | Paid recurring-membership invite links and canceling a user's Star subscription. |
| `39_message_drafts.dart` | Pre-filling a chat's input field without sending, via `sendMessageDraft`/`sendRichMessageDraft`. |
| `40_custom_emoji_and_sticker_details.dart` | Looking up sticker sets and custom emoji, and re-tagging an existing sticker's search metadata. |
| `41_inline_query_result_gallery.dart` | Reference gallery: one of every `InlineQueryResult*` (including `Cached*` variants) and `InputMessageContent*` subtype. |

## A note on error handling

Most examples keep things short by mostly not wrapping calls in `try`/`catch`.
In a real bot, wrap your update-handling logic in a `try`/`catch` for
`TelegramApiException` so that one failed API call — a user who blocked the
bot, a rate limit, a bad `chat_id` — doesn't crash your whole process. See
`15_error_handling_and_retries.dart` for a full retry/backoff pattern, or
`11_god_mode_bot.dart` for a simpler catch-and-log version.
