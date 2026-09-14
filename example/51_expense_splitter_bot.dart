// A complete, deployable bot: track shared group expenses and settle up.
// Add expenses with who paid and who it's split between, and the bot
// keeps a running balance of who owes whom — the same idea as Splitwise,
// simplified to fit in one file.
//
// Usage in a group:
//   /paid Alice 60 for dinner
//   /owe Bob 15       (records that Bob individually owes the payer)
//   /balances         (shows the net balance for everyone tracked)
//   /settle Bob Alice (records that Bob paid Alice back, zeroing that debt)
//
// Names are matched against whoever has talked in the group before
// (tracked automatically via BotStorage), so people don't need to type
// exact @usernames.

import 'dart:convert';

import 'package:ptgb/ptgb.dart';

/// Balances are stored per-chat as a JSON map of "debtorId:creditorId" ->
/// amount owed, attached to the chat's custom data.
Future<Map<String, double>> _getBalances(BotStorage storage, int chatId) async {
  final raw = storage.getChatData(chatId: chatId, key: 'balances') as String?;
  if (raw == null) return {};
  return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()));
}

Future<void> _saveBalances(BotStorage storage, int chatId, Map<String, double> balances) =>
    storage.setChatData(chatId: chatId, key: 'balances', value: jsonEncode(balances));

/// Records that [debtorId] owes [creditorId] [amount], net against any
/// existing debt the other way (so if Bob already owed Alice, and Alice
/// now owes Bob, the two debts cancel out instead of stacking).
void _addDebt(Map<String, double> balances, int debtorId, int creditorId, double amount) {
  final forwardKey = '$debtorId:$creditorId';
  final reverseKey = '$creditorId:$debtorId';
  final existingReverse = balances[reverseKey] ?? 0;
  if (existingReverse >= amount) {
    balances[reverseKey] = existingReverse - amount;
    if (balances[reverseKey] == 0) balances.remove(reverseKey);
  } else {
    balances.remove(reverseKey);
    balances[forwardKey] = (balances[forwardKey] ?? 0) + (amount - existingReverse);
  }
}

Future<StoredUser?> _findUserByName(BotStorage storage, String name) async {
  final matches = storage.allUsers().where((u) => u.firstName.toLowerCase() == name.toLowerCase());
  return matches.isEmpty ? null : matches.first;
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'expenses_data.json');
  await storage.load();

  print('Expense splitter bot running.');

  await for (final update in bot.poll()) {
    final chatId = update.chatId;
    final text = update.text;
    final user = update.from;
    if (chatId == null || text == null || user == null) continue;
    await storage.saveUser(user: user);
    await storage.saveChat(chat: update.chat!);

    if (text.startsWith('/paid ')) {
      // /paid <name> <amount> for <description>  — payer defaults to the sender
      final match = RegExp(r'^/paid\s+(\S+)\s+([\d.]+)\s*(?:for\s+(.*))?$').firstMatch(text);
      if (match == null) {
        await bot.sendMessage(chatId: chatId, text: 'Format: /paid <name> <amount> for <what>');
        continue;
      }
      final payerName = match.group(1)!;
      final amount = double.tryParse(match.group(2)!);
      final description = match.group(3) ?? 'an expense';
      final payer = await _findUserByName(storage, payerName);
      if (amount == null || payer == null) {
        await bot.sendMessage(chatId: chatId, text: 'Couldn\'t find "$payerName" or parse the amount.');
        continue;
      }
      // The sender owes the payer their share (here: the whole amount,
      // for a simple 2-person split — extend to split N ways as needed).
      final balances = await _getBalances(storage, chatId);
      _addDebt(balances, user.id, payer.id, amount);
      await _saveBalances(storage, chatId, balances);
      await bot.sendMessage(chatId: chatId, text: '${user.firstName} owes ${payer.firstName} \$${amount.toStringAsFixed(2)} for $description.');
    } else if (text.startsWith('/owe ')) {
      // /owe <name> <amount> — sender owes <name> directly
      final match = RegExp(r'^/owe\s+(\S+)\s+([\d.]+)$').firstMatch(text);
      if (match == null) {
        await bot.sendMessage(chatId: chatId, text: 'Format: /owe <name> <amount>');
        continue;
      }
      final creditor = await _findUserByName(storage, match.group(1)!);
      final amount = double.tryParse(match.group(2)!);
      if (amount == null || creditor == null) {
        await bot.sendMessage(chatId: chatId, text: 'Couldn\'t find that person or parse the amount.');
        continue;
      }
      final balances = await _getBalances(storage, chatId);
      _addDebt(balances, user.id, creditor.id, amount);
      await _saveBalances(storage, chatId, balances);
      await bot.sendMessage(chatId: chatId, text: 'Recorded: ${user.firstName} owes ${creditor.firstName} \$${amount.toStringAsFixed(2)}.');
    } else if (text.startsWith('/settle ')) {
      // /settle <debtorName> <creditorName> — zeroes that specific debt
      final parts = text.substring('/settle '.length).trim().split(RegExp(r'\s+'));
      if (parts.length != 2) {
        await bot.sendMessage(chatId: chatId, text: 'Format: /settle <who paid back> <who they paid>');
        continue;
      }
      final debtor = await _findUserByName(storage, parts[0]);
      final creditor = await _findUserByName(storage, parts[1]);
      if (debtor == null || creditor == null) {
        await bot.sendMessage(chatId: chatId, text: 'Couldn\'t find one of those people.');
        continue;
      }
      final balances = await _getBalances(storage, chatId);
      balances.remove('${debtor.id}:${creditor.id}');
      await _saveBalances(storage, chatId, balances);
      await bot.sendMessage(chatId: chatId, text: 'Settled: ${debtor.firstName} → ${creditor.firstName}.');
    } else if (text == '/balances') {
      final balances = await _getBalances(storage, chatId);
      if (balances.isEmpty) {
        await bot.sendMessage(chatId: chatId, text: 'Everyone\'s settled up! 🎉');
        continue;
      }
      final lines = <String>[];
      for (final entry in balances.entries) {
        final ids = entry.key.split(':');
        final debtor = storage.getUser(userId: int.parse(ids[0]));
        final creditor = storage.getUser(userId: int.parse(ids[1]));
        lines.add('${debtor?.firstName ?? ids[0]} owes ${creditor?.firstName ?? ids[1]}: \$${entry.value.toStringAsFixed(2)}');
      }
      await bot.sendMessage(chatId: chatId, text: lines.join('\n'));
    } else if (text == '/start' || text == '/help') {
      await bot.sendMessage(
        chatId: chatId,
        text: 'Track shared expenses:\n'
            '/paid <name> <amount> for <what> — you owe them their share\n'
            '/owe <name> <amount> — you owe them directly\n'
            '/settle <who paid> <who they paid> — clear a debt\n'
            '/balances — see who owes whom',
      );
    }
  }
}
