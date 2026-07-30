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
| `08_inline_queries.dart` | Inline mode (`@yourbot ...` in any chat). |
| `09_payments_and_stars.dart` | Selling something with Telegram Stars, the full invoice → checkout → success flow. |
| `10_webhook_server.dart` | Switching from polling to a production-style webhook server. |
| `11_god_mode_bot.dart` | **Everything above, combined** into one polished, menu-driven bot. Start here if you just want to see what's possible, then dip into the earlier files for the details. |
| `12_web_app_verification.dart` | Verifying a Telegram Mini App's signed `initData`. |
| `13_invite_links_and_join_requests.dart` | Invite links that require bot approval to join — `createChatInviteLink`, `chatJoinRequest` updates. |
| `14_sticker_sets.dart` | The multi-step flow for creating and adding to a sticker set. |
| `15_error_handling_and_retries.dart` | Handling `TelegramApiException`: rate limits (429), blocked chats (403), and retry/backoff. |
| `16_custom_env_config.dart` | Overriding the `.env` filename and key via `dotFileName`/`envKey`. |

## A note on error handling

Most examples keep things short by mostly not wrapping calls in `try`/`catch`.
In a real bot, wrap your update-handling logic in a `try`/`catch` for
`TelegramApiException` so that one failed API call — a user who blocked the
bot, a rate limit, a bad `chat_id` — doesn't crash your whole process. See
`15_error_handling_and_retries.dart` for a full retry/backoff pattern, or
`11_god_mode_bot.dart` for a simpler catch-and-log version.
