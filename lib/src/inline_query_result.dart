import 'core.dart';
import 'enums.dart';
import 'input_message_content.dart';
import 'keyboards.dart';

/// A single result Telegram shows the user in response to an inline query
/// (`@yourbot ...`), passed to [Bot.answerInlineQuery] via a
/// [inlineQueryResults] list.
///
/// Use a concrete subtype depending on what kind of content the result
/// represents — a link-style [InlineQueryResultArticle], a media result
/// fetched by URL (e.g. [InlineQueryResultPhoto]), or a `...Cached...`
/// variant that reuses a `file_id` already on Telegram's servers (e.g.
/// [InlineQueryResultCachedPhoto]).
abstract class InlineQueryResult {
  /// The result type string Telegram's API expects (e.g. `'photo'`).
  final String type;

  /// Unique identifier for this result within the answer, 1-64 bytes.
  final String id;

  /// The keyboard attached to the sent message, if any.
  final InlineKeyboardMarkup? replyMarkup;

  /// The content actually sent when this result is tapped, if different
  /// from the result's own preview content.
  final InputMessageContent? inputMessageContent;

  /// Creates a result of the given [type] and [id]. Prefer a concrete
  /// subtype's constructor.
  const InlineQueryResult(
    this.type,
    this.id, {
    this.replyMarkup,
    this.inputMessageContent,
  });

  /// The fields common to every result: [type], [id], [replyMarkup], and
  /// [inputMessageContent].
  Json baseJson() => {
        'type': type,
        'id': id,
        if (replyMarkup != null) 'reply_markup': replyMarkup!.toJson(),
        if (inputMessageContent != null)
          'input_message_content': inputMessageContent!.toJson(),
      };

  /// The fields specific to this subtype. Implemented by each concrete subtype.
  Json extraJson();

  /// The full JSON shape Telegram expects for this result, combining
  /// [baseJson] and [extraJson]. Used internally by [Bot.answerInlineQuery]
  /// and friends — you don't need to call this yourself.
  Json toJson() => {...baseJson(), ...extraJson()};
}

/// A link-style result with a title and description, whose tap sends
/// [inputMessageContent] (required, since there's no other content to fall
/// back to).
class InlineQueryResultArticle extends InlineQueryResult {
  /// The result's title.
  final String title;

  /// A URL associated with the result, shown to the user.
  final String? url;

  /// A short description shown below the title.
  final String? description;

  /// A thumbnail image URL for the result.
  final String? thumbnailUrl;

  /// Thumbnail width, if known.
  final int? thumbnailWidth;

  /// Thumbnail height, if known.
  final int? thumbnailHeight;

  /// Creates an article result. [inputMessageContent] is required since an
  /// article has no other content to send.
  const InlineQueryResultArticle(
    String id,
    this.title,
    InputMessageContent inputMessageContent, {
    InlineKeyboardMarkup? replyMarkup,
    this.url,
    this.description,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
  }) : super(
          'article',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'title': title,
        if (url != null) 'url': url,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (thumbnailWidth != null) 'thumbnail_width': thumbnailWidth,
        if (thumbnailHeight != null) 'thumbnail_height': thumbnailHeight,
      };
}

/// A photo result, fetched by [photoUrl].
class InlineQueryResultPhoto extends InlineQueryResult {
  /// A URL of the full-size photo (max 5MB, JPEG).
  final String photoUrl;

  /// A URL of a thumbnail for the photo.
  final String thumbnailUrl;

  /// Photo width, if known.
  final int? photoWidth;

  /// Photo height, if known.
  final int? photoHeight;

  /// A title shown with the result in the picker.
  final String? title;

  /// A short description shown with the result in the picker.
  final String? description;

  /// The caption sent with the photo (1024 characters max).
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Whether [caption] is shown above the photo instead of below it.
  final bool? showCaptionAboveMedia;

  /// Creates a photo result fetched from [photoUrl].
  const InlineQueryResultPhoto(
    String id,
    this.photoUrl,
    this.thumbnailUrl, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.photoWidth,
    this.photoHeight,
    this.title,
    this.description,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
  }) : super(
          'photo',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'photo_url': photoUrl,
        'thumbnail_url': thumbnailUrl,
        if (photoWidth != null) 'photo_width': photoWidth,
        if (photoHeight != null) 'photo_height': photoHeight,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
      };
}

/// A GIF animation result, fetched by [gifUrl].
class InlineQueryResultGif extends InlineQueryResult {
  /// A URL of the GIF file (max 1MB for photo-quality, or up to 5MB).
  final String gifUrl;

  /// GIF width, if known.
  final int? gifWidth;

