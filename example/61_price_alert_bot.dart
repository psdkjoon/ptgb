// A complete, deployable bot: set a price alert for a cryptocurrency and
// get notified the moment it crosses your target — no exchange account or
// API key needed, using CoinGecko's public, keyless price endpoint.
//
// Usage: /alert bitcoin above 70000   (or "below")
// The bot checks prices every minute alongside polling for messages (see
// `55_rss_notifier_bot.dart` for more on the Timer.periodic + Bot.poll
// side-by-side pattern this also uses). Alerts persist via [BotStorage]
// and are removed once triggered.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ptgb/ptgb.dart';

Future<double?> _fetchPrice(String coinId) async {
  final url = Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$coinId&vs_currencies=usd');
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    if (response.statusCode != 200) return null;
    final json = jsonDecode(body) as Map<String, dynamic>;
    final coin = json[coinId] as Map<String, dynamic>?;
    return (coin?['usd'] as num?)?.toDouble();
  } finally {
    client.close();
  }
}

class _Alert {
  _Alert(this.chatId, this.coinId, this.above, this.target);
  final int chatId;
  final String coinId;
  final bool above; // true = notify when price rises above target
  final double target;

  Map<String, dynamic> toJson() => {'chatId': chatId, 'coinId': coinId, 'above': above, 'target': target};
  static _Alert fromJson(Map<String, dynamic> j) =>
      _Alert(j['chatId'] as int, j['coinId'] as String, j['above'] as bool, (j['target'] as num).toDouble());
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'price_alerts_data.json');
  await storage.load();
  await storage.saveChat(chat: Chat({'id': 0, 'type': 'private'}));

  Future<List<_Alert>> loadAlerts() async {
    final raw = storage.getChatData(chatId: 0, key: 'alerts') as String?;
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((j) => _Alert.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> saveAlerts(List<_Alert> alerts) =>
      storage.setChatData(chatId: 0, key: 'alerts', value: jsonEncode(alerts.map((a) => a.toJson()).toList()));

  Future<void> checkAlerts() async {
    final alerts = await loadAlerts();
    if (alerts.isEmpty) return;
    final coinIds = alerts.map((a) => a.coinId).toSet();
    final prices = <String, double?>{};
    for (final id in coinIds) {
      prices[id] = await _fetchPrice(id);
    }
    final triggered = <_Alert>[];
    for (final alert in alerts) {
      final price = prices[alert.coinId];
      if (price == null) continue;
      final crossed = alert.above ? price >= alert.target : price <= alert.target;
      if (crossed) {
        triggered.add(alert);
        await bot.sendMessage(
          chatId: alert.chatId,
          text: '🚨 ${alert.coinId} is now \$${price.toStringAsFixed(2)}, ${alert.above ? 'above' : 'below'} your target of \$${alert.target.toStringAsFixed(2)}!',
        );
      }
    }
    if (triggered.isNotEmpty) {
      alerts.removeWhere(triggered.contains);
      await saveAlerts(alerts);
    }
  }

  Timer.periodic(const Duration(minutes: 1), (_) => checkAlerts());

  await bot.setMyCommands(commands: [
    {'command': 'alert', 'description': 'Set a price alert, e.g. /alert bitcoin above 70000'},
    {'command': 'alerts', 'description': 'List your active alerts'},
  ],);

  print('Price alert bot running.');

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text.startsWith('/alert ')) {
      final match = RegExp(r'^/alert\s+(\S+)\s+(above|below)\s+([\d.]+)$').firstMatch(text);
      if (match == null) {
        await bot.sendMessage(chatId: chatId, text: 'Format: /alert bitcoin above 70000');
        continue;
      }
      final coinId = match.group(1)!.toLowerCase();
      final above = match.group(2) == 'above';
      final target = double.parse(match.group(3)!);
      final currentPrice = await _fetchPrice(coinId);
      if (currentPrice == null) {
        await bot.sendMessage(chatId: chatId, text: 'Couldn\'t find a coin called "$coinId" — use CoinGecko\'s id format, e.g. "bitcoin", "ethereum".');
        continue;
      }
      final alerts = await loadAlerts();
      alerts.add(_Alert(chatId, coinId, above, target));
      await saveAlerts(alerts);
      await bot.sendMessage(
        chatId: chatId,
        text: 'Alert set! Currently \$${currentPrice.toStringAsFixed(2)} — you\'ll be notified when it goes ${match.group(2)} \$${target.toStringAsFixed(2)}.',
      );
    } else if (text == '/alerts') {
      final alerts = (await loadAlerts()).where((a) => a.chatId == chatId).toList();
      await bot.sendMessage(
        chatId: chatId,
        text: alerts.isEmpty
            ? 'No active alerts. Set one with /alert bitcoin above 70000.'
            : alerts.map((a) => '${a.coinId} ${a.above ? 'above' : 'below'} \$${a.target.toStringAsFixed(2)}').join('\n'),
      );
    } else if (text == '/start') {
      await bot.sendMessage(chatId: chatId, text: 'Set a price alert with /alert <coingecko-id> above|below <price>, e.g. /alert bitcoin above 70000.');
    }
  }
}
