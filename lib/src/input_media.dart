import 'core.dart';
import 'enums.dart';
import 'input_file.dart';

/// Base class for a single item inside an album sent via [Bot.sendMediaGroup],
/// or for the replacement media passed to [Bot.editMessageMedia].
///
/// Use a concrete subtype — [InputMediaPhoto], [InputMediaVideo],
/// [InputMediaAnimation], [InputMediaAudio], or [InputMediaDocument] —
/// depending on the kind of media you're sending.
abstract class InputMedia {
  /// The Telegram media type string (`'photo'`, `'video'`, etc).
  final String type;
  final InputFile media;
  final InputFile? thumbnail;
  final String? caption;
  final ParseMode? parseMode;
  final List<Json>? captionEntities;
  final bool? showCaptionAboveMedia;

  const InputMedia(
    this.type,
    this.media, {
    this.thumbnail,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
  });

  Json baseJson(String mediaRef, {String? thumbRef}) => {
        'type': type,
        'media': mediaRef,
        if (thumbRef != null) 'thumbnail': thumbRef,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null) 'show_caption_above_media': showCaptionAboveMedia,
      };

  Json extraJson();

  Json toJson(String mediaRef, {String? thumbRef}) => {
        ...baseJson(mediaRef, thumbRef: thumbRef),
        ...extraJson(),
      };
}

/// A photo used as one item of an album in [Bot.sendMediaGroup].
class InputMediaPhoto extends InputMedia {
  /// Whether the photo is blurred until the user taps to reveal it.
  final bool? hasSpoiler;

  const InputMediaPhoto(
    InputFile media, {
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    this.hasSpoiler,
  }) : super('photo', media,
            caption: caption,
            parseMode: parseMode,
            captionEntities: captionEntities,
            showCaptionAboveMedia: showCaptionAboveMedia,);

  @override
  Json extraJson() => {if (hasSpoiler != null) 'has_spoiler': hasSpoiler};
}

/// A video used as one item of an album in [Bot.sendMediaGroup].
class InputMediaVideo extends InputMedia {
  /// The video's width in pixels, if known.
  final int? width;

  /// The video's height in pixels, if known.
  final int? height;

  /// The video's duration in seconds, if known.
  final int? duration;

  /// Whether the video can be streamed rather than fully downloaded first.
  final bool? supportsStreaming;

  /// Whether the video is blurred until the user taps to reveal it.
  final bool? hasSpoiler;

  const InputMediaVideo(
    InputFile media, {
    InputFile? thumbnail,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    this.width,
    this.height,
    this.duration,
    this.supportsStreaming,
    this.hasSpoiler,
  }) : super('video', media,
            thumbnail: thumbnail,
            caption: caption,
            parseMode: parseMode,
            captionEntities: captionEntities,
            showCaptionAboveMedia: showCaptionAboveMedia,);

  @override
  Json extraJson() => {
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (duration != null) 'duration': duration,
        if (supportsStreaming != null) 'supports_streaming': supportsStreaming,
        if (hasSpoiler != null) 'has_spoiler': hasSpoiler,
      };
}

/// A GIF or silent, looping MP4 animation used as one item of an album in [Bot.sendMediaGroup].
class InputMediaAnimation extends InputMedia {
  /// The animation's width in pixels, if known.
  final int? width;

  /// The animation's height in pixels, if known.
  final int? height;

  /// The animation's duration in seconds, if known.
  final int? duration;

  /// Whether the animation is blurred until the user taps to reveal it.
  final bool? hasSpoiler;

  const InputMediaAnimation(
    InputFile media, {
    InputFile? thumbnail,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    this.width,
    this.height,
    this.duration,
    this.hasSpoiler,
  }) : super('animation', media,
            thumbnail: thumbnail,
            caption: caption,
            parseMode: parseMode,
            captionEntities: captionEntities,
            showCaptionAboveMedia: showCaptionAboveMedia,);

  @override
  Json extraJson() => {
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (duration != null) 'duration': duration,
        if (hasSpoiler != null) 'has_spoiler': hasSpoiler,
      };
}

/// An audio file used as one item of an album in [Bot.sendMediaGroup].
class InputMediaAudio extends InputMedia {
  /// The audio's duration in seconds, if known.
  final int? duration;

  /// The performer/artist name shown in the music player UI.
  final String? performer;

  /// The track title shown in the music player UI.
  final String? title;

  const InputMediaAudio(
    InputFile media, {
    InputFile? thumbnail,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    this.duration,
    this.performer,
    this.title,
  }) : super('audio', media,
            thumbnail: thumbnail,
            caption: caption,
            parseMode: parseMode,
            captionEntities: captionEntities,);

  @override
  Json extraJson() => {
        if (duration != null) 'duration': duration,
        if (performer != null) 'performer': performer,
        if (title != null) 'title': title,
      };
}

/// A generic file used as one item of an album in [Bot.sendMediaGroup].
class InputMediaDocument extends InputMedia {
  /// Disables automatic server-side content-type detection for files sent
  /// as part of an album where the type should not be guessed from content.
  final bool? disableContentTypeDetection;

  const InputMediaDocument(
    InputFile media, {
    InputFile? thumbnail,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    this.disableContentTypeDetection,
  }) : super('document', media,
            thumbnail: thumbnail,
            caption: caption,
            parseMode: parseMode,
            captionEntities: captionEntities,);

  @override
  Json extraJson() => {
        if (disableContentTypeDetection != null)
          'disable_content_type_detection': disableContentTypeDetection,
      };
}