  /// GIF height, if known.
  final int? gifHeight;

  /// GIF duration in seconds, if known.
  final int? gifDuration;

  /// A URL of a static (JPEG) or animated (MP4/GIF) thumbnail for the result.
  final String thumbnailUrl;

  /// MIME type of [thumbnailUrl] — `'image/jpeg'`, `'image/gif'`, or `'video/mp4'`.
  final String? thumbnailMimeType;

  /// A title shown with the result in the picker.
  final String? title;

  /// The caption sent with the GIF.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Whether [caption] is shown above the GIF instead of below it.
  final bool? showCaptionAboveMedia;

  /// Creates a GIF result fetched from [gifUrl].
  const InlineQueryResultGif(
    String id,
    this.gifUrl,
    this.thumbnailUrl, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.gifWidth,
    this.gifHeight,
    this.gifDuration,
    this.thumbnailMimeType,
    this.title,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
  }) : super(
          'gif',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'gif_url': gifUrl,
        'thumbnail_url': thumbnailUrl,
        if (gifWidth != null) 'gif_width': gifWidth,
        if (gifHeight != null) 'gif_height': gifHeight,
        if (gifDuration != null) 'gif_duration': gifDuration,
        if (thumbnailMimeType != null) 'thumbnail_mime_type': thumbnailMimeType,
        if (title != null) 'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
      };
}

/// A silent, looping H.264/MPEG-4 animation result, fetched by [mpeg4Url].
class InlineQueryResultMpeg4Gif extends InlineQueryResult {
  /// A URL of the MP4 file.
  final String mpeg4Url;

  /// Video width, if known.
  final int? mpeg4Width;

  /// Video height, if known.
  final int? mpeg4Height;

  /// Video duration in seconds, if known.
  final int? mpeg4Duration;

  /// A URL of a static (JPEG) or animated (MP4/GIF) thumbnail for the result.
  final String thumbnailUrl;

  /// MIME type of [thumbnailUrl] — `'image/jpeg'`, `'image/gif'`, or `'video/mp4'`.
  final String? thumbnailMimeType;

  /// A title shown with the result in the picker.
  final String? title;

  /// The caption sent with the animation.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Whether [caption] is shown above the animation instead of below it.
  final bool? showCaptionAboveMedia;

  /// Creates an MP4 animation result fetched from [mpeg4Url].
  const InlineQueryResultMpeg4Gif(
    String id,
    this.mpeg4Url,
    this.thumbnailUrl, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.mpeg4Width,
    this.mpeg4Height,
    this.mpeg4Duration,
    this.thumbnailMimeType,
    this.title,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
  }) : super(
          'mpeg4_gif',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'mpeg4_url': mpeg4Url,
        'thumbnail_url': thumbnailUrl,
        if (mpeg4Width != null) 'mpeg4_width': mpeg4Width,
        if (mpeg4Height != null) 'mpeg4_height': mpeg4Height,
        if (mpeg4Duration != null) 'mpeg4_duration': mpeg4Duration,
        if (thumbnailMimeType != null) 'thumbnail_mime_type': thumbnailMimeType,
        if (title != null) 'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
      };
}

/// A video result, fetched by [videoUrl].
class InlineQueryResultVideo extends InlineQueryResult {
  /// A URL of the video (an embeddable page for `'text/html'`, or an MP4 file for `'video/mp4'`).
  final String videoUrl;

  /// MIME type of [videoUrl] — `'text/html'` or `'video/mp4'`.
  final String mimeType;

  /// A URL of a thumbnail for the video.
  final String thumbnailUrl;

  /// A title shown with the result in the picker.
  final String title;

  /// The caption sent with the video.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Whether [caption] is shown above the video instead of below it.
  final bool? showCaptionAboveMedia;

  /// Video width, if known.
  final int? videoWidth;

  /// Video height, if known.
  final int? videoHeight;

  /// Video duration in seconds, if known.
  final int? videoDuration;

  /// A short description shown with the result in the picker.
  final String? description;

  /// Creates a video result fetched from [videoUrl]. Since embedded videos
  /// (`'text/html'`) can't be sent directly to a chat, set
  /// [inputMessageContent] when using that MIME type.
  const InlineQueryResultVideo(
    String id,
    this.videoUrl,
    this.mimeType,
    this.thumbnailUrl,
    this.title, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
    this.videoWidth,
    this.videoHeight,
    this.videoDuration,
    this.description,
  }) : super(
          'video',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'video_url': videoUrl,
        'mime_type': mimeType,
        'thumbnail_url': thumbnailUrl,
        'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
        if (videoWidth != null) 'video_width': videoWidth,
        if (videoHeight != null) 'video_height': videoHeight,
        if (videoDuration != null) 'video_duration': videoDuration,
        if (description != null) 'description': description,
      };
}

