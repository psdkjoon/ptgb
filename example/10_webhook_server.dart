// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 10 — WEBHOOKS (production-style deployment)
// ============================================================================
//
// `poll()` (used in every example so far) is great for development, but a
// deployed bot typically uses webhooks instead: Telegram pushes updates
// straight to your own HTTP endpoint, which is more efficient at scale.
//
// This example starts an HTTP server with `serveWebhook` and registers it
// with Telegram via `setWebhook`. You'll need a public HTTPS URL pointing
// at this server — e.g. a reverse proxy (nginx/Caddy) terminating TLS in
// front of this process, or a tunnel like ngrok/Cloudflare Tunnel while
// testing locally.
//
// HOW TO RUN (local testing with a tunnel):
//   1. dart run example/10_webhook_server.dart   (with a `.env` file)
//   2. In another terminal: ngrok http 8443
//   3. Set WEBHOOK_URL below to the https://....ngrok-free.app URL ngrok gives you.
// ============================================================================

import 'dart:developer';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  const webhookUrl = 'https://your-public-domain.example.com/telegram-webhook';
  // A shared secret Telegram will echo back in a header on every request,
  // so you can verify the request really came from Telegram.
  const secretToken = 'a-long-random-secret-you-choose';

  // Start listening for incoming webhook POST requests on port 8443.
  final server = await bot.serveWebhook(
    (update) async {
      // This callback fires for every update, same shape as `poll()`'s stream.
      final text = update.text;
      final chatId = update.chatId;
      if (text != null && chatId != null) {
        await bot.sendMessage(chatId, 'Received via webhook: $text');
      }
    },
    path: '/telegram-webhook',
    port: 8443,
    secretToken: secretToken,
  );

  log('Webhook server listening on ${server.address.address}:${server.port}');

  // Tell Telegram where to send updates. Only needs to run once — Telegram
  // remembers the URL until you call `deleteWebhook` or change it again.
  await bot.setWebhook(webhookUrl, secretToken: secretToken);
  log('Webhook registered at $webhookUrl');

  // NOTE: if you were previously using `poll()` for this same bot, make
  // sure to call `bot.deleteWebhook()` before switching back to polling —
  // a bot can only use one delivery method (polling OR webhook) at a time.
}
