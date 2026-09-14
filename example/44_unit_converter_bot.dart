// A complete, deployable bot: unit and currency conversion, usable inline
// in ANY chat (you don't even need to add the bot to a group — just type
// `@yourbot 10 km to mi` in any chat's message box).
//
// Supports:
//   - Length: km, mi, m, ft, cm, in
//   - Weight: kg, lb, g, oz
//   - Temperature: c, f, k
//   - A tiny built-in currency table (usd, eur, gbp, jpy) using fixed
//     illustrative rates — swap `_currencyRates` for a live API call
//     (see `51_weather_bot.dart` for the pattern) in a real deployment.
//
// Try inline: `@yourbot 5 kg to lb`, `@yourbot 100 f to c`, `@yourbot 20 usd to eur`.
// Also works as a plain command: `/convert 5 kg to lb`.

import 'package:ptgb/ptgb.dart';

// Everything expressed as "how many base units is 1 of this unit".
const _lengthToMeters = {
  'km': 1000.0, 'm': 1.0, 'cm': 0.01,
  'mi': 1609.344, 'ft': 0.3048, 'in': 0.0254,
};
const _weightToGrams = {
  'kg': 1000.0, 'g': 1.0,
  'lb': 453.592, 'oz': 28.3495,
};
// Illustrative fixed rates (units per 1 USD). Replace with a live lookup
// (e.g. an exchangerate.host or similar call) for real conversions.
const _currencyToUsd = {
  'usd': 1.0, 'eur': 0.92, 'gbp': 0.79, 'jpy': 149.5,
};

/// Parses `"10 km to mi"` / `"100 f to c"` and returns a human-readable
/// result, or `null` if the input doesn't match a supported conversion.
String? convert(String input) {
  final match = RegExp(
    r'^\s*([\d.]+)\s*([a-zA-Z]+)\s*(?:to|in|->)?\s*([a-zA-Z]+)\s*$',
  ).firstMatch(input);
  if (match == null) return null;

  final amount = double.tryParse(match.group(1)!);
  if (amount == null) return null;
  final from = match.group(2)!.toLowerCase();
  final to = match.group(3)!.toLowerCase();

  if (from == 'c' || from == 'f' || from == 'k') {
    if (to != 'c' && to != 'f' && to != 'k') return null;
    final celsius = switch (from) {
      'c' => amount,
      'f' => (amount - 32) * 5 / 9,
      _ => amount - 273.15,
    };
    final result = switch (to) {
      'c' => celsius,
      'f' => celsius * 9 / 5 + 32,
      _ => celsius + 273.15,
    };
    return '${amount.toStringAsFixed(1)}$from = ${result.toStringAsFixed(1)}$to';
  }

  if (_lengthToMeters.containsKey(from) && _lengthToMeters.containsKey(to)) {
    final meters = amount * _lengthToMeters[from]!;
    final result = meters / _lengthToMeters[to]!;
    return '${amount.toStringAsFixed(2)} $from = ${result.toStringAsFixed(4)} $to';
  }

  if (_weightToGrams.containsKey(from) && _weightToGrams.containsKey(to)) {
    final grams = amount * _weightToGrams[from]!;
    final result = grams / _weightToGrams[to]!;
    return '${amount.toStringAsFixed(2)} $from = ${result.toStringAsFixed(4)} $to';
  }

  if (_currencyToUsd.containsKey(from) && _currencyToUsd.containsKey(to)) {
    final usd = amount / _currencyToUsd[from]!;
    final result = usd * _currencyToUsd[to]!;
    return '${amount.toStringAsFixed(2)} ${from.toUpperCase()} ≈ ${result.toStringAsFixed(2)} ${to.toUpperCase()} (fixed demo rate)';
  }

  return null;
}

void main() async {
  final bot = Bot();

  await bot.setMyCommands(commands: [
    {'command': 'convert', 'description': 'Convert units, e.g. /convert 5 kg to lb'},
  ],);

  print('Unit converter bot running. Also try inline mode: @yourbot 10 km to mi');

  await for (final update in bot.poll()) {
    final inlineQuery = update.inlineQuery;
    if (inlineQuery != null) {
      final result = convert(inlineQuery.query);
      await bot.answerInlineQuery(
        inlineQueryId: inlineQuery.id,
        results: result == null
            ? []
            : [
                InlineQueryResultArticle(
                  id: 'convert',
                  title: result,
                  inputMessageContent: InputTextMessageContent(messageText: result),
                  description: 'Tap to send this conversion',
                ),
              ],
        cacheTime: 0,
      );
      continue;
    }

    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text.startsWith('/convert')) {
      final query = text.substring('/convert'.length).trim();
      final result = convert(query);
      await bot.sendMessage(
        chatId: chatId,
        text: result ?? 'Couldn\'t parse that. Try: /convert 5 kg to lb',
      );
    } else if (text == '/start') {
      await bot.sendMessage(
        chatId: chatId,
        text: 'Send /convert 5 kg to lb, or type @${(await bot.getMe()).username} 10 km to mi in any chat.',
      );
    }
  }
}
