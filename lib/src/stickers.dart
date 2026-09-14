import 'core.dart';
import 'enums.dart';
import 'input_file.dart';

/// A sticker to be added to a set via [Bot.addStickerToSet] or included in a
/// new set via [Bot.createNewStickerSet].
///
/// ```dart
/// final sticker = InputSticker(
///   sticker: InputFile.path(path: 'assets/sticker.png'),
///   format: StickerFormat.static,
///   emojiList: ['😀', '😄'],
/// );
///
/// await bot.createNewStickerSet(
///   userId: update.userId!,
///   name: 'my_pack_by_yourbot',
///   title: 'My Pack',
///   stickers: [sticker],
/// );
/// ```
class InputSticker {
  /// The sticker file itself, typically uploaded via [InputFile.path]/[InputFile.bytes]
  /// or reused from [Bot.uploadStickerFile]'s returned `file_id`.
  final InputFile sticker;

  /// The technical file format of [sticker].
  final StickerFormat format;

  /// One or more emoji that represent this sticker's meaning, used for search.
  final List<String> emojiList;

  /// For mask stickers, where on the face this sticker should be anchored.
  final Json? maskPosition;

  /// Extra search keywords for this sticker (regular stickers only, max 20).
  final List<String>? keywords;

  /// Creates an input sticker from [sticker], its [format], and its [emojiList].
  const InputSticker({
    required this.sticker,
    required this.format,
    required this.emojiList,
    this.maskPosition,
    this.keywords,
  });

  /// Converts this sticker to the JSON shape Telegram's API expects, given
  /// [ref] — the resolved `file_id`/URL/attach-name string for [sticker].
  Json toJson(String ref) => {
        'sticker': ref,
        'format': format.value,
        'emoji_list': emojiList,
        if (maskPosition != null) 'mask_position': maskPosition,
        if (keywords != null) 'keywords': keywords,
      };
}
