// A complete, deployable bot: pick an available time slot from an inline
// "calendar" and book it. Slots are generated for the next 5 weekdays,
// 9am-5pm in 1-hour blocks; booked slots are removed from what others see.
// State (which slots are taken, by whom) persists via [BotStorage].
//
// This demonstrates the "menu that shrinks as it's used" pattern common to
// booking/reservation bots — the keyboard is regenerated fresh from
// current availability every time it's shown, rather than trying to
// patch an existing one.

import 'dart:convert';

import 'package:ptgb/ptgb.dart';

List<DateTime> _upcomingSlots() {
  final slots = <DateTime>[];
  var day = DateTime.now();
  var daysAdded = 0;
  while (daysAdded < 5) {
    day = day.add(const Duration(days: 1));
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) continue;
    for (var hour = 9; hour < 17; hour++) {
      slots.add(DateTime(day.year, day.month, day.day, hour));
    }
    daysAdded++;
  }
  return slots;
}

String _slotKey(DateTime slot) => slot.toIso8601String();

String _slotLabel(DateTime slot) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final hour12 = slot.hour > 12 ? slot.hour - 12 : slot.hour;
  final period = slot.hour >= 12 ? 'PM' : 'AM';
  return '${weekdays[slot.weekday - 1]} ${slot.month}/${slot.day} — $hour12:00 $period';
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'bookings_data.json');
  await storage.load();
  await storage.saveChat(chat: Chat({'id': 0, 'type': 'private'}));

  Future<Map<String, int>> loadBookings() async {
    final raw = storage.getChatData(chatId: 0, key: 'bookings') as String?;
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
  }

  Future<void> saveBookings(Map<String, int> bookings) =>
      storage.setChatData(chatId: 0, key: 'bookings', value: jsonEncode(bookings));

  Future<InlineKeyboardMarkup> availabilityKeyboard() async {
    final bookings = await loadBookings();
    final slots = _upcomingSlots().where((s) => !bookings.containsKey(_slotKey(s))).take(15);
    return InlineKeyboardMarkup(rows: [
      for (final slot in slots) [InlineKeyboardButton.callback(text: _slotLabel(slot), data: 'book:${_slotKey(slot)}')],
    ],);
  }

  await bot.setMyCommands(commands: [
    {'command': 'book', 'description': 'See available appointment slots'},
    {'command': 'mybooking', 'description': 'See your upcoming booking'},
    {'command': 'cancel', 'description': 'Cancel your booking'},
  ],);

  print('Booking bot running.');

  await for (final update in bot.poll()) {
    final user = update.from;
    final chatId = update.chatId;
    final text = update.text;
    final callback = update.callbackQuery;
    if (user == null || chatId == null) continue;
    await storage.saveUser(user: user);

    if (text == '/book' || text == '/start') {
      final keyboard = await availabilityKeyboard();
      await bot.sendMessage(
        chatId: chatId,
        text: keyboard.rows.isEmpty ? 'No slots available right now — check back later.' : 'Pick a time:',
        replyMarkup: keyboard.rows.isEmpty ? null : keyboard,
      );
    } else if (text == '/mybooking') {
      final bookings = await loadBookings();
      final mine = bookings.entries.where((e) => e.value == user.id).map((e) => DateTime.parse(e.key)).toList();
      await bot.sendMessage(
        chatId: chatId,
        text: mine.isEmpty ? 'You don\'t have a booking. Send /book to schedule one.' : 'Your booking: ${_slotLabel(mine.first)}',
      );
    } else if (text == '/cancel') {
      final bookings = await loadBookings();
      final mineKey = bookings.entries.where((e) => e.value == user.id).map((e) => e.key).firstOrNull;
      if (mineKey == null) {
        await bot.sendMessage(chatId: chatId, text: 'You don\'t have a booking to cancel.');
      } else {
        bookings.remove(mineKey);
        await saveBookings(bookings);
        await bot.sendMessage(chatId: chatId, text: 'Booking cancelled.');
      }
    } else if (callback != null) {
      final data = callback.data ?? '';
      if (data.startsWith('book:')) {
        final slotKey = data.substring('book:'.length);
        final bookings = await loadBookings();
        if (bookings.containsKey(slotKey)) {
          await bot.answerCallbackQuery(callbackQueryId: callback.id, text: 'Sorry, that slot was just taken.');
        } else if (bookings.containsValue(user.id)) {
          await bot.answerCallbackQuery(callbackQueryId: callback.id, text: 'You already have a booking — cancel it first with /cancel.');
        } else {
          bookings[slotKey] = user.id;
          await saveBookings(bookings);
          await bot.answerCallbackQuery(callbackQueryId: callback.id, text: 'Booked!');
          await bot.sendMessage(chatId: chatId, text: '✅ Booked for ${_slotLabel(DateTime.parse(slotKey))}.');
        }
      }
    }
  }
}
