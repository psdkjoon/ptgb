import 'core.dart';
import 'enums.dart';
import 'reply_options.dart';

/// The content Telegram should actually send for an [InlineQueryResult],
/// used instead of that result's own preview content — e.g. an
/// [InlineQueryResultArticle] whose tap sends formatted text rather than a
/// link. Use a concrete subtype depending on what kind of content you want sent.
abstract class InputMessageContent {
  /// Converts this content to the JSON shape Telegram's API expects.
  Json toJson();
}

/// Plain (optionally formatted) text content for an inline query result.
class InputTextMessageContent implements InputMessageContent {
  /// The text to send, 1-4096 characters after entity parsing.
  final String messageText;

  /// How [messageText] should be parsed (Markdown/HTML entities), if at all.
  final ParseMode? parseMode;

  /// Pre-parsed entities for [messageText], as an alternative to [parseMode].
  final List<Json>? entities;

  /// Controls the automatic link preview attached to [messageText].
  final LinkPreviewOptions? linkPreviewOptions;

  /// Creates text content from [messageText].
  const InputTextMessageContent(
    this.messageText, {
    this.parseMode,
    this.entities,
    this.linkPreviewOptions,
  });

  @override
  Json toJson() => {
        'message_text': messageText,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (entities != null) 'entities': entities,
        if (linkPreviewOptions != null)
          'link_preview_options': linkPreviewOptions!.toJson(),
      };
}

/// A point on the map as the content of an inline query result.
class InputLocationMessageContent implements InputMessageContent {
  /// Latitude.
  final double latitude;

  /// Longitude.
  final double longitude;

  /// The radius of uncertainty for the location, in meters.
  final double? horizontalAccuracy;

  /// Set to share a live, periodically updating location instead of a static point.
  final int? livePeriod;

  /// Direction the user is moving in, in degrees, for a live location.
  final int? heading;

  /// Maximum distance (meters) for proximity alerts, for a live location.
  final int? proximityAlertRadius;

  /// Creates location content from [latitude]/[longitude].
  const InputLocationMessageContent(
    this.latitude,
    this.longitude, {
    this.horizontalAccuracy,
    this.livePeriod,
    this.heading,
    this.proximityAlertRadius,
  });

  @override
  Json toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (horizontalAccuracy != null)
          'horizontal_accuracy': horizontalAccuracy,
        if (livePeriod != null) 'live_period': livePeriod,
        if (heading != null) 'heading': heading,
        if (proximityAlertRadius != null)
          'proximity_alert_radius': proximityAlertRadius,
      };
}

/// A venue (a location plus a name/address) as the content of an inline query result.
class InputVenueMessageContent implements InputMessageContent {
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

  /// Creates venue content.
  const InputVenueMessageContent(
    this.latitude,
    this.longitude,
    this.title,
    this.address, {
    this.foursquareId,
    this.foursquareType,
    this.googlePlaceId,
    this.googlePlaceType,
  });

  @override
  Json toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'title': title,
        'address': address,
        if (foursquareId != null) 'foursquare_id': foursquareId,
        if (foursquareType != null) 'foursquare_type': foursquareType,
        if (googlePlaceId != null) 'google_place_id': googlePlaceId,
        if (googlePlaceType != null) 'google_place_type': googlePlaceType,
      };
}

/// A phone contact card as the content of an inline query result.
class InputContactMessageContent implements InputMessageContent {
  /// The contact's phone number.
  final String phoneNumber;

  /// The contact's first name.
  final String firstName;

  /// The contact's last name, if any.
  final String? lastName;

  /// The contact's vCard, if any.
  final String? vcard;

  /// Creates contact content.
  const InputContactMessageContent(
    this.phoneNumber,
    this.firstName, {
    this.lastName,
    this.vcard,
  });

  @override
  Json toJson() => {
        'phone_number': phoneNumber,
        'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (vcard != null) 'vcard': vcard,
      };
}

/// An invoice as the content of an inline query result.
class InputInvoiceMessageContent implements InputMessageContent {
  /// The invoice's title.
  final String title;

  /// The invoice's description.
  final String description;

  /// A bot-defined payload not shown to the user, used to identify the invoice later.
  final String payload;

  /// Three-letter ISO 4217 currency code, or `'XTR'` for Telegram Stars.
  final String currency;

  /// The price breakdown, as raw `LabeledPrice[]` JSON (`[{'label': ..., 'amount': ...}]`).
  final List<Json> prices;

  /// Payment provider token, empty when charging in Telegram Stars.
  final String? providerToken;

  /// The maximum accepted tip, in the smallest units of [currency].
  final int? maxTipAmount;

  /// Suggested tip amounts, in the smallest units of [currency], in increasing order.
  final List<int>? suggestedTipAmounts;

  /// A blob passed unchanged to the payment provider.
  final String? providerData;

  /// A URL of the product photo shown for the invoice.
  final String? photoUrl;

  /// Photo size in bytes, if known.
  final int? photoSize;

  /// Photo width, if known.
  final int? photoWidth;

  /// Photo height, if known.
  final int? photoHeight;

  /// Whether to collect the payer's full name.
  final bool? needName;

  /// Whether to collect the payer's phone number.
  final bool? needPhoneNumber;

  /// Whether to collect the payer's email.
  final bool? needEmail;

  /// Whether to collect the payer's shipping address.
  final bool? needShippingAddress;

  /// Whether to send the payer's phone number to the provider.
  final bool? sendPhoneNumberToProvider;

  /// Whether to send the payer's email to the provider.
  final bool? sendEmailToProvider;

  /// Whether the final price depends on the shipping method.
  final bool? isFlexible;

  /// Creates invoice content.
  const InputInvoiceMessageContent(
    this.title,
    this.description,
    this.payload,
    this.currency,
    this.prices, {
    this.providerToken,
    this.maxTipAmount,
    this.suggestedTipAmounts,
    this.providerData,
    this.photoUrl,
    this.photoSize,
    this.photoWidth,
    this.photoHeight,
    this.needName,
    this.needPhoneNumber,
    this.needEmail,
    this.needShippingAddress,
    this.sendPhoneNumberToProvider,
    this.sendEmailToProvider,
    this.isFlexible,
  });

  @override
  Json toJson() => {
        'title': title,
        'description': description,
        'payload': payload,
        'currency': currency,
        'prices': prices,
        if (providerToken != null) 'provider_token': providerToken,
        if (maxTipAmount != null) 'max_tip_amount': maxTipAmount,
        if (suggestedTipAmounts != null)
          'suggested_tip_amounts': suggestedTipAmounts,
        if (providerData != null) 'provider_data': providerData,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (photoSize != null) 'photo_size': photoSize,
        if (photoWidth != null) 'photo_width': photoWidth,
        if (photoHeight != null) 'photo_height': photoHeight,
        if (needName != null) 'need_name': needName,
        if (needPhoneNumber != null) 'need_phone_number': needPhoneNumber,
        if (needEmail != null) 'need_email': needEmail,
        if (needShippingAddress != null)
          'need_shipping_address': needShippingAddress,
        if (sendPhoneNumberToProvider != null)
          'send_phone_number_to_provider': sendPhoneNumberToProvider,
        if (sendEmailToProvider != null)
          'send_email_to_provider': sendEmailToProvider,
        if (isFlexible != null) 'is_flexible': isFlexible,
      };
}