/// An audio file result, fetched by [audioUrl].
class InlineQueryResultAudio extends InlineQueryResult {
  /// A URL of the audio file (MP3 only, so far as Telegram documents).
  final String audioUrl;

  /// A title shown with the result in the picker.
  final String title;

  /// The caption sent with the audio.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Performer, shown alongside [title].
  final String? performer;

  /// Audio duration in seconds, if known.
  final int? audioDuration;

  /// Creates an audio result fetched from [audioUrl].
  const InlineQueryResultAudio(
    String id,
    this.audioUrl,
    this.title, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.performer,
    this.audioDuration,
  }) : super(
          'audio',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'audio_url': audioUrl,
        'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (performer != null) 'performer': performer,
        if (audioDuration != null) 'audio_duration': audioDuration,
      };
}

/// A voice recording result, fetched by [voiceUrl].
class InlineQueryResultVoice extends InlineQueryResult {
  /// A URL of the voice recording (`.ogg` container with OPUS, so far as Telegram documents).
  final String voiceUrl;

  /// A title shown with the result in the picker.
  final String title;

  /// The caption sent with the voice message.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Voice message duration in seconds, if known.
  final int? voiceDuration;

  /// Creates a voice result fetched from [voiceUrl].
  const InlineQueryResultVoice(
    String id,
    this.voiceUrl,
    this.title, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.voiceDuration,
  }) : super(
          'voice',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'voice_url': voiceUrl,
        'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (voiceDuration != null) 'voice_duration': voiceDuration,
      };
}

/// A generic file result, fetched by [documentUrl].
class InlineQueryResultDocument extends InlineQueryResult {
  /// A title shown with the result in the picker.
  final String title;

  /// The caption sent with the file.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// A URL of the file (`.pdf` or `.zip`, so far as Telegram documents).
  final String documentUrl;

  /// MIME type of [documentUrl] — `'application/pdf'` or `'application/zip'`.
  final String mimeType;

  /// A short description shown with the result in the picker.
  final String? description;

  /// A URL of a thumbnail for the result.
  final String? thumbnailUrl;

  /// Thumbnail width, if known.
  final int? thumbnailWidth;

  /// Thumbnail height, if known.
  final int? thumbnailHeight;

  /// Creates a document result fetched from [documentUrl].
  const InlineQueryResultDocument(
    String id,
    this.title,
    this.documentUrl,
    this.mimeType, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.description,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
  }) : super(
          'document',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        'document_url': documentUrl,
        'mime_type': mimeType,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (thumbnailWidth != null) 'thumbnail_width': thumbnailWidth,
        if (thumbnailHeight != null) 'thumbnail_height': thumbnailHeight,
      };
}

/// A point-on-the-map result.
class InlineQueryResultLocation extends InlineQueryResult {
  /// Latitude.
  final double latitude;

  /// Longitude.
  final double longitude;

  /// A title shown with the result in the picker.
  final String title;

  /// The radius of uncertainty for the location, in meters.
  final double? horizontalAccuracy;

  /// Set to share a live, periodically updating location instead of a static point.
  final int? livePeriod;

  /// Direction the user is moving in, in degrees, for a live location.
  final int? heading;

  /// Maximum distance (meters) for proximity alerts, for a live location.
  final int? proximityAlertRadius;

  /// A URL of a thumbnail for the result.
  final String? thumbnailUrl;

  /// Thumbnail width, if known.
  final int? thumbnailWidth;

  /// Thumbnail height, if known.
  final int? thumbnailHeight;

  /// Creates a location result at [latitude]/[longitude].
  const InlineQueryResultLocation(
    String id,
    this.latitude,
    this.longitude,
    this.title, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.horizontalAccuracy,
    this.livePeriod,
    this.heading,
    this.proximityAlertRadius,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
  }) : super(
          'location',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'title': title,
        if (horizontalAccuracy != null)
          'horizontal_accuracy': horizontalAccuracy,
        if (livePeriod != null) 'live_period': livePeriod,
        if (heading != null) 'heading': heading,
        if (proximityAlertRadius != null)
          'proximity_alert_radius': proximityAlertRadius,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (thumbnailWidth != null) 'thumbnail_width': thumbnailWidth,
        if (thumbnailHeight != null) 'thumbnail_height': thumbnailHeight,
      };
}

/// A venue (a location plus a name/address) result.
class InlineQueryResultVenue extends InlineQueryResult {
  /// Latitude of the venue.
  final double latitude;

