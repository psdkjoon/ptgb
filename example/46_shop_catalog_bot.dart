// A complete, deployable bot: browse a product catalog with inline
// keyboards, add items to a persistent per-user cart, and check out with
// Telegram Stars — no external payment provider needed (see
// `09_payments_and_stars.dart` for the underlying API this builds on).
//
// The catalog itself is a hardcoded list for the demo; swap `_catalog` for
// a database or API call in a real shop. Cart contents persist across bot
// restarts via [BotStorage]'s per-user custom data.

import 'dart:convert';

import 'package:ptgb/ptgb.dart';

class _Product {
  const _Product(this.id, this.name, this.priceStars, this.emoji);
  final String id;
  final String name;
  final int priceStars;
  final String emoji;
}

const _catalog = [
  _Product('sticker_pack', 'Sticker Pack', 50, '🎨'),
  _Product('premium_theme', 'Premium Chat Theme', 100, '🌈'),
  _Product('badge', 'Profile Badge', 30, '🏅'),
  _Product('boost', '7-Day Chat Boost', 150, '🚀'),
];

InlineKeyboardMarkup _catalogKeyboard() => InlineKeyboardMarkup(rows: [
      for (final p in _catalog)
        [InlineKeyboardButton.callback(text: '${p.emoji} ${p.name} — ${p.priceStars} ⭐', data: 'add:${p.id}')],
      [InlineKeyboardButton.callback(text: '🛒 View cart', data: 'cart')],
    ],);

Future<List<String>> _getCart(BotStorage storage, int userId) async {
  final raw = storage.getUserData(userId: userId, key: 'cart') as String?;
  if (raw == null) return [];
  return (jsonDecode(raw) as List).cast<String>();
}

Future<void> _saveCart(BotStorage storage, int userId, List<String> cart) =>
    storage.setUserData(userId: userId, key: 'cart', value: jsonEncode(cart));

String _cartSummary(List<String> cartIds) {
  if (cartIds.isEmpty) return 'Your cart is empty.';
  final counts = <String, int>{};
  for (final id in cartIds) {
    counts[id] = (counts[id] ?? 0) + 1;
  }
  var total = 0;
  final lines = <String>[];
  for (final entry in counts.entries) {
    final product = _catalog.firstWhere((p) => p.id == entry.key);
    final subtotal = product.priceStars * entry.value;
    total += subtotal;
    lines.add('${product.emoji} ${product.name} × ${entry.value} — $subtotal ⭐');
  }
  lines.add('\nTotal: $total ⭐');
  return lines.join('\n');
}

Future<void> _checkout(Bot bot, User user, int chatId, List<String> cart) async {
  if (cart.isEmpty) {
    await bot.sendMessage(chatId: chatId, text: 'Your cart is empty — send /shop first.');
    return;
  }
  var total = 0;
  for (final id in cart) {
    total += _catalog.firstWhere((p) => p.id == id).priceStars;
  }
  await bot.sendInvoice(
    chatId: chatId,
    title: 'Your order',
    description: '${cart.length} item(s) from the shop.',
    payload: 'order_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
    currency: 'XTR',
    prices: [
      {'label': 'Order total', 'amount': total},
    ],
  );
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'shop_data.json');
  await storage.load();

  await bot.setMyCommands(commands: [
    {'command': 'shop', 'description': 'Browse the catalog'},
    {'command': 'cart', 'description': 'View your cart'},
  ],);

  print('Shop bot running. Send /shop to browse.');

  await for (final update in bot.poll()) {
    final user = update.from;
    final chatId = update.chatId;
    if (user == null || chatId == null) continue;
    await storage.saveUser(user: user);

    final text = update.text;
    final callback = update.callbackQuery;
    final preCheckout = update.preCheckoutQuery;

    if (preCheckout != null) {
      // Telegram holds the payment until this is answered — must reply
      // within 10 seconds or the payment is cancelled automatically.
      await bot.answerPreCheckoutQuery(preCheckoutQueryId: preCheckout.id, ok: true);
    } else if (text == '/shop' || text == '/start') {
      await bot.sendMessage(chatId: chatId, text: 'Welcome to the shop! Tap an item to add it to your cart.', replyMarkup: _catalogKeyboard());
    } else if (text == '/cart') {
      final cart = await _getCart(storage, user.id);
      await bot.sendMessage(chatId: chatId, text: _cartSummary(cart));
    } else if (callback != null) {
      final data = callback.data ?? '';
      if (data.startsWith('add:')) {
        final productId = data.substring('add:'.length);
        final cart = await _getCart(storage, user.id);
        cart.add(productId);
        await _saveCart(storage, user.id, cart);
        final product = _catalog.firstWhere((p) => p.id == productId);
        await bot.answerCallbackQuery(callbackQueryId: callback.id, text: 'Added ${product.name} to your cart!');
      } else if (data == 'cart') {
        final cart = await _getCart(storage, user.id);
        await bot.answerCallbackQuery(callbackQueryId: callback.id);
        await bot.sendMessage(
          chatId: chatId,
          text: _cartSummary(cart),
          replyMarkup: cart.isEmpty
              ? null
              : InlineKeyboardMarkup.single(row: [InlineKeyboardButton.callback(text: '💳 Checkout', data: 'checkout')]),
        );
      } else if (data == 'checkout') {
        final cart = await _getCart(storage, user.id);
        await bot.answerCallbackQuery(callbackQueryId: callback.id);
        await _checkout(bot, user, chatId, cart);
      }
    } else if (text == '/checkout') {
      final cart = await _getCart(storage, user.id);
      await _checkout(bot, user, chatId, cart);
    } else if (update.message?.successfulPayment != null) {
      await _saveCart(storage, user.id, []);
      await bot.sendMessage(chatId: chatId, text: 'Payment received — thank you! Your cart has been cleared.');
    }
  }
}
