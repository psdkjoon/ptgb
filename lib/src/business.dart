import 'core.dart';
import 'input_file.dart';

/// A new profile photo for a connected Telegram Business account, used with
/// [Bot.setBusinessAccountProfilePhoto].
abstract class InputProfilePhoto {
  /// Converts this photo to the JSON shape Telegram's API expects,
  /// registering any local upload into [files] as it goes.
  Json toJson(Map<String, InputFile> files);
}

/// A static image used as a profile photo.
class InputProfilePhotoStatic implements InputProfilePhoto {
  /// The image file.
  final InputFile photo;

  /// Creates a static profile photo from [photo].
  const InputProfilePhotoStatic(this.photo);

  @override
  Json toJson(Map<String, InputFile> files) {
    String ref;
    if (photo.isUpload) {
      files['photo'] = photo;
      ref = 'attach://photo';
    } else {
      ref = photo.remoteValue!;
    }
    return {'type': 'static', 'photo': ref};
  }
}

/// An animated video used as a profile photo.
class InputProfilePhotoAnimated implements InputProfilePhoto {
  /// The animation file.
  final InputFile animation;

  /// The timestamp (in seconds) of the frame used as a static preview.
  final double? mainFrameTimestamp;

  /// Creates an animated profile photo from [animation].
  const InputProfilePhotoAnimated(this.animation, {this.mainFrameTimestamp});

  @override
  Json toJson(Map<String, InputFile> files) {
    String ref;
    if (animation.isUpload) {
      files['animation'] = animation;
      ref = 'attach://animation';
    } else {
      ref = animation.remoteValue!;
    }
    return {
      'type': 'animated',
      'animation': ref,
      if (mainFrameTimestamp != null) 'main_frame_timestamp': mainFrameTimestamp,
    };
  }
}

/// The media content of a Telegram Story, used with [Bot.postStory] and [Bot.editStory].
abstract class InputStoryContent {
  /// Converts this content to the JSON shape Telegram's API expects,
  /// registering any local upload into [files] as it goes.
  Json toJson(Map<String, InputFile> files);
}

/// A photo-based story.
class InputStoryContentPhoto implements InputStoryContent {
  /// The image file.
  final InputFile photo;

  /// Creates a photo story from [photo].
  const InputStoryContentPhoto(this.photo);

  @override
  Json toJson(Map<String, InputFile> files) {
    String ref;
    if (photo.isUpload) {
      files['photo'] = photo;
      ref = 'attach://photo';
    } else {
      ref = photo.remoteValue!;
    }
    return {'type': 'photo', 'photo': ref};
  }
}

/// A video-based story.
class InputStoryContentVideo implements InputStoryContent {
  /// The video file.
  final InputFile video;

  /// The video's duration in seconds.
  final double? duration;

  /// The timestamp (in seconds) of the frame used as a static cover preview.
  final double? coverFrameTimestamp;

  /// Whether the video should be treated as a silent, looping animation.
  final bool? isAnimation;

  /// Creates a video story from [video].
  const InputStoryContentVideo(
    this.video, {
    this.duration,
    this.coverFrameTimestamp,
    this.isAnimation,
  });

  @override
  Json toJson(Map<String, InputFile> files) {
    String ref;
    if (video.isUpload) {
      files['video'] = video;
      ref = 'attach://video';
    } else {
      ref = video.remoteValue!;
    }
    return {
      'type': 'video',
      'video': ref,
      if (duration != null) 'duration': duration,
      if (coverFrameTimestamp != null) 'cover_frame_timestamp': coverFrameTimestamp,
      if (isAnimation != null) 'is_animation': isAnimation,
    };
  }
}

/// Which gift types a connected Telegram Business account accepts, used
/// with [Bot.setBusinessAccountGiftSettings].
class AcceptedGiftTypes {
  /// Whether ordinary (non-limited) gifts are accepted.
  final bool unlimitedGifts;

  /// Whether limited-edition gifts are accepted.
  final bool limitedGifts;

  /// Whether unique (one-of-a-kind, upgraded) gifts are accepted.
  final bool uniqueGifts;

  /// Whether gifted Telegram Premium subscriptions are accepted.
  final bool premiumSubscription;

  /// Creates a gift settings configuration — every flag must be explicitly set.
  const AcceptedGiftTypes({
    required this.unlimitedGifts,
    required this.limitedGifts,
    required this.uniqueGifts,
    required this.premiumSubscription,
  });

  /// Converts these settings to the JSON shape Telegram's API expects.
  Json toJson() => {
        'unlimited_gifts': unlimitedGifts,
        'limited_gifts': limitedGifts,
        'unique_gifts': uniqueGifts,
        'premium_subscription': premiumSubscription,
      };
}
