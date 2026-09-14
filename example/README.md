# ptgb examples — basic to god mode

Every file here is a complete, runnable Dart program. They're numbered in
the order you should read/run them if you're new to `ptgb` or to Telegram
bots in general — each one introduces a new concept on top of the last.

## Setup (do this once)

1. Message [@BotFather](https://t.me/BotFather) on Telegram, send `/newbot`,
   and copy the token it gives you.
2. Create a file named `.env` in the **root of this package** (next to
   `pubspec.yaml`). If you skip this, running any example creates one for
   you automatically with step-by-step instructions inside — just open it,
   paste your token after `TOKEN=`, and run the example again. Or create it
   yourself up front:
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
| `42_bot_storage.dart` | Remembering users and chats between runs with the built-in `BotStorage`, backed by `pdata` — no database needed. |

## Full bot projects

Everything above demonstrates one feature at a time. The examples below are
different: each is a complete, standalone bot you could actually deploy —
combining several features into one real product, the way you'd actually
build something. All state that needs to survive a restart uses
`BotStorage`; a few reach out to a real third-party API (noted below) using
nothing but `dart:io`'s built-in `HttpClient`, so no extra dependencies are
needed beyond what's already in `pubspec.yaml`.

| File | What it is |
| --- | --- |
| `43_hidden_chat_bot.dart` | Anonymous random-pairing chat — `/find` queues you, two waiting users are matched, messages relay both ways with no names shown. |
| `44_unit_converter_bot.dart` | Length/weight/temperature/currency conversion, usable inline (`@yourbot 10 km to mi`) in any chat. |
| `45_gif_search_bot.dart` | Inline GIF search backed by the real Tenor API (needs a free `TENOR_API_KEY`). |
| `46_shop_catalog_bot.dart` | Product catalog with inline-keyboard browsing, a persistent per-user cart, and Stars checkout — including the `answerPreCheckoutQuery` step real payments require. |
| `47_todo_list_bot.dart` | Personal todo list with inline toggle/delete buttons that edit the list message in place. |
| `48_survey_bot.dart` | Admin-authored multi-question surveys delivered as real (non-anonymous) Telegram polls, tallied automatically. |
| `49_url_shortener_bot.dart` | Shortens URLs to a `t.me` deep link, tracks clicks, works inline. |
| `50_moderation_bot.dart` | Auto-deletes links from non-admins, tracks warnings, auto-mutes at 3 — plus manual `/warn`, `/mute`, `/ban` by replying to a message. |
| `51_expense_splitter_bot.dart` | Group "who owes who" tracking — `/paid`, `/owe`, `/settle`, `/balances`, matched by first name. |
| `52_habit_tracker_bot.dart` | Daily habit check-ins with current/longest streak tracking. |
| `53_feedback_bot.dart` | Anonymous feedback inbox — relays messages to an admin via `copyMessage` (not `forwardMessage`, which would leak the sender's name) and routes replies back. |
| `54_booking_bot.dart` | Appointment slot picker — an inline "calendar" that shrinks as slots are booked. |
| `55_rss_notifier_bot.dart` | Watches an RSS feed on a `Timer.periodic` alongside `Bot.poll`'s update stream, posting new entries to subscribed chats. |
| `56_flashcard_bot.dart` | Spaced-repetition flashcard study (SM-2-style interval scheduling) with Again/Good/Easy grading buttons. |
| `57_welcome_captcha_bot.dart` | Mutes new group members until they tap a "prove you're human" button within 2 minutes, or removes them. |
| `58_pastebin_bot.dart` | Save a ```` ``` ````-fenced code block, get a short code back, share the full snippet inline anywhere. |
| `59_guessing_game_bot.dart` | Classic 1-100 number guessing game with higher/lower hints, shared per-chat so groups can compete. |
| `60_broadcast_bot.dart` | Admin `/broadcast` to every user and chat `BotStorage` has ever seen, skipping anyone who's blocked the bot. |
| `61_price_alert_bot.dart` | Crypto price alerts backed by CoinGecko's free, keyless API, checked every minute via `Timer.periodic`. |

## A note on error handling

Most examples keep things short by mostly not wrapping calls in `try`/`catch`.
In a real bot, wrap your update-handling logic in a `try`/`catch` for
`TelegramApiException` so that one failed API call — a user who blocked the
bot, a rate limit, a bad `chat_id` — doesn't crash your whole process. See
`15_error_handling_and_retries.dart` for a full retry/backoff pattern, or
`11_god_mode_bot.dart` for a simpler catch-and-log version.