  /// Longitude of the venue.
  final double longitude;

  /// The venue's name.
  final String title;

  /// The venue's address.
  final String address;

  /// Foursquare identifier of the venue, if known.
  final String? foursquareId;

  /// Foursquare type of the venue, if known.
  final String? foursquareType;

  /// Google Places identifier of the venue, if known.
  final String? googlePlaceId;

  /// Google Places type of the venue, if known.
  final String? googlePlaceType;

  /// A URL of a thumbnail for the result.
  final String? thumbnailUrl;

  /// Thumbnail width, if known.
  final int? thumbnailWidth;

  /// Thumbnail height, if known.
  final int? thumbnailHeight;

  /// Creates a venue result.
  const InlineQueryResultVenue(
    String id,
    this.latitude,
    this.longitude,
    this.title,
    this.address, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.foursquareId,
    this.foursquareType,
    this.googlePlaceId,
    this.googlePlaceType,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
  }) : super(
          'venue',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'title': title,
        'address': address,
        if (foursquareId != null) 'foursquare_id': foursquareId,
        if (foursquareType != null) 'foursquare_type': foursquareType,
        if (googlePlaceId != null) 'google_place_id': googlePlaceId,
        if (googlePlaceType != null) 'google_place_type': googlePlaceType,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (thumbnailWidth != null) 'thumbnail_width': thumbnailWidth,
        if (thumbnailHeight != null) 'thumbnail_height': thumbnailHeight,
      };
}

/// A phone contact card result.
class InlineQueryResultContact extends InlineQueryResult {
  /// The contact's phone number.
  final String phoneNumber;

  /// The contact's first name.
  final String firstName;

  /// The contact's last name, if any.
  final String? lastName;

  /// The contact's vCard, if any.
  final String? vcard;

  /// A URL of a thumbnail for the result.
  final String? thumbnailUrl;

  /// Thumbnail width, if known.
  final int? thumbnailWidth;

  /// Thumbnail height, if known.
  final int? thumbnailHeight;

  /// Creates a contact result.
  const InlineQueryResultContact(
    String id,
    this.phoneNumber,
    this.firstName, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.lastName,
    this.vcard,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
  }) : super(
          'contact',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'phone_number': phoneNumber,
        'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (vcard != null) 'vcard': vcard,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (thumbnailWidth != null) 'thumbnail_width': thumbnailWidth,
        if (thumbnailHeight != null) 'thumbnail_height': thumbnailHeight,
      };
}

/// A Telegram Game result.
class InlineQueryResultGame extends InlineQueryResult {
  /// The short name of the game, as registered with @BotFather.
  final String gameShortName;

  /// Creates a game result for [gameShortName].
  const InlineQueryResultGame(
    String id,
    this.gameShortName, {
    InlineKeyboardMarkup? replyMarkup,
  }) : super('game', id, replyMarkup: replyMarkup);

  @override
  Json extraJson() => {'game_short_name': gameShortName};
}

/// A sticker result, fetched by [stickerUrl].
class InlineQueryResultSticker extends InlineQueryResult {
  /// A URL of the sticker (`.webp`, `.tgs`, or `.webm`).
  final String stickerUrl;

  /// Creates a sticker result fetched from [stickerUrl].
  const InlineQueryResultSticker(
    String id,
    this.stickerUrl, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
  }) : super(
          'sticker',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {'sticker_url': stickerUrl};
}

/// A photo result reused from a `file_id` already on Telegram's servers.
class InlineQueryResultCachedPhoto extends InlineQueryResult {
  /// The `file_id` of the photo.
  final String photoFileId;

  /// A title shown with the result in the picker.
  final String? title;

  /// A short description shown with the result in the picker.
  final String? description;

  /// The caption sent with the photo.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Whether [caption] is shown above the photo instead of below it.
  final bool? showCaptionAboveMedia;

  /// Creates a cached-photo result from [photoFileId].
  const InlineQueryResultCachedPhoto(
    String id,
    this.photoFileId, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.title,
    this.description,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
  }) : super(
          'photo',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'photo_file_id': photoFileId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
      };
}

/// A GIF result reused from a `file_id` already on Telegram's servers.
class InlineQueryResultCachedGif extends InlineQueryResult {
  /// The `file_id` of the GIF.
  final String gifFileId;

  /// A title shown with the result in the picker.
  final String? title;

  /// The caption sent with the GIF.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Whether [caption] is shown above the GIF instead of below it.
  final bool? showCaptionAboveMedia;

  /// Creates a cached-GIF result from [gifFileId].
  const InlineQueryResultCachedGif(
    String id,
    this.gifFileId, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.title,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
  }) : super(
          'gif',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'gif_file_id': gifFileId,
        if (title != null) 'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
      };
}

