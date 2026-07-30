# ptgb

[![pub package](https://img.shields.io/pub/v/ptgb.svg)](https://pub.dev/packages/ptgb)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A complete client for the [Telegram Bot API](https://core.telegram.org/bots/api). Methods
for every endpoint + keyboards, media, webhooks, payments, stickers,
business accounts, and etc.

```dart
import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot(); // loads your token from a .env file — see Quick Start
  await for (final update in bot.poll()) {
    if (update.text == '/start') {
      await bot.sendMessage(update.chatId!, 'Hello from ptgb!');
    }
  }
}
```

## Contents

- [Features](#features)
- [Installation](#installation)
- [Getting a bot token](#getting-a-bot-token)
- [Quick start](#quick-start)
- [Examples](#examples)
- [Things to keep in mind](#things-to-keep-in-mind)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Full API coverage** — messaging, media, chat & forum administration,
  inline mode, payments & Telegram Stars, stickers, games, Telegram Business
  accounts, Stories, and Web Apps.
- **Two update sources** — long-polling out of the box (`Bot.poll`) or your
  own webhook server (`Bot.serveWebhook`).
- **Typed helpers**, not raw JSON, for keyboards (`InlineKeyboardMarkup`,
  `ReplyKeyboardMarkup`), media (`InputMedia*`), and permissions
  (`ChatPermissions`, `ChatAdministratorRights`).
- **Telegram Mini App support** — verify a Web App's signed `initData` with
  `Bot.verifyWebAppInitData`.
- **A low-level escape hatch** (`Bot.call`) for any Bot API method that
  doesn't have a typed wrapper yet.

## Installation

```bash
dart pub add ptgb
```

or add it to `pubspec.yaml` directly:

```yaml
dependencies:
  ptgb: ^1.0.0
```

## Getting a bot token

1. Message [@BotFather](https://t.me/BotFather) on Telegram and send `/newbot`.
2. Copy the token it gives you (looks like `123456:ABC-your-token-here`).
3. Keep it somewhere safe — never commit it to source control. See Quick
   Start below for the recommended way to load it.

## Quick start

**Recommended:** put your token in a `.env` file next to your script and let
`ptgb` load it for you automatically (via the [`penv`](https://pub.dev/packages/penv)
package):

```
TOKEN=123456:ABC-your-token-here
```

```dart
import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot(); // reads TOKEN from .env

  await for (final update in bot.poll()) {
    if (update.text == '/start') {
      await bot.sendMessage(update.chatId!, 'Hello from ptgb!');
    }
  }
}
```

Using a different filename or key? Pass `dotFileName` and/or `envKey`:

```dart
final bot = Bot(dotFileName: 'secrets.env', envKey: 'BOT_TOKEN');
```

Add `.env` to your `.gitignore` so it never gets committed.

**Alternative:** pass the token directly if you're managing it yourself, e.g.
from a secrets manager at deploy time:

```dart
final bot = Bot(token: myTokenFromSomewhereElse);
```

Either way works — just never hard-code a real token as a literal string in
code that ends up in version control.

## Examples

The [`example/`](example/) folder has a full, numbered set of runnable
programs, from a minimal echo bot up to a "god mode" bot exercising
keyboards, media, payments, stickers, invite links, and webhooks. Start with
[`example/README.md`](example/README.md) for the full list and reading order.

## Things to keep in mind

- **Treat your token like a password.** Anyone who has it can control your
  bot. Keep it out of version control.
- **`poll()` and `serveWebhook()` are mutually exclusive.** Telegram only
  delivers updates through one channel at a time — call `setWebhook` before
  using webhooks, and `deleteWebhook` before switching back to polling.
- **ptgb does not retry or throttle requests for you.** Every failed call
  throws a `TelegramApiException`; wrap your update handling in `try`/`catch`
  so one bad call (blocked user, rate limit, invalid `chat_id`) doesn't crash
  your whole process. See `example/15_error_handling_and_retries.dart`.
- **Inline query results are raw JSON `Map`s, not typed classes** — there
  are many result types (article, photo, gif, ...) with very different
  shapes, so this is intentional for now.
- Requires Dart SDK `^3.5.0`.

## Contributing

Bug reports, feature requests, and pull requests are welcome on
[GitHub](https://github.com/psdkjoon/ptgb). If you're filing a bug, a
minimal reproduction and the relevant Bot API method name help a lot.

## License

[MIT](LICENSE) — see the LICENSE file for details.
