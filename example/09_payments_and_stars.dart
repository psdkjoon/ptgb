// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 09 — PAYMENTS AND TELEGRAM STARS
// ============================================================================
//
// This example sells a fictional "digital sticker pack" for 50 Telegram
// Stars — Telegram's built-in in-app currency, which needs no payment
// provider setup at all. (To charge real-world currency instead, get a
// `providerToken` from @BotFather and pass it to `sendInvoice`.)
//
// Every payment flow has three steps:
//   1. Send an invoice (`sendInvoice`).
//   2. Answer the pre-checkout confirmation (`answerPreCheckoutQuery`) —
//      this is your last chance to reject the payment (e.g. out of stock).
//   3. Receive the `successful_payment` field on the resulting message.
//
// HOW TO RUN:
//   dart run example/09_payments_and_stars.dart   (with a `.env` file)
// ============================================================================

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  await for (final update in bot.poll()) {
    // Step 2: Telegram asks for final confirmation right before charging
    // the user. You MUST answer within 10 seconds.
    final preCheckout = update.preCheckoutQuery;
    if (preCheckout != null) {
      // Here you'd check stock, validate the payload, etc. We always accept.
      await bot.answerPreCheckoutQuery(preCheckout.id, true);
      continue;
    }

    final text = update.text;
    final chatId = update.chatId;

    // Step 3: the payment succeeded — Telegram attaches this field to the
    // message that follows the invoice.
    final successfulPayment = update.message?.successfulPayment;
    if (successfulPayment != null && chatId != null) {
      await bot.sendMessage(
        chatId,
        'Thank you for your purchase! 🎉 Here is your sticker pack.',
      );
      continue;
    }

    if (text == '/buy' && chatId != null) {
      // Step 1: send the invoice. `currency: 'XTR'` and no `providerToken`
      // means "charge in Telegram Stars" — no external payment provider needed.
      await bot.sendInvoice(
        chatId,
        'Digital Sticker Pack',
        'A pack of 20 exclusive stickers, delivered instantly.',
        'sticker_pack_v1', // your own internal order/payload identifier
        'XTR',
        [
          {'label': 'Sticker Pack', 'amount': 50}, // 50 Telegram Stars
        ],
      );
    } else if (text != null && chatId != null) {
      await bot.sendMessage(
        chatId,
        'Send /buy to purchase a digital sticker pack for 50 ⭐.',
      );
    }
  }
}