/// A silent, looping MP4 animation result reused from a `file_id` already
/// on Telegram's servers.
class InlineQueryResultCachedMpeg4Gif extends InlineQueryResult {
  /// The `file_id` of the animation.
  final String mpeg4FileId;

  /// A title shown with the result in the picker.
  final String? title;

  /// The caption sent with the animation.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Whether [caption] is shown above the animation instead of below it.
  final bool? showCaptionAboveMedia;

  /// Creates a cached-animation result from [mpeg4FileId].
  const InlineQueryResultCachedMpeg4Gif(
    String id,
    this.mpeg4FileId, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.title,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
  }) : super(
          'mpeg4_gif',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'mpeg4_file_id': mpeg4FileId,
        if (title != null) 'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
      };
}

/// A sticker result reused from a `file_id` already on Telegram's servers.
class InlineQueryResultCachedSticker extends InlineQueryResult {
  /// The `file_id` of the sticker.
  final String stickerFileId;

  /// Creates a cached-sticker result from [stickerFileId].
  const InlineQueryResultCachedSticker(
    String id,
    this.stickerFileId, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
  }) : super(
          'sticker',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {'sticker_file_id': stickerFileId};
}

/// A file result reused from a `file_id` already on Telegram's servers.
class InlineQueryResultCachedDocument extends InlineQueryResult {
  /// A title shown with the result in the picker.
  final String title;

  /// The `file_id` of the document.
  final String documentFileId;

  /// A short description shown with the result in the picker.
  final String? description;

  /// The caption sent with the file.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Creates a cached-document result from [documentFileId].
  const InlineQueryResultCachedDocument(
    String id,
    this.title,
    this.documentFileId, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.description,
    this.caption,
    this.parseMode,
    this.captionEntities,
  }) : super(
          'document',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'title': title,
        'document_file_id': documentFileId,
        if (description != null) 'description': description,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
      };
}

/// A video result reused from a `file_id` already on Telegram's servers.
class InlineQueryResultCachedVideo extends InlineQueryResult {
  /// The `file_id` of the video.
  final String videoFileId;

  /// A title shown with the result in the picker.
  final String title;

  /// A short description shown with the result in the picker.
  final String? description;

  /// The caption sent with the video.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Whether [caption] is shown above the video instead of below it.
  final bool? showCaptionAboveMedia;

  /// Creates a cached-video result from [videoFileId].
  const InlineQueryResultCachedVideo(
    String id,
    this.videoFileId,
    this.title, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.description,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.showCaptionAboveMedia,
  }) : super(
          'video',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'video_file_id': videoFileId,
        'title': title,
        if (description != null) 'description': description,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
      };
}

/// A voice message result reused from a `file_id` already on Telegram's servers.
class InlineQueryResultCachedVoice extends InlineQueryResult {
  /// The `file_id` of the voice message.
  final String voiceFileId;

  /// A title shown with the result in the picker.
  final String title;

  /// The caption sent with the voice message.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Creates a cached-voice result from [voiceFileId].
  const InlineQueryResultCachedVoice(
    String id,
    this.voiceFileId,
    this.title, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.caption,
    this.parseMode,
    this.captionEntities,
  }) : super(
          'voice',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'voice_file_id': voiceFileId,
        'title': title,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
      };
}

/// An audio file result reused from a `file_id` already on Telegram's servers.
class InlineQueryResultCachedAudio extends InlineQueryResult {
  /// The `file_id` of the audio file.
  final String audioFileId;

  /// The caption sent with the audio.
  final String? caption;

  /// How [caption] should be parsed, if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [caption], as an alternative to [parseMode].
  final List<Json>? captionEntities;

  /// Creates a cached-audio result from [audioFileId].
  const InlineQueryResultCachedAudio(
    String id,
    this.audioFileId, {
    InlineKeyboardMarkup? replyMarkup,
    InputMessageContent? inputMessageContent,
    this.caption,
    this.parseMode,
    this.captionEntities,
  }) : super(
          'audio',
          id,
          replyMarkup: replyMarkup,
          inputMessageContent: inputMessageContent,
        );

  @override
  Json extraJson() => {
        'audio_file_id': audioFileId,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
      };
}

/// Converts a list of [InlineQueryResult]s to the raw JSON list Telegram's
/// API expects — a small helper so call sites read `inlineQueryResults([...])`
/// rather than a bare `.map((r) => r.toJson()).toList()`.
List<Json> inlineQueryResults(List<InlineQueryResult> results) =>
    results.map((r) => r.toJson()).toList();
