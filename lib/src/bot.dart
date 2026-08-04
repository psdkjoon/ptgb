import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:penv/penv.dart';

import 'business.dart';
import 'checklist.dart';
import 'core.dart';
import 'enums.dart';
import 'http_client.dart';
import 'input_file.dart';
import 'input_media.dart';
import 'keyboards.dart';
import 'models.dart';
import 'permissions.dart';
import 'rate_limiter.dart';
import 'reply_options.dart';
import 'stickers.dart';
import 'updates.dart';
import 'webapp.dart' hide verifyWebAppInitData;
import 'webapp.dart' as webapp show verifyWebAppInitData;

export 'business.dart';
export 'checklist.dart';
export 'core.dart';
export 'enums.dart';
export 'input_file.dart';
export 'input_media.dart';
export 'keyboards.dart';
export 'models.dart';
export 'permissions.dart';
export 'rate_limiter.dart';
export 'reply_options.dart';
export 'stickers.dart';
export 'updates.dart';
export 'webapp.dart';

Json _o(dynamic r) => r as Json;
List<Json> _l(dynamic r) => (r as List).cast<Json>();
bool _b(dynamic r) => r as bool;
int _i(dynamic r) => r as int;
String _s(dynamic r) => r as String;

/// The main entry point of `ptgb` — a thin, fully-typed wrapper around every
/// method of the [Telegram Bot API](https://core.telegram.org/bots/api).
///
/// Create one instance per bot token and reuse it for the lifetime of your
/// program; it owns a single HTTP client under the hood.
///
/// ```dart
/// import 'package:ptgb/ptgb.dart';
///
/// void main() async {
///   // Loads the token from a `.env` file (TOKEN=...) next to your script —
///   // see the [Bot.new] constructor docs for the token: parameter if you'd
///   // rather supply it directly.
///   final bot = Bot();
///
///   await for (final update in bot.poll()) {
///     if (update.text == '/start') {
///       await bot.sendMessage(update.chatId!, 'Hello!');
///     }
///   }
/// }
/// ```
///
/// Every Bot API method (`sendMessage`, `sendPhoto`, `banChatMember`, ...) is
/// available as a typed method on this class. Anything not yet covered by a
/// typed method can still be reached through the low-level [call] escape hatch.
class Bot {
  /// The bot token this instance authenticates with, as returned by @BotFather.
  final String token;
  final TelegramHttpClient _client;
  final RateLimiter? _rateLimiter;
  bool _polling = false;

  Bot._(this.token, this._client, this._rateLimiter);

  /// Creates a [Bot].
  ///
  /// Pass [token] directly, or omit it to load it automatically from a
  /// `.env`-style file (see the `penv` package) using [dotFileName] and
  /// [envKey] — handy for keeping secrets out of source control.
  ///
  /// [apiBaseUrl] and [fileBaseUrl] let you point at a self-hosted Bot API
  /// server instead of `api.telegram.org`.
  ///
  /// Pass [rateLimiter] to automatically pace outgoing requests and reduce
  /// how often you hit Telegram's rate limits — see [RateLimiter] for
  /// details. Left `null` (the default), requests are sent as fast as you
  /// call them, same as before.
  ///
  /// [requestTimeout] bounds how long any single HTTP request (including
  /// long-polling calls made by [poll]) is allowed to take before it's
  /// aborted with a [TimeoutException] — see [TelegramHttpClient.requestTimeout].
  /// If you pass a longer `timeout` to [poll] or [getUpdates], raise this
  /// to match (it must exceed the long-poll `timeout` or every poll will
  /// spuriously time out).
  factory Bot({
    String? token,
    String dotFileName = '.env',
    String envKey = 'TOKEN',
    String? apiBaseUrl,
    String? fileBaseUrl,
    RateLimiter? rateLimiter,
    Duration requestTimeout = const Duration(seconds: 35),
  }) {
    final resolvedToken = token ?? penvload(dotFileName)[envKey] as String;
    final api = apiBaseUrl ?? 'https://api.telegram.org/bot$resolvedToken';
    final files =
        fileBaseUrl ?? 'https://api.telegram.org/file/bot$resolvedToken';
    return Bot._(
      resolvedToken,
      TelegramHttpClient(api, files, requestTimeout: requestTimeout),
      rateLimiter,
    );
  }

  /// Releases the underlying HTTP client's resources. Call this when your
  /// bot is shutting down for good.
  void dispose() => _client.close();

  /// Low-level escape hatch: calls any Telegram Bot API method by name.
  ///
  /// Use this for brand-new API methods that don't have a typed wrapper yet.
  /// [method] is the raw Bot API method name (e.g. `'sendMessage'`), [params]
  /// is the JSON body, and [files] are any [InputFile]s that should be
  /// uploaded as multipart attachments.
  ///
  /// If this [Bot] was created with a [RateLimiter], every call — including
  /// ones made through this method directly — waits its turn first.
  Future<dynamic> call(
    String method, [
    Json? params,
    Map<String, InputFile>? files,
  ]) async {
    if (_rateLimiter != null) await _rateLimiter.acquire(params?['chat_id']);
    return _client.call(method, params, files);
  }

  /// Returns basic information about the bot itself as a [User] object (in raw JSON form).
  ///
  /// Handy as a quick way to verify that [token] is valid.
  Future<Json> getMe() async => _o(await call('getMe'));

  /// Logs the bot out from the Bot API server before moving it to a local server instance.
  /// You generally never need this unless you're running your own Bot API server.
  Future<bool> logOut() async => _b(await call('logOut'));

  /// Closes the bot instance before moving it from one local server to another.
  /// Not related to [dispose] — this is a Telegram API call, not local cleanup.
  Future<bool> close() async => _b(await call('close'));

  /// Long-polls Telegram for new [Update]s.
  ///
  /// You rarely need to call this directly — prefer the [poll] stream, which
  /// wraps this method in a convenient `await for` loop and manages the
  /// offset for you automatically.
  Future<List<Update>> getUpdates({
    int? offset,
    int? limit,
    int? timeout,
    List<String>? allowedUpdates,
  }) async {
    final raw = await call('getUpdates', {
      if (offset != null) 'offset': offset,
      if (limit != null) 'limit': limit,
      if (timeout != null) 'timeout': timeout,
      if (allowedUpdates != null) 'allowed_updates': allowedUpdates,
    });
    return _l(raw).map(Update.new).toList();
  }

  /// Registers [url] as the webhook endpoint Telegram will POST updates to.
  /// Use [serveWebhook] on your side to actually receive them.
  Future<bool> setWebhook(
    String url, {
    InputFile? certificate,
    String? ipAddress,
    int? maxConnections,
    List<String>? allowedUpdates,
    bool? dropPendingUpdates,
    String? secretToken,
  }) async =>
      _b(
        await call(
          'setWebhook',
          {
            'url': url,
            if (ipAddress != null) 'ip_address': ipAddress,
            if (maxConnections != null) 'max_connections': maxConnections,
            if (allowedUpdates != null) 'allowed_updates': allowedUpdates,
            if (dropPendingUpdates != null)
              'drop_pending_updates': dropPendingUpdates,
            if (secretToken != null) 'secret_token': secretToken,
          },
          certificate != null ? {'certificate': certificate} : null,
        ),
      );

  /// Removes the current webhook and switches the bot back to polling mode.
  Future<bool> deleteWebhook({bool? dropPendingUpdates}) async => _b(
        await call('deleteWebhook', {
          if (dropPendingUpdates != null)
            'drop_pending_updates': dropPendingUpdates,
        }),
      );

  /// Returns the current webhook status (URL, pending update count, last error, etc).
  Future<Json> getWebhookInfo() async => _o(await call('getWebhookInfo'));

  /// Signals an in-progress [poll] stream to stop after its current iteration.
  void stopPolling() => _polling = false;

  /// Starts long-polling Telegram and yields every incoming [Update] as a stream.
  ///
  /// This is the easiest way to run a bot: it repeatedly calls [getUpdates]
  /// under the hood, automatically advancing the offset so you never see the
  /// same update twice. Call [stopPolling] to stop the loop gracefully.
  ///
  /// ```dart
  /// await for (final update in bot.poll()) {
  ///   if (update.text != null) {
  ///     await bot.sendMessage(update.chatId!, 'You said: \${update.text}');
  ///   }
  /// }
  /// ```
  ///
  /// Transient network errors (timeouts, socket errors, and the like) don't
  /// kill the stream: [poll] catches them, waits with exponential backoff
  /// (starting at [initialBackoff] and doubling up to [maxBackoff] on
  /// repeated failures, resetting once a call succeeds again), and retries
  /// — the stream itself keeps running. Pass [onError] to observe these
  /// failures (e.g. for logging) as they happen; leave it `null` to retry
  /// silently. Errors thrown by your own code inside the `await for` body
  /// are unaffected and propagate normally.
  Stream<Update> poll({
    int limit = 100,
    int timeout = 30,
    List<String>? allowedUpdates,
    void Function(Object error, StackTrace stackTrace)? onError,
    Duration initialBackoff = const Duration(seconds: 1),
    Duration maxBackoff = const Duration(seconds: 30),
  }) async* {
    _polling = true;
    var offset = 0;
    var backoff = initialBackoff;
    while (_polling) {
      List<Update> updates;
      try {
        updates = await getUpdates(
          offset: offset,
          limit: limit,
          timeout: timeout,
          allowedUpdates: allowedUpdates,
        );
      } catch (error, stackTrace) {
        onError?.call(error, stackTrace);
        if (!_polling) return;
        await Future<void>.delayed(backoff);
        backoff = Duration(
          milliseconds:
              (backoff.inMilliseconds * 2).clamp(0, maxBackoff.inMilliseconds),
        );
        continue;
      }
      backoff = initialBackoff;
      for (final update in updates) {
        offset = update.updateId + 1;
        yield update;
      }
    }
  }

  /// Starts an HTTP server that receives Telegram webhook updates and calls
  /// [onUpdate] for each one. Alternative to [poll] for production deployments
  /// behind a reverse proxy or with a direct TLS certificate via [securityContext].
  /// Pair with [setWebhook] so Telegram knows where to send updates.
  ///
  /// If parsing the request body or your [onUpdate] callback throws, the
  /// exception is caught (so one bad request can't crash the server) and
  /// passed to [onError] if you provide one — handy for logging. Left
  /// `null` (the default), such errors are swallowed silently, same as
  /// before. Either way, the request still gets an HTTP 200 response, since
  /// Telegram doesn't inspect it.
  Future<HttpServer> serveWebhook(
    void Function(Update update) onUpdate, {
    String path = '/',
    Object address = '0.0.0.0',
    int port = 8443,
    SecurityContext? securityContext,
    String? secretToken,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    final server = securityContext != null
        ? await HttpServer.bindSecure(address, port, securityContext)
        : await HttpServer.bind(address, port);

    server.listen((request) async {
      if (request.method != 'POST' || request.uri.path != path) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      if (secretToken != null &&
          request.headers.value('X-Telegram-Bot-Api-Secret-Token') !=
              secretToken) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }
      try {
        final body = await utf8.decoder.bind(request).join();
        onUpdate(Update(jsonDecode(body) as Json));
      } catch (error, stackTrace) {
        onError?.call(error, stackTrace);
      }
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
    });

    return server;
  }

  /// Downloads the raw bytes of a file already located via [getFile], given its `file_path`.
  Future<Uint8List> downloadFile(String filePath) =>
      _client.downloadFile(filePath);

  /// Convenience helper that resolves a Telegram `file_id` via [getFile] and
  /// immediately downloads its bytes in one call.
  Future<Uint8List> downloadFileById(String fileId) async {
    final file = await getFile(fileId);
    return downloadFile(file['file_path'] as String);
  }

  /// Sends a text message to [chatId].
  ///
  /// This is the most common method in the whole API. Use [parseMode] to enable
  /// Markdown/HTML formatting, [replyMarkup] to attach an inline/reply keyboard,
  /// and [replyParameters] to reply to an existing message.
  Future<Json> sendMessage(
    Object chatId,
    String text, {
    String? businessConnectionId,
    int? messageThreadId,
    ParseMode? parseMode,
    List<Json>? entities,
    LinkPreviewOptions? linkPreviewOptions,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    int? replyToMessageId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendMessage', {
          'chat_id': chatId,
          'text': text,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (parseMode != null) 'parse_mode': parseMode.value,
          if (entities != null) 'entities': entities,
          if (linkPreviewOptions != null)
            'link_preview_options': linkPreviewOptions.toJson(),
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson()
          else if (replyToMessageId != null)
            'reply_parameters': {'message_id': replyToMessageId},
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Streams a partial message to [chatId] while it's still being generated
  /// — e.g. to show an AI response being "typed out" live. Supported only
  /// in chats with forum topic mode enabled. The streamed draft is
  /// ephemeral (a ~30-second preview); once the content is final, call
  /// [sendMessage] with the complete text to actually persist it. Re-using
  /// the same [draftId] animates the transition from the previous text.
  Future<bool> sendMessageDraft(
    Object chatId,
    int draftId, {
    int? messageThreadId,
    String? text,
    ParseMode? parseMode,
    List<Json>? entities,
  }) async =>
      _b(
        await call('sendMessageDraft', {
          'chat_id': chatId,
          'draft_id': draftId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (text != null) 'text': text,
          if (parseMode != null) 'parse_mode': parseMode.value,
          if (entities != null) 'entities': entities,
        }),
      );

  /// Forwards a single existing message from [fromChatId] to [chatId], keeping
  /// the "Forwarded from" attribution.
  Future<Json> forwardMessage(
    Object chatId,
    Object fromChatId,
    int messageId, {
    int? messageThreadId,
    bool? disableNotification,
    bool? protectContent,
  }) async =>
      _o(
        await call('forwardMessage', {
          'chat_id': chatId,
          'from_chat_id': fromChatId,
          'message_id': messageId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
        }),
      );

  /// Forwards a batch of messages ([messageIds]) from [fromChatId] to [chatId] in one call.
  Future<List<Json>> forwardMessages(
    Object chatId,
    Object fromChatId,
    List<int> messageIds, {
    int? messageThreadId,
    bool? disableNotification,
    bool? protectContent,
  }) async =>
      _l(
        await call('forwardMessages', {
          'chat_id': chatId,
          'from_chat_id': fromChatId,
          'message_ids': messageIds,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
        }),
      );

  /// Copies a message from [fromChatId] to [chatId] *without* the "Forwarded
  /// from" header, as if you wrote it yourself. Media, captions, and reply
  /// markup are preserved.
  Future<Json> copyMessage(
    Object chatId,
    Object fromChatId,
    int messageId, {
    int? messageThreadId,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call('copyMessage', {
          'chat_id': chatId,
          'from_chat_id': fromChatId,
          'message_id': messageId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (caption != null) 'caption': caption,
          if (parseMode != null) 'parse_mode': parseMode.value,
          if (captionEntities != null) 'caption_entities': captionEntities,
          if (showCaptionAboveMedia != null)
            'show_caption_above_media': showCaptionAboveMedia,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Copies a batch of messages ([messageIds]) from [fromChatId] to [chatId] in one call.
  Future<List<Json>> copyMessages(
    Object chatId,
    Object fromChatId,
    List<int> messageIds, {
    int? messageThreadId,
    bool? disableNotification,
    bool? protectContent,
    bool? removeCaption,
  }) async =>
      _l(
        await call('copyMessages', {
          'chat_id': chatId,
          'from_chat_id': fromChatId,
          'message_ids': messageIds,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (removeCaption != null) 'remove_caption': removeCaption,
        }),
      );

  /// Sends a photo. [photo] accepts a `file_id`, a URL, or a local upload via
  /// [InputFile.path]/[InputFile.bytes].
  Future<Json> sendPhoto(
    Object chatId,
    InputFile photo, {
    String? businessConnectionId,
    int? messageThreadId,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    bool? hasSpoiler,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call(
          'sendPhoto',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (caption != null) 'caption': caption,
            if (parseMode != null) 'parse_mode': parseMode.value,
            if (captionEntities != null) 'caption_entities': captionEntities,
            if (showCaptionAboveMedia != null)
              'show_caption_above_media': showCaptionAboveMedia,
            if (hasSpoiler != null) 'has_spoiler': hasSpoiler,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
          },
          {'photo': photo},
        ),
      );

  /// Sends an audio file that Telegram will display with a music player UI.
  /// Use [sendVoice] instead for voice-message-style recordings, or
  /// [sendDocument] for arbitrary audio files you don't want played inline.
  Future<Json> sendAudio(
    Object chatId,
    InputFile audio, {
    String? businessConnectionId,
    int? messageThreadId,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    int? duration,
    String? performer,
    String? title,
    InputFile? thumbnail,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call(
          'sendAudio',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (caption != null) 'caption': caption,
            if (parseMode != null) 'parse_mode': parseMode.value,
            if (captionEntities != null) 'caption_entities': captionEntities,
            if (duration != null) 'duration': duration,
            if (performer != null) 'performer': performer,
            if (title != null) 'title': title,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
          },
          {'audio': audio, if (thumbnail != null) 'thumbnail': thumbnail},
        ),
      );

  /// Sends a general file/document of any type.
  Future<Json> sendDocument(
    Object chatId,
    InputFile document, {
    String? businessConnectionId,
    int? messageThreadId,
    InputFile? thumbnail,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? disableContentTypeDetection,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call(
          'sendDocument',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (caption != null) 'caption': caption,
            if (parseMode != null) 'parse_mode': parseMode.value,
            if (captionEntities != null) 'caption_entities': captionEntities,
            if (disableContentTypeDetection != null)
              'disable_content_type_detection': disableContentTypeDetection,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
          },
          {'document': document, if (thumbnail != null) 'thumbnail': thumbnail},
        ),
      );

  /// Sends a video that Telegram can play inline in the chat.
  Future<Json> sendVideo(
    Object chatId,
    InputFile video, {
    String? businessConnectionId,
    int? messageThreadId,
    int? duration,
    int? width,
    int? height,
    InputFile? thumbnail,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    bool? hasSpoiler,
    bool? supportsStreaming,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call(
          'sendVideo',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (duration != null) 'duration': duration,
            if (width != null) 'width': width,
            if (height != null) 'height': height,
            if (caption != null) 'caption': caption,
            if (parseMode != null) 'parse_mode': parseMode.value,
            if (captionEntities != null) 'caption_entities': captionEntities,
            if (showCaptionAboveMedia != null)
              'show_caption_above_media': showCaptionAboveMedia,
            if (hasSpoiler != null) 'has_spoiler': hasSpoiler,
            if (supportsStreaming != null)
              'supports_streaming': supportsStreaming,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
          },
          {'video': video, if (thumbnail != null) 'thumbnail': thumbnail},
        ),
      );

  /// Sends an animation (GIF or silent, looping MP4).
  Future<Json> sendAnimation(
    Object chatId,
    InputFile animation, {
    String? businessConnectionId,
    int? messageThreadId,
    int? duration,
    int? width,
    int? height,
    InputFile? thumbnail,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    bool? hasSpoiler,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call(
          'sendAnimation',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (duration != null) 'duration': duration,
            if (width != null) 'width': width,
            if (height != null) 'height': height,
            if (caption != null) 'caption': caption,
            if (parseMode != null) 'parse_mode': parseMode.value,
            if (captionEntities != null) 'caption_entities': captionEntities,
            if (showCaptionAboveMedia != null)
              'show_caption_above_media': showCaptionAboveMedia,
            if (hasSpoiler != null) 'has_spoiler': hasSpoiler,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
          },
          {
            'animation': animation,
            if (thumbnail != null) 'thumbnail': thumbnail,
          },
        ),
      );

  /// Sends a voice-message-style audio clip (displayed with a waveform in the
  /// Telegram UI). The file must be an .ogg encoded with the OPUS codec, or
  /// another format Telegram can automatically convert.
  Future<Json> sendVoice(
    Object chatId,
    InputFile voice, {
    String? businessConnectionId,
    int? messageThreadId,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    int? duration,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call(
          'sendVoice',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (caption != null) 'caption': caption,
            if (parseMode != null) 'parse_mode': parseMode.value,
            if (captionEntities != null) 'caption_entities': captionEntities,
            if (duration != null) 'duration': duration,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
          },
          {'voice': voice},
        ),
      );

  /// Sends a round "video note" message (the circular video bubbles seen in
  /// Telegram chats). Telegram only supports square, i.e. `width == height`, video notes.
  Future<Json> sendVideoNote(
    Object chatId,
    InputFile videoNote, {
    String? businessConnectionId,
    int? messageThreadId,
    int? duration,
    int? length,
    InputFile? thumbnail,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call(
          'sendVideoNote',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (duration != null) 'duration': duration,
            if (length != null) 'length': length,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
          },
          {
            'video_note': videoNote,
            if (thumbnail != null) 'thumbnail': thumbnail,
          },
        ),
      );

  /// Sends an album of 2-10 photos/videos/documents/audio files grouped
  /// together as a single message using a list of [InputMedia] items.
  Future<List<Json>> sendMediaGroup(
    Object chatId,
    List<InputMedia> media, {
    String? businessConnectionId,
    int? messageThreadId,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
  }) async {
    final files = <String, InputFile>{};
    final mediaJson = <Json>[];
    for (var i = 0; i < media.length; i++) {
      final item = media[i];
      String mediaRef;
      if (item.media.isUpload) {
        final name = 'file$i';
        files[name] = item.media;
        mediaRef = 'attach://$name';
      } else {
        mediaRef = item.media.remoteValue!;
      }
      String? thumbRef;
      if (item.thumbnail != null) {
        if (item.thumbnail!.isUpload) {
          final name = 'thumb$i';
          files[name] = item.thumbnail!;
          thumbRef = 'attach://$name';
        } else {
          thumbRef = item.thumbnail!.remoteValue;
        }
      }
      mediaJson.add(item.toJson(mediaRef, thumbRef: thumbRef));
    }

    return _l(
      await call(
        'sendMediaGroup',
        {
          'chat_id': chatId,
          'media': mediaJson,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
        },
        files,
      ),
    );
  }

  /// Sends paid media (photos/videos) that chat members must pay [starCount]
  /// Telegram Stars to unlock. Star proceeds are credited to the channel's
  /// balance if [chatId] is a channel, or to the bot's balance otherwise.
  Future<Json> sendPaidMedia(
    Object chatId,
    int starCount,
    List<InputPaidMedia> media, {
    String? businessConnectionId,
    String? payload,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async {
    final files = <String, InputFile>{};
    final mediaJson = <Json>[];
    for (var i = 0; i < media.length; i++) {
      final item = media[i];
      String mediaRef;
      if (item.media.isUpload) {
        final name = 'file$i';
        files[name] = item.media;
        mediaRef = 'attach://$name';
      } else {
        mediaRef = item.media.remoteValue!;
      }
      String? thumbRef;
      if (item.thumbnail != null) {
        if (item.thumbnail!.isUpload) {
          final name = 'thumb$i';
          files[name] = item.thumbnail!;
          thumbRef = 'attach://$name';
        } else {
          thumbRef = item.thumbnail!.remoteValue;
        }
      }
      mediaJson.add(item.toJson(mediaRef, thumbRef: thumbRef));
    }

    return _o(
      await call(
        'sendPaidMedia',
        {
          'chat_id': chatId,
          'star_count': starCount,
          'media': mediaJson,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (payload != null) 'payload': payload,
          if (caption != null) 'caption': caption,
          if (parseMode != null) 'parse_mode': parseMode.value,
          if (captionEntities != null) 'caption_entities': captionEntities,
          if (showCaptionAboveMedia != null)
            'show_caption_above_media': showCaptionAboveMedia,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        },
        files,
      ),
    );
  }

  /// Sends a point on the map. Set [livePeriod] to share a live, periodically
  /// updating location instead of a static point.
  Future<Json> sendLocation(
    Object chatId,
    double latitude,
    double longitude, {
    String? businessConnectionId,
    int? messageThreadId,
    double? horizontalAccuracy,
    int? livePeriod,
    int? heading,
    int? proximityAlertRadius,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendLocation', {
          'chat_id': chatId,
          'latitude': latitude,
          'longitude': longitude,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (horizontalAccuracy != null)
            'horizontal_accuracy': horizontalAccuracy,
          if (livePeriod != null) 'live_period': livePeriod,
          if (heading != null) 'heading': heading,
          if (proximityAlertRadius != null)
            'proximity_alert_radius': proximityAlertRadius,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Sends information about a venue (a location plus a name and address).
  Future<Json> sendVenue(
    Object chatId,
    double latitude,
    double longitude,
    String title,
    String address, {
    String? businessConnectionId,
    int? messageThreadId,
    String? foursquareId,
    String? foursquareType,
    String? googlePlaceId,
    String? googlePlaceType,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendVenue', {
          'chat_id': chatId,
          'latitude': latitude,
          'longitude': longitude,
          'title': title,
          'address': address,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (foursquareId != null) 'foursquare_id': foursquareId,
          if (foursquareType != null) 'foursquare_type': foursquareType,
          if (googlePlaceId != null) 'google_place_id': googlePlaceId,
          if (googlePlaceType != null) 'google_place_type': googlePlaceType,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Sends a phone contact card.
  Future<Json> sendContact(
    Object chatId,
    String phoneNumber,
    String firstName, {
    String? businessConnectionId,
    int? messageThreadId,
    String? lastName,
    String? vcard,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendContact', {
          'chat_id': chatId,
          'phone_number': phoneNumber,
          'first_name': firstName,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (lastName != null) 'last_name': lastName,
          if (vcard != null) 'vcard': vcard,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Sends a native Telegram poll or quiz. Use [type] set to `PollType.quiz` for
  /// a quiz poll and provide [correctOptionId].
  Future<Json> sendPoll(
    Object chatId,
    String question,
    List<String> options, {
    String? businessConnectionId,
    int? messageThreadId,
    List<Json>? questionEntities,
    bool? isAnonymous,
    PollType? type,
    bool? allowsMultipleAnswers,
    int? correctOptionId,
    String? explanation,
    ParseMode? explanationParseMode,
    List<Json>? explanationEntities,
    int? openPeriod,
    int? closeDate,
    bool? isClosed,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendPoll', {
          'chat_id': chatId,
          'question': question,
          'options': options.map((o) => {'text': o}).toList(),
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (questionEntities != null) 'question_entities': questionEntities,
          if (isAnonymous != null) 'is_anonymous': isAnonymous,
          if (type != null) 'type': type.value,
          if (allowsMultipleAnswers != null)
            'allows_multiple_answers': allowsMultipleAnswers,
          if (correctOptionId != null) 'correct_option_id': correctOptionId,
          if (explanation != null) 'explanation': explanation,
          if (explanationParseMode != null)
            'explanation_parse_mode': explanationParseMode.value,
          if (explanationEntities != null)
            'explanation_entities': explanationEntities,
          if (openPeriod != null) 'open_period': openPeriod,
          if (closeDate != null) 'close_date': closeDate,
          if (isClosed != null) 'is_closed': isClosed,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Sends an animated dice-style emoji (dice, dart, basketball, etc). Telegram
  /// computes the result server-side, unlike a plain emoji message.
  Future<Json> sendDice(
    Object chatId, {
    String? businessConnectionId,
    int? messageThreadId,
    DiceEmoji? emoji,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendDice', {
          'chat_id': chatId,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (emoji != null) 'emoji': emoji.value,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Shows a transient status indicator such as "Bot is typing..." in the chat.
  /// The indicator is automatically cleared after ~5 seconds or the next sent
  /// message, whichever is sooner.
  Future<bool> sendChatAction(
    Object chatId,
    ChatAction action, {
    String? businessConnectionId,
    int? messageThreadId,
  }) async =>
      _b(
        await call('sendChatAction', {
          'chat_id': chatId,
          'action': action.value,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
        }),
      );

  /// Sets (or clears) the bot's emoji reaction(s) on a message.
  Future<bool> setMessageReaction(
    Object chatId,
    int messageId, {
    List<ReactionType>? reaction,
    bool? isBig,
  }) async =>
      _b(
        await call('setMessageReaction', {
          'chat_id': chatId,
          'message_id': messageId,
          if (reaction != null)
            'reaction': reaction.map((r) => r.toJson()).toList(),
          if (isBig != null) 'is_big': isBig,
        }),
      );

  /// Edits the text of a previously sent message. Provide [chatId] and
  /// [messageId] for bot-sent messages, or [inlineMessageId] when editing a
  /// message that came from an inline query result.
  Future<dynamic> editMessageText(
    String text, {
    String? businessConnectionId,
    Object? chatId,
    int? messageId,
    String? inlineMessageId,
    ParseMode? parseMode,
    List<Json>? entities,
    LinkPreviewOptions? linkPreviewOptions,
    InlineKeyboardMarkup? replyMarkup,
  }) =>
      call('editMessageText', {
        'text': text,
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (inlineMessageId != null) 'inline_message_id': inlineMessageId,
        if (parseMode != null) 'parse_mode': parseMode.value,
        if (entities != null) 'entities': entities,
        if (linkPreviewOptions != null)
          'link_preview_options': linkPreviewOptions.toJson(),
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      });

  /// Edits the caption of a message that has media attached.
  Future<dynamic> editMessageCaption({
    String? businessConnectionId,
    Object? chatId,
    int? messageId,
    String? inlineMessageId,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    InlineKeyboardMarkup? replyMarkup,
  }) =>
      call('editMessageCaption', {
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (inlineMessageId != null) 'inline_message_id': inlineMessageId,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      });

  /// Replaces the media (photo/video/etc) of an existing message with [media].
  Future<dynamic> editMessageMedia(
    InputMedia media, {
    String? businessConnectionId,
    Object? chatId,
    int? messageId,
    String? inlineMessageId,
    InlineKeyboardMarkup? replyMarkup,
  }) async {
    final files = <String, InputFile>{};
    String mediaRef;
    if (media.media.isUpload) {
      files['file0'] = media.media;
      mediaRef = 'attach://file0';
    } else {
      mediaRef = media.media.remoteValue!;
    }
    String? thumbRef;
    if (media.thumbnail != null) {
      if (media.thumbnail!.isUpload) {
        files['thumb0'] = media.thumbnail!;
        thumbRef = 'attach://thumb0';
      } else {
        thumbRef = media.thumbnail!.remoteValue;
      }
    }

    return call(
      'editMessageMedia',
      {
        'media': media.toJson(mediaRef, thumbRef: thumbRef),
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (inlineMessageId != null) 'inline_message_id': inlineMessageId,
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      },
      files,
    );
  }

  /// Updates the coordinates of an in-progress live location started with
  /// [sendLocation]'s `livePeriod`.
  Future<dynamic> editMessageLiveLocation(
    double latitude,
    double longitude, {
    String? businessConnectionId,
    Object? chatId,
    int? messageId,
    String? inlineMessageId,
    int? livePeriod,
    double? horizontalAccuracy,
    int? heading,
    int? proximityAlertRadius,
    InlineKeyboardMarkup? replyMarkup,
  }) =>
      call('editMessageLiveLocation', {
        'latitude': latitude,
        'longitude': longitude,
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (inlineMessageId != null) 'inline_message_id': inlineMessageId,
        if (livePeriod != null) 'live_period': livePeriod,
        if (horizontalAccuracy != null)
          'horizontal_accuracy': horizontalAccuracy,
        if (heading != null) 'heading': heading,
        if (proximityAlertRadius != null)
          'proximity_alert_radius': proximityAlertRadius,
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      });

  /// Stops updating a live location before its `livePeriod` naturally expires.
  Future<dynamic> stopMessageLiveLocation({
    String? businessConnectionId,
    Object? chatId,
    int? messageId,
    String? inlineMessageId,
    InlineKeyboardMarkup? replyMarkup,
  }) =>
      call('stopMessageLiveLocation', {
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (inlineMessageId != null) 'inline_message_id': inlineMessageId,
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      });

  /// Replaces just the inline keyboard attached to a message, leaving its
  /// content untouched.
  Future<dynamic> editMessageReplyMarkup({
    String? businessConnectionId,
    Object? chatId,
    int? messageId,
    String? inlineMessageId,
    InlineKeyboardMarkup? replyMarkup,
  }) =>
      call('editMessageReplyMarkup', {
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (inlineMessageId != null) 'inline_message_id': inlineMessageId,
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      });

  /// Immediately closes a poll so it no longer accepts new answers, and
  /// returns the final results.
  Future<Json> stopPoll(
    Object chatId,
    int messageId, {
    String? businessConnectionId,
    InlineKeyboardMarkup? replyMarkup,
  }) async =>
      _o(
        await call('stopPoll', {
          'chat_id': chatId,
          'message_id': messageId,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Deletes a single message. Bots can only delete their own messages in
  /// private chats, but have wider delete permissions in groups/channels they admin.
  Future<bool> deleteMessage(Object chatId, int messageId) async => _b(
        await call(
          'deleteMessage',
          {'chat_id': chatId, 'message_id': messageId},
        ),
      );

  /// Deletes a batch of messages ([messageIds]) in one call.
  Future<bool> deleteMessages(Object chatId, List<int> messageIds) async => _b(
        await call(
          'deleteMessages',
          {'chat_id': chatId, 'message_ids': messageIds},
        ),
      );

  /// Returns a user's profile photos, paginated via [offset]/[limit].
  Future<Json> getUserProfilePhotos(
    int userId, {
    int? offset,
    int? limit,
  }) async =>
      _o(
        await call('getUserProfilePhotos', {
          'user_id': userId,
          if (offset != null) 'offset': offset,
          if (limit != null) 'limit': limit,
        }),
      );

  /// Resolves a Telegram `file_id` into a [Json] containing `file_path`, which
  /// can then be downloaded with [downloadFile] or streamed directly from
  /// `https://api.telegram.org/file/bot<token>/<file_path>`.
  Future<Json> getFile(String fileId) async =>
      _o(await call('getFile', {'file_id': fileId}));

  /// Bans a user from the chat. In supergroups/channels they won't be able to
  /// return until unbanned; set [untilDate] for a temporary ban.
  Future<bool> banChatMember(
    Object chatId,
    int userId, {
    int? untilDate,
    bool? revokeMessages,
  }) async =>
      _b(
        await call('banChatMember', {
          'chat_id': chatId,
          'user_id': userId,
          if (untilDate != null) 'until_date': untilDate,
          if (revokeMessages != null) 'revoke_messages': revokeMessages,
        }),
      );

  /// Lifts a ban, allowing the user to rejoin. Set [onlyIfBanned] to avoid
  /// accidentally removing a user who is currently a member.
  Future<bool> unbanChatMember(
    Object chatId,
    int userId, {
    bool? onlyIfBanned,
  }) async =>
      _b(
        await call('unbanChatMember', {
          'chat_id': chatId,
          'user_id': userId,
          if (onlyIfBanned != null) 'only_if_banned': onlyIfBanned,
        }),
      );

  /// Restricts what a member can do in a supergroup via [permissions]
  /// (e.g. mute them by disabling `canSendMessages`), optionally until [untilDate].
  Future<bool> restrictChatMember(
    Object chatId,
    int userId,
    ChatPermissions permissions, {
    bool? useIndependentChatPermissions,
    int? untilDate,
  }) async =>
      _b(
        await call('restrictChatMember', {
          'chat_id': chatId,
          'user_id': userId,
          'permissions': permissions.toJson(),
          if (useIndependentChatPermissions != null)
            'use_independent_chat_permissions': useIndependentChatPermissions,
          if (untilDate != null) 'until_date': untilDate,
        }),
      );

  /// Promotes or demotes a user to/from chat administrator, granting the
  /// specific admin privileges passed as named booleans.
  Future<bool> promoteChatMember(
    Object chatId,
    int userId, {
    bool? isAnonymous,
    bool? canManageChat,
    bool? canDeleteMessages,
    bool? canManageVideoChats,
    bool? canRestrictMembers,
    bool? canPromoteMembers,
    bool? canChangeInfo,
    bool? canInviteUsers,
    bool? canPostStories,
    bool? canEditStories,
    bool? canDeleteStories,
    bool? canPostMessages,
    bool? canEditMessages,
    bool? canPinMessages,
    bool? canManageTopics,
  }) async =>
      _b(
        await call('promoteChatMember', {
          'chat_id': chatId,
          'user_id': userId,
          if (isAnonymous != null) 'is_anonymous': isAnonymous,
          if (canManageChat != null) 'can_manage_chat': canManageChat,
          if (canDeleteMessages != null)
            'can_delete_messages': canDeleteMessages,
          if (canManageVideoChats != null)
            'can_manage_video_chats': canManageVideoChats,
          if (canRestrictMembers != null)
            'can_restrict_members': canRestrictMembers,
          if (canPromoteMembers != null)
            'can_promote_members': canPromoteMembers,
          if (canChangeInfo != null) 'can_change_info': canChangeInfo,
          if (canInviteUsers != null) 'can_invite_users': canInviteUsers,
          if (canPostStories != null) 'can_post_stories': canPostStories,
          if (canEditStories != null) 'can_edit_stories': canEditStories,
          if (canDeleteStories != null) 'can_delete_stories': canDeleteStories,
          if (canPostMessages != null) 'can_post_messages': canPostMessages,
          if (canEditMessages != null) 'can_edit_messages': canEditMessages,
          if (canPinMessages != null) 'can_pin_messages': canPinMessages,
          if (canManageTopics != null) 'can_manage_topics': canManageTopics,
        }),
      );

  /// Sets a custom title (shown instead of "Admin") for an admin in a supergroup.
  Future<bool> setChatAdministratorCustomTitle(
    Object chatId,
    int userId,
    String customTitle,
  ) async =>
      _b(
        await call('setChatAdministratorCustomTitle', {
          'chat_id': chatId,
          'user_id': userId,
          'custom_title': customTitle,
        }),
      );

  /// Bans an anonymous channel (acting as a sender chat) from a group/channel.
  Future<bool> banChatSenderChat(Object chatId, int senderChatId) async => _b(
        await call(
          'banChatSenderChat',
          {'chat_id': chatId, 'sender_chat_id': senderChatId},
        ),
      );

  /// Unbans a previously banned sender chat.
  Future<bool> unbanChatSenderChat(Object chatId, int senderChatId) async => _b(
        await call(
          'unbanChatSenderChat',
          {'chat_id': chatId, 'sender_chat_id': senderChatId},
        ),
      );

  /// Sets the default [ChatPermissions] that apply to all non-admin members of a chat.
  Future<bool> setChatPermissions(
    Object chatId,
    ChatPermissions permissions, {
    bool? useIndependentChatPermissions,
  }) async =>
      _b(
        await call('setChatPermissions', {
          'chat_id': chatId,
          'permissions': permissions.toJson(),
          if (useIndependentChatPermissions != null)
            'use_independent_chat_permissions': useIndependentChatPermissions,
        }),
      );

  /// Generates a new primary invite link for the chat, invalidating the previous one.
  Future<String> exportChatInviteLink(Object chatId) async =>
      _s(await call('exportChatInviteLink', {'chat_id': chatId}));

  /// Creates an additional (non-primary) invite link, optionally limited by
  /// [expireDate], [memberLimit], or requiring admin approval via [createsJoinRequest].
  Future<Json> createChatInviteLink(
    Object chatId, {
    String? name,
    int? expireDate,
    int? memberLimit,
    bool? createsJoinRequest,
  }) async =>
      _o(
        await call('createChatInviteLink', {
          'chat_id': chatId,
          if (name != null) 'name': name,
          if (expireDate != null) 'expire_date': expireDate,
          if (memberLimit != null) 'member_limit': memberLimit,
          if (createsJoinRequest != null)
            'creates_join_request': createsJoinRequest,
        }),
      );

  /// Edits a previously created non-primary invite link.
  Future<Json> editChatInviteLink(
    Object chatId,
    String inviteLink, {
    String? name,
    int? expireDate,
    int? memberLimit,
    bool? createsJoinRequest,
  }) async =>
      _o(
        await call('editChatInviteLink', {
          'chat_id': chatId,
          'invite_link': inviteLink,
          if (name != null) 'name': name,
          if (expireDate != null) 'expire_date': expireDate,
          if (memberLimit != null) 'member_limit': memberLimit,
          if (createsJoinRequest != null)
            'creates_join_request': createsJoinRequest,
        }),
      );

  /// Revokes an invite link so it can no longer be used to join.
  Future<Json> revokeChatInviteLink(Object chatId, String inviteLink) async =>
      _o(
        await call(
          'revokeChatInviteLink',
          {'chat_id': chatId, 'invite_link': inviteLink},
        ),
      );

  /// Creates a subscription invite link that charges [subscriptionPeriod] /
  /// [subscriptionPrice] in Telegram Stars for access to the channel.
  Future<Json> createChatSubscriptionInviteLink(
    Object chatId,
    int subscriptionPeriod,
    int subscriptionPrice, {
    String? name,
  }) async =>
      _o(
        await call('createChatSubscriptionInviteLink', {
          'chat_id': chatId,
          'subscription_period': subscriptionPeriod,
          'subscription_price': subscriptionPrice,
          if (name != null) 'name': name,
        }),
      );

  /// Edits the name of an existing subscription invite link.
  Future<Json> editChatSubscriptionInviteLink(
    Object chatId,
    String inviteLink, {
    String? name,
  }) async =>
      _o(
        await call('editChatSubscriptionInviteLink', {
          'chat_id': chatId,
          'invite_link': inviteLink,
          if (name != null) 'name': name,
        }),
      );

  /// Approves a pending join request for a chat that requires admin approval.
  Future<bool> approveChatJoinRequest(Object chatId, int userId) async => _b(
        await call(
          'approveChatJoinRequest',
          {'chat_id': chatId, 'user_id': userId},
        ),
      );

  /// Declines a pending join request.
  Future<bool> declineChatJoinRequest(Object chatId, int userId) async => _b(
        await call(
          'declineChatJoinRequest',
          {'chat_id': chatId, 'user_id': userId},
        ),
      );

  /// Sets a new chat photo, uploaded fresh (not reused via `file_id`).
  Future<bool> setChatPhoto(Object chatId, InputFile photo) async =>
      _b(await call('setChatPhoto', {'chat_id': chatId}, {'photo': photo}));

  /// Deletes the chat's current photo.
  Future<bool> deleteChatPhoto(Object chatId) async =>
      _b(await call('deleteChatPhoto', {'chat_id': chatId}));

  /// Renames the chat.
  Future<bool> setChatTitle(Object chatId, String title) async =>
      _b(await call('setChatTitle', {'chat_id': chatId, 'title': title}));

  /// Sets or clears the chat's description.
  Future<bool> setChatDescription(Object chatId, {String? description}) async =>
      _b(
        await call('setChatDescription', {
          'chat_id': chatId,
          if (description != null) 'description': description,
        }),
      );

  /// Pins a message at the top of the chat.
  Future<bool> pinChatMessage(
    Object chatId,
    int messageId, {
    String? businessConnectionId,
    bool? disableNotification,
  }) async =>
      _b(
        await call('pinChatMessage', {
          'chat_id': chatId,
          'message_id': messageId,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (disableNotification != null)
            'disable_notification': disableNotification,
        }),
      );

  /// Unpins a message. If [messageId] is omitted, unpins the most recently pinned message.
  Future<bool> unpinChatMessage(
    Object chatId, {
    String? businessConnectionId,
    int? messageId,
  }) async =>
      _b(
        await call('unpinChatMessage', {
          'chat_id': chatId,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageId != null) 'message_id': messageId,
        }),
      );

  /// Unpins every currently pinned message in the chat.
  Future<bool> unpinAllChatMessages(Object chatId) async =>
      _b(await call('unpinAllChatMessages', {'chat_id': chatId}));

  /// Makes the bot leave the given group, supergroup, or channel.
  Future<bool> leaveChat(Object chatId) async =>
      _b(await call('leaveChat', {'chat_id': chatId}));

  /// Fetches up-to-date information about a chat (title, description, permissions, etc).
  Future<Json> getChat(Object chatId) async =>
      _o(await call('getChat', {'chat_id': chatId}));

  /// Lists every administrator (and the owner) of the chat.
  Future<List<Json>> getChatAdministrators(Object chatId) async =>
      _l(await call('getChatAdministrators', {'chat_id': chatId}));

  /// Returns the number of members in the chat.
  Future<int> getChatMemberCount(Object chatId) async =>
      _i(await call('getChatMemberCount', {'chat_id': chatId}));

  /// Fetches a specific member's status and permissions within the chat.
  Future<Json> getChatMember(Object chatId, int userId) async =>
      _o(await call('getChatMember', {'chat_id': chatId, 'user_id': userId}));

  /// Sets the group's custom sticker set (supergroups only).
  Future<bool> setChatStickerSet(Object chatId, String stickerSetName) async =>
      _b(
        await call(
          'setChatStickerSet',
          {'chat_id': chatId, 'sticker_set_name': stickerSetName},
        ),
      );

  /// Removes the group's custom sticker set.
  Future<bool> deleteChatStickerSet(Object chatId) async =>
      _b(await call('deleteChatStickerSet', {'chat_id': chatId}));

  /// Lists the built-in custom emoji stickers usable as forum topic icons.
  Future<List<Json>> getForumTopicIconStickers() async =>
      _l(await call('getForumTopicIconStickers'));

  /// Creates a new topic in a forum-enabled supergroup.
  Future<Json> createForumTopic(
    Object chatId,
    String name, {
    int? iconColor,
    String? iconCustomEmojiId,
  }) async =>
      _o(
        await call('createForumTopic', {
          'chat_id': chatId,
          'name': name,
          if (iconColor != null) 'icon_color': iconColor,
          if (iconCustomEmojiId != null)
            'icon_custom_emoji_id': iconCustomEmojiId,
        }),
      );

  /// Renames a forum topic and/or changes its icon.
  Future<bool> editForumTopic(
    Object chatId,
    int messageThreadId, {
    String? name,
    String? iconCustomEmojiId,
  }) async =>
      _b(
        await call('editForumTopic', {
          'chat_id': chatId,
          'message_thread_id': messageThreadId,
          if (name != null) 'name': name,
          if (iconCustomEmojiId != null)
            'icon_custom_emoji_id': iconCustomEmojiId,
        }),
      );

  /// Closes a forum topic (prevents new messages until reopened).
  Future<bool> closeForumTopic(Object chatId, int messageThreadId) async => _b(
        await call(
          'closeForumTopic',
          {'chat_id': chatId, 'message_thread_id': messageThreadId},
        ),
      );

  /// Reopens a previously closed forum topic.
  Future<bool> reopenForumTopic(Object chatId, int messageThreadId) async => _b(
        await call(
          'reopenForumTopic',
          {'chat_id': chatId, 'message_thread_id': messageThreadId},
        ),
      );

  /// Deletes a forum topic and every message inside it.
  Future<bool> deleteForumTopic(Object chatId, int messageThreadId) async => _b(
        await call(
          'deleteForumTopic',
          {'chat_id': chatId, 'message_thread_id': messageThreadId},
        ),
      );

  /// Unpins every message pinned within a specific forum topic.
  Future<bool> unpinAllForumTopicMessages(
    Object chatId,
    int messageThreadId,
  ) async =>
      _b(
        await call(
          'unpinAllForumTopicMessages',
          {'chat_id': chatId, 'message_thread_id': messageThreadId},
        ),
      );

  /// Renames the forum's built-in "General" topic.
  Future<bool> editGeneralForumTopic(Object chatId, String name) async => _b(
        await call('editGeneralForumTopic', {'chat_id': chatId, 'name': name}),
      );

  /// Closes the "General" forum topic.
  Future<bool> closeGeneralForumTopic(Object chatId) async =>
      _b(await call('closeGeneralForumTopic', {'chat_id': chatId}));

  /// Reopens the "General" forum topic.
  Future<bool> reopenGeneralForumTopic(Object chatId) async =>
      _b(await call('reopenGeneralForumTopic', {'chat_id': chatId}));

  /// Hides the "General" forum topic from the topic list.
  Future<bool> hideGeneralForumTopic(Object chatId) async =>
      _b(await call('hideGeneralForumTopic', {'chat_id': chatId}));

  /// Unhides the "General" forum topic.
  Future<bool> unhideGeneralForumTopic(Object chatId) async =>
      _b(await call('unhideGeneralForumTopic', {'chat_id': chatId}));

  /// Unpins every message pinned within the "General" forum topic.
  Future<bool> unpinAllGeneralForumTopicMessages(Object chatId) async =>
      _b(await call('unpinAllGeneralForumTopicMessages', {'chat_id': chatId}));

  /// Responds to a button press from an [InlineKeyboardButton.callback] button.
  ///
  /// You should call this for *every* callback query you receive, even with no
  /// arguments, so Telegram stops showing a loading spinner on the button. Set
  /// [showAlert] to show the response as a popup instead of a toast.
  Future<bool> answerCallbackQuery(
    String callbackQueryId, {
    String? text,
    bool? showAlert,
    String? url,
    int? cacheTime,
  }) async =>
      _b(
        await call('answerCallbackQuery', {
          'callback_query_id': callbackQueryId,
          if (text != null) 'text': text,
          if (showAlert != null) 'show_alert': showAlert,
          if (url != null) 'url': url,
          if (cacheTime != null) 'cache_time': cacheTime,
        }),
      );

  /// Sets the list of commands shown in the chat's `/` menu, optionally scoped
  /// via [scope]/[languageCode].
  Future<bool> setMyCommands(
    List<Json> commands, {
    Json? scope,
    String? languageCode,
  }) async =>
      _b(
        await call('setMyCommands', {
          'commands': commands,
          if (scope != null) 'scope': scope,
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Clears the command list for the given [scope]/[languageCode], falling
  /// back to a higher-level scope.
  Future<bool> deleteMyCommands({Json? scope, String? languageCode}) async =>
      _b(
        await call('deleteMyCommands', {
          if (scope != null) 'scope': scope,
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Returns the currently configured command list for a given [scope]/[languageCode].
  Future<List<Json>> getMyCommands({Json? scope, String? languageCode}) async =>
      _l(
        await call('getMyCommands', {
          if (scope != null) 'scope': scope,
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Sets the bot's display name.
  Future<bool> setMyName({String? name, String? languageCode}) async => _b(
        await call('setMyName', {
          if (name != null) 'name': name,
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Returns the bot's current display name.
  Future<Json> getMyName({String? languageCode}) async => _o(
        await call('getMyName', {
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Sets the description shown on the bot's profile page before a user has started it.
  Future<bool> setMyDescription({
    String? description,
    String? languageCode,
  }) async =>
      _b(
        await call('setMyDescription', {
          if (description != null) 'description': description,
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Returns the bot's current profile description.
  Future<Json> getMyDescription({String? languageCode}) async => _o(
        await call('getMyDescription', {
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Sets the short description shown alongside the bot's profile photo and in chat sharing.
  Future<bool> setMyShortDescription({
    String? shortDescription,
    String? languageCode,
  }) async =>
      _b(
        await call('setMyShortDescription', {
          if (shortDescription != null) 'short_description': shortDescription,
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Returns the bot's current short description.
  Future<Json> getMyShortDescription({String? languageCode}) async => _o(
        await call('getMyShortDescription', {
          if (languageCode != null) 'language_code': languageCode,
        }),
      );

  /// Configures the menu button shown in a private chat (e.g. to open a Web App).
  Future<bool> setChatMenuButton({Object? chatId, Json? menuButton}) async =>
      _b(
        await call('setChatMenuButton', {
          if (chatId != null) 'chat_id': chatId,
          if (menuButton != null) 'menu_button': menuButton,
        }),
      );

  /// Returns the currently configured menu button for a chat.
  Future<Json> getChatMenuButton({Object? chatId}) async => _o(
        await call('getChatMenuButton', {
          if (chatId != null) 'chat_id': chatId,
        }),
      );

  /// Sets the default admin rights requested when the bot is added as an admin.
  Future<bool> setMyDefaultAdministratorRights({
    ChatAdministratorRights? rights,
    bool? forChannels,
  }) async =>
      _b(
        await call('setMyDefaultAdministratorRights', {
          if (rights != null) 'rights': rights.toJson(),
          if (forChannels != null) 'for_channels': forChannels,
        }),
      );

  /// Returns the bot's currently configured default admin rights.
  Future<Json> getMyDefaultAdministratorRights({bool? forChannels}) async => _o(
        await call('getMyDefaultAdministratorRights', {
          if (forChannels != null) 'for_channels': forChannels,
        }),
      );

  /// Responds to an inline query (`@yourbot ...` typed in any chat) with a list
  /// of [results] the user can pick from.
  Future<bool> answerInlineQuery(
    String inlineQueryId,
    List<Json> results, {
    int? cacheTime,
    bool? isPersonal,
    String? nextOffset,
    Json? button,
  }) async =>
      _b(
        await call('answerInlineQuery', {
          'inline_query_id': inlineQueryId,
          'results': results,
          if (cacheTime != null) 'cache_time': cacheTime,
          if (isPersonal != null) 'is_personal': isPersonal,
          if (nextOffset != null) 'next_offset': nextOffset,
          if (button != null) 'button': button,
        }),
      );

  /// Sends a [result] back to a Web App that was opened via a `switch_inline_query`-style button.
  Future<Json> answerWebAppQuery(String webAppQueryId, Json result) async => _o(
        await call(
          'answerWebAppQuery',
          {'web_app_query_id': webAppQueryId, 'result': result},
        ),
      );

  /// Pre-uploads an inline message result so it can be reused efficiently across many users.
  Future<Json> savePreparedInlineMessage(
    int userId,
    Json result, {
    bool? allowUserChats,
    bool? allowBotChats,
    bool? allowGroupChats,
    bool? allowChannelChats,
  }) async =>
      _o(
        await call('savePreparedInlineMessage', {
          'user_id': userId,
          'result': result,
          if (allowUserChats != null) 'allow_user_chats': allowUserChats,
          if (allowBotChats != null) 'allow_bot_chats': allowBotChats,
          if (allowGroupChats != null) 'allow_group_chats': allowGroupChats,
          if (allowChannelChats != null)
            'allow_channel_chats': allowChannelChats,
        }),
      );

  /// Sends an invoice for a payment (physical goods, digital goods, or
  /// Telegram Stars). Use [providerToken] for a payment provider, or leave it
  /// empty when charging in Telegram Stars (`currency: 'XTR'`).
  Future<Json> sendInvoice(
    Object chatId,
    String title,
    String description,
    String payload,
    String currency,
    List<Json> prices, {
    int? messageThreadId,
    String? providerToken,
    int? maxTipAmount,
    List<int>? suggestedTipAmounts,
    String? startParameter,
    String? providerData,
    String? photoUrl,
    int? photoSize,
    int? photoWidth,
    int? photoHeight,
    bool? needName,
    bool? needPhoneNumber,
    bool? needEmail,
    bool? needShippingAddress,
    bool? sendPhoneNumberToProvider,
    bool? sendEmailToProvider,
    bool? isFlexible,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    InlineKeyboardMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendInvoice', {
          'chat_id': chatId,
          'title': title,
          'description': description,
          'payload': payload,
          'currency': currency,
          'prices': prices,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (providerToken != null) 'provider_token': providerToken,
          if (maxTipAmount != null) 'max_tip_amount': maxTipAmount,
          if (suggestedTipAmounts != null)
            'suggested_tip_amounts': suggestedTipAmounts,
          if (startParameter != null) 'start_parameter': startParameter,
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
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Creates a standalone payment link for an invoice, without sending it to a chat.
  Future<String> createInvoiceLink(
    String title,
    String description,
    String payload,
    String currency,
    List<Json> prices, {
    String? businessConnectionId,
    String? providerToken,
    int? subscriptionPeriod,
    int? maxTipAmount,
    List<int>? suggestedTipAmounts,
    String? providerData,
    String? photoUrl,
    int? photoSize,
    int? photoWidth,
    int? photoHeight,
    bool? needName,
    bool? needPhoneNumber,
    bool? needEmail,
    bool? needShippingAddress,
    bool? sendPhoneNumberToProvider,
    bool? sendEmailToProvider,
    bool? isFlexible,
  }) async =>
      _s(
        await call('createInvoiceLink', {
          'title': title,
          'description': description,
          'payload': payload,
          'currency': currency,
          'prices': prices,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (providerToken != null) 'provider_token': providerToken,
          if (subscriptionPeriod != null)
            'subscription_period': subscriptionPeriod,
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
        }),
      );

  /// Responds to a shipping query raised for an invoice with flexible shipping options.
  Future<bool> answerShippingQuery(
    String shippingQueryId,
    bool ok, {
    List<Json>? shippingOptions,
    String? errorMessage,
  }) async =>
      _b(
        await call('answerShippingQuery', {
          'shipping_query_id': shippingQueryId,
          'ok': ok,
          if (shippingOptions != null) 'shipping_options': shippingOptions,
          if (errorMessage != null) 'error_message': errorMessage,
        }),
      );

  /// Responds to the final pre-checkout confirmation before payment is captured.
  /// Must be answered within 10 seconds or the payment is cancelled.
  Future<bool> answerPreCheckoutQuery(
    String preCheckoutQueryId,
    bool ok, {
    String? errorMessage,
  }) async =>
      _b(
        await call('answerPreCheckoutQuery', {
          'pre_checkout_query_id': preCheckoutQueryId,
          'ok': ok,
          if (errorMessage != null) 'error_message': errorMessage,
        }),
      );

  /// Lists the bot's incoming and outgoing Telegram Stars transactions.
  Future<Json> getStarTransactions({int? offset, int? limit}) async => _o(
        await call('getStarTransactions', {
          if (offset != null) 'offset': offset,
          if (limit != null) 'limit': limit,
        }),
      );

  /// Refunds a successful payment that was made in Telegram Stars.
  Future<bool> refundStarPayment(
    int userId,
    String telegramPaymentChargeId,
  ) async =>
      _b(
        await call('refundStarPayment', {
          'user_id': userId,
          'telegram_payment_charge_id': telegramPaymentChargeId,
        }),
      );

  /// Cancels or reactivates a user's recurring Telegram Stars subscription payment.
  Future<bool> editUserStarSubscription(
    int userId,
    String telegramPaymentChargeId,
    bool isCanceled,
  ) async =>
      _b(
        await call('editUserStarSubscription', {
          'user_id': userId,
          'telegram_payment_charge_id': telegramPaymentChargeId,
          'is_canceled': isCanceled,
        }),
      );

  /// Sends a Telegram Game (an HTML5 game registered with @BotFather).
  Future<Json> sendGame(
    int chatId,
    String gameShortName, {
    String? businessConnectionId,
    int? messageThreadId,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    InlineKeyboardMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendGame', {
          'chat_id': chatId,
          'game_short_name': gameShortName,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Updates a user's score in a previously sent game message.
  Future<dynamic> setGameScore(
    int userId,
    int score, {
    bool? force,
    bool? disableEditMessage,
    int? chatId,
    int? messageId,
    String? inlineMessageId,
  }) =>
      call('setGameScore', {
        'user_id': userId,
        'score': score,
        if (force != null) 'force': force,
        if (disableEditMessage != null)
          'disable_edit_message': disableEditMessage,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (inlineMessageId != null) 'inline_message_id': inlineMessageId,
      });

  /// Fetches the high score table for a game message.
  Future<List<Json>> getGameHighScores(
    int userId, {
    int? chatId,
    int? messageId,
    String? inlineMessageId,
  }) async =>
      _l(
        await call('getGameHighScores', {
          'user_id': userId,
          if (chatId != null) 'chat_id': chatId,
          if (messageId != null) 'message_id': messageId,
          if (inlineMessageId != null) 'inline_message_id': inlineMessageId,
        }),
      );

  /// Sends a sticker from a `file_id`, URL, or local upload.
  Future<Json> sendSticker(
    Object chatId,
    InputFile sticker, {
    String? businessConnectionId,
    int? messageThreadId,
    String? emoji,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call(
          'sendSticker',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (emoji != null) 'emoji': emoji,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
          },
          {'sticker': sticker},
        ),
      );

  /// Fetches metadata and every sticker in a named sticker set.
  Future<Json> getStickerSet(String name) async =>
      _o(await call('getStickerSet', {'name': name}));

  /// Resolves a list of custom emoji IDs into full sticker information.
  Future<List<Json>> getCustomEmojiStickers(
    List<String> customEmojiIds,
  ) async =>
      _l(
        await call(
          'getCustomEmojiStickers',
          {'custom_emoji_ids': customEmojiIds},
        ),
      );

  /// Uploads a file to be later reused as a sticker in [createNewStickerSet]
  /// or [addStickerToSet], returning a reusable `file_id`.
  Future<Json> uploadStickerFile(
    int userId,
    InputFile sticker,
    StickerFormat stickerFormat,
  ) async =>
      _o(
        await call(
          'uploadStickerFile',
          {'user_id': userId, 'sticker_format': stickerFormat.value},
          {'sticker': sticker},
        ),
      );

  /// Creates a new sticker set owned by [userId].
  Future<bool> createNewStickerSet(
    int userId,
    String name,
    String title,
    List<InputSticker> stickers, {
    StickerType? stickerType,
    bool? needsRepainting,
  }) async {
    final files = <String, InputFile>{};
    final stickersJson = <Json>[];
    for (var i = 0; i < stickers.length; i++) {
      final item = stickers[i];
      String ref;
      if (item.sticker.isUpload) {
        final key = 'sticker$i';
        files[key] = item.sticker;
        ref = 'attach://$key';
      } else {
        ref = item.sticker.remoteValue!;
      }
      stickersJson.add(item.toJson(ref));
    }
    return _b(
      await call(
        'createNewStickerSet',
        {
          'user_id': userId,
          'name': name,
          'title': title,
          'stickers': stickersJson,
          if (stickerType != null) 'sticker_type': stickerType.value,
          if (needsRepainting != null) 'needs_repainting': needsRepainting,
        },
        files,
      ),
    );
  }

  /// Adds one more sticker to an existing set created by the bot.
  Future<bool> addStickerToSet(
    int userId,
    String name,
    InputSticker sticker,
  ) async {
    final files = <String, InputFile>{};
    String ref;
    if (sticker.sticker.isUpload) {
      files['sticker'] = sticker.sticker;
      ref = 'attach://sticker';
    } else {
      ref = sticker.sticker.remoteValue!;
    }
    return _b(
      await call(
        'addStickerToSet',
        {'user_id': userId, 'name': name, 'sticker': sticker.toJson(ref)},
        files,
      ),
    );
  }

  /// Moves a sticker to a new zero-based [position] within its set.
  Future<bool> setStickerPositionInSet(String sticker, int position) async =>
      _b(
        await call(
          'setStickerPositionInSet',
          {'sticker': sticker, 'position': position},
        ),
      );

  /// Removes a sticker from its set.
  Future<bool> deleteStickerFromSet(String sticker) async =>
      _b(await call('deleteStickerFromSet', {'sticker': sticker}));

  /// Replaces an existing sticker in a set with a new one, preserving its position.
  Future<bool> replaceStickerInSet(
    int userId,
    String name,
    String oldSticker,
    InputSticker sticker,
  ) async {
    final files = <String, InputFile>{};
    String ref;
    if (sticker.sticker.isUpload) {
      files['sticker'] = sticker.sticker;
      ref = 'attach://sticker';
    } else {
      ref = sticker.sticker.remoteValue!;
    }
    return _b(
      await call(
        'replaceStickerInSet',
        {
          'user_id': userId,
          'name': name,
          'old_sticker': oldSticker,
          'sticker': sticker.toJson(ref),
        },
        files,
      ),
    );
  }

  /// Changes the emoji associated with a sticker.
  Future<bool> setStickerEmojiList(
    String sticker,
    List<String> emojiList,
  ) async =>
      _b(
        await call(
          'setStickerEmojiList',
          {'sticker': sticker, 'emoji_list': emojiList},
        ),
      );

  /// Changes the search keywords associated with a sticker.
  Future<bool> setStickerKeywords(
    String sticker, {
    List<String>? keywords,
  }) async =>
      _b(
        await call('setStickerKeywords', {
          'sticker': sticker,
          if (keywords != null) 'keywords': keywords,
        }),
      );

  /// Changes where a mask sticker is anchored on a face.
  Future<bool> setStickerMaskPosition(
    String sticker, {
    Json? maskPosition,
  }) async =>
      _b(
        await call('setStickerMaskPosition', {
          'sticker': sticker,
          if (maskPosition != null) 'mask_position': maskPosition,
        }),
      );

  /// Renames a sticker set.
  Future<bool> setStickerSetTitle(String name, String title) async =>
      _b(await call('setStickerSetTitle', {'name': name, 'title': title}));

  /// Sets the thumbnail shown for a sticker set in the sticker picker.
  Future<bool> setStickerSetThumbnail(
    String name,
    int userId,
    StickerFormat format, {
    InputFile? thumbnail,
  }) async =>
      _b(
        await call(
          'setStickerSetThumbnail',
          {'name': name, 'user_id': userId, 'format': format.value},
          thumbnail != null ? {'thumbnail': thumbnail} : null,
        ),
      );

  /// Sets the thumbnail of a custom emoji sticker set from one of its own stickers.
  Future<bool> setCustomEmojiStickerSetThumbnail(
    String name, {
    String? customEmojiId,
  }) async =>
      _b(
        await call('setCustomEmojiStickerSetThumbnail', {
          'name': name,
          if (customEmojiId != null) 'custom_emoji_id': customEmojiId,
        }),
      );

  /// Deletes an entire sticker set owned by the bot.
  Future<bool> deleteStickerSet(String name) async =>
      _b(await call('deleteStickerSet', {'name': name}));

  /// Lists the boosts a user has applied to a chat.
  Future<Json> getUserChatBoosts(Object chatId, int userId) async => _o(
        await call('getUserChatBoosts', {'chat_id': chatId, 'user_id': userId}),
      );

  /// Verifies [userId] on behalf of the organization that owns the bot,
  /// showing a verification badge on their profile.
  ///
  /// Only bots with explicit Telegram approval for third-party verification
  /// can use this method — see https://telegram.org/verify to apply. Call
  /// this again with a new [customDescription] to update it; there's no
  /// separate "update" method. Use [removeUserVerification] to remove the badge.
  Future<bool> verifyUser(int userId, {String? customDescription}) async => _b(
        await call('verifyUser', {
          'user_id': userId,
          if (customDescription != null)
            'custom_description': customDescription,
        }),
      );

  /// Verifies [chatId] (a group, supergroup, or channel — not a direct
  /// messages chat) on behalf of the organization that owns the bot. See
  /// [verifyUser] for details on the approval this requires.
  Future<bool> verifyChat(Object chatId, {String? customDescription}) async =>
      _b(
        await call('verifyChat', {
          'chat_id': chatId,
          if (customDescription != null)
            'custom_description': customDescription,
        }),
      );

  /// Removes a third-party verification badge previously granted to [userId] via [verifyUser].
  Future<bool> removeUserVerification(int userId) async =>
      _b(await call('removeUserVerification', {'user_id': userId}));

  /// Removes a third-party verification badge previously granted to [chatId] via [verifyChat].
  Future<bool> removeChatVerification(Object chatId) async =>
      _b(await call('removeChatVerification', {'chat_id': chatId}));

  /// Returns the bot's current balance of Telegram Stars as a `StarAmount` object (raw JSON).
  Future<Json> getMyStarBalance() async => _o(await call('getMyStarBalance'));

  /// Sets the bot's profile photo. [photo] can be a static image
  /// ([InputProfilePhotoStatic]) or a short animation ([InputProfilePhotoAnimated]).
  Future<bool> setMyProfilePhoto(InputProfilePhoto photo) async {
    final files = <String, InputFile>{};
    final photoJson = photo.toJson(files);
    return _b(await call('setMyProfilePhoto', {'photo': photoJson}, files));
  }

  /// Removes the bot's current profile photo.
  Future<bool> removeMyProfilePhoto() async =>
      _b(await call('removeMyProfilePhoto'));

  /// Returns the audio files a user has added to their profile, as a `UserProfileAudios` object (raw JSON).
  Future<Json> getUserProfileAudios(
    int userId, {
    int? offset,
    int? limit,
  }) async =>
      _o(
        await call('getUserProfileAudios', {
          'user_id': userId,
          if (offset != null) 'offset': offset,
          if (limit != null) 'limit': limit,
        }),
      );

  /// Returns the current access token of a bot managed by this bot ([botId]
  /// is the managed bot's user ID). Only available to managing bots — see
  /// https://core.telegram.org/bots/features#secretary-bots.
  Future<String> getManagedBotToken(int botId) async =>
      _s(await call('getManagedBotToken', {'bot_id': botId}));

  /// Generates a new access token for a bot managed by this bot ([botId] is
  /// the managed bot's user ID), invalidating the previous one. Use this to
  /// rotate a managed bot's token, e.g. after a suspected compromise.
  Future<String> replaceManagedBotToken(int botId) async =>
      _s(await call('replaceManagedBotToken', {'bot_id': botId}));

  /// Stores a keyboard [button] (e.g. a users/chat/managed-bot request
  /// button — see [KeyboardButton]) for reuse from a Mini App via
  /// `sendPreparedMessage`. Returns a `PreparedKeyboardButton` (raw JSON).
  /// The `allow*Chats` flags mirror [Bot.savePreparedInlineMessage]'s.
  Future<Json> savePreparedKeyboardButton(
    int userId,
    Json button, {
    bool? allowUserChats,
    bool? allowBotChats,
    bool? allowGroupChats,
    bool? allowChannelChats,
  }) async =>
      _o(
        await call('savePreparedKeyboardButton', {
          'user_id': userId,
          'button': button,
          if (allowUserChats != null) 'allow_user_chats': allowUserChats,
          if (allowBotChats != null) 'allow_bot_chats': allowBotChats,
          if (allowGroupChats != null) 'allow_group_chats': allowGroupChats,
          if (allowChannelChats != null)
            'allow_channel_chats': allowChannelChats,
        }),
      );

  /// Removes one user's reaction from a message in a chat the bot administers.
  Future<bool> deleteMessageReaction(
    Object chatId,
    int messageId,
    int userId,
  ) async =>
      _b(
        await call('deleteMessageReaction', {
          'chat_id': chatId,
          'message_id': messageId,
          'user_id': userId,
        }),
      );

  /// Removes all reactions from a message in a chat the bot administers.
  Future<bool> deleteAllMessageReactions(Object chatId, int messageId) async =>
      _b(
        await call('deleteAllMessageReactions', {
          'chat_id': chatId,
          'message_id': messageId,
        }),
      );

  /// Approves a suggested post in a channel direct-messages chat. If
  /// [sendDate] is omitted, the post is published immediately.
  Future<bool> approveSuggestedPost(
    int chatId,
    int messageId, {
    int? sendDate,
  }) async =>
      _b(
        await call('approveSuggestedPost', {
          'chat_id': chatId,
          'message_id': messageId,
          if (sendDate != null) 'send_date': sendDate,
        }),
      );

  /// Declines a suggested post in a channel direct-messages chat, optionally
  /// explaining why via [comment].
  Future<bool> declineSuggestedPost(
    int chatId,
    int messageId, {
    String? comment,
  }) async =>
      _b(
        await call('declineSuggestedPost', {
          'chat_id': chatId,
          'message_id': messageId,
          if (comment != null) 'comment': comment,
        }),
      );

  /// Sends a checklist on behalf of a connected business account.
  Future<Json> sendChecklist(
    String businessConnectionId,
    int chatId,
    InputChecklist checklist, {
    bool? disableNotification,
    bool? protectContent,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    InlineKeyboardMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendChecklist', {
          'business_connection_id': businessConnectionId,
          'chat_id': chatId,
          'checklist': checklist.toJson(),
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Edits a checklist previously sent on behalf of a connected business account.
  Future<Json> editMessageChecklist(
    String businessConnectionId,
    int chatId,
    int messageId,
    InputChecklist checklist, {
    InlineKeyboardMarkup? replyMarkup,
  }) async =>
      _o(
        await call('editMessageChecklist', {
          'business_connection_id': businessConnectionId,
          'chat_id': chatId,
          'message_id': messageId,
          'checklist': checklist.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Sends a "live photo" — a still [photo] paired with a short [video] clip
  /// that plays when the recipient taps it.
  ///
  /// If [receiverUserId] is set (together with [callbackQueryId], from a
  /// callback query the guest triggered), the message is sent as an
  /// *ephemeral* message visible only to that user — see
  /// [editEphemeralMessageText] and friends for editing it afterwards.
  Future<Json> sendLivePhoto(
    Object chatId,
    InputFile photo,
    InputFile video, {
    String? businessConnectionId,
    int? messageThreadId,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    bool? hasSpoiler,
    int? duration,
    int? width,
    int? height,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
    int? receiverUserId,
    String? callbackQueryId,
  }) async =>
      _o(
        await call(
          'sendLivePhoto',
          {
            'chat_id': chatId,
            if (businessConnectionId != null)
              'business_connection_id': businessConnectionId,
            if (messageThreadId != null) 'message_thread_id': messageThreadId,
            if (caption != null) 'caption': caption,
            if (parseMode != null) 'parse_mode': parseMode.value,
            if (captionEntities != null) 'caption_entities': captionEntities,
            if (showCaptionAboveMedia != null)
              'show_caption_above_media': showCaptionAboveMedia,
            if (hasSpoiler != null) 'has_spoiler': hasSpoiler,
            if (duration != null) 'duration': duration,
            if (width != null) 'width': width,
            if (height != null) 'height': height,
            if (disableNotification != null)
              'disable_notification': disableNotification,
            if (protectContent != null) 'protect_content': protectContent,
            if (allowPaidBroadcast != null)
              'allow_paid_broadcast': allowPaidBroadcast,
            if (messageEffectId != null) 'message_effect_id': messageEffectId,
            if (replyParameters != null)
              'reply_parameters': replyParameters.toJson(),
            if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
            if (receiverUserId != null) 'receiver_user_id': receiverUserId,
            if (callbackQueryId != null) 'callback_query_id': callbackQueryId,
          },
          {'photo': photo, 'video': video},
        ),
      );

  /// Answers a query sent by a guest (an unauthenticated user browsing via
  /// Guest Mode), delivering [result] back to them. [result] should be
  /// shaped like a `SentGuestMessage`; raw [Json] is used since the shape
  /// depends on what kind of content you send back.
  Future<Json> answerGuestQuery(String guestQueryId, Json result) async => _o(
        await call(
          'answerGuestQuery',
          {'guest_query_id': guestQueryId, 'result': result},
        ),
      );

  /// Sends a rich message — one built from formatted text and structured
  /// content blocks (images, lists, embeds, etc) rather than a single plain
  /// caption. [richMessage] should be shaped like Telegram's
  /// `InputRichMessage` (its `blocks` array and optional `media`); raw
  /// [Json] is used given how many block types that structure can contain —
  /// see https://core.telegram.org/bots/api#inputrichmessage for the shape,
  /// or fall back to [call] directly if this typed wrapper doesn't fit.
  Future<Json> sendRichMessage(
    Object chatId,
    Json richMessage, {
    String? businessConnectionId,
    int? messageThreadId,
    bool? disableNotification,
    bool? protectContent,
    bool? allowPaidBroadcast,
    String? messageEffectId,
    ReplyParameters? replyParameters,
    ReplyMarkup? replyMarkup,
  }) async =>
      _o(
        await call('sendRichMessage', {
          'chat_id': chatId,
          'rich_message': richMessage,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (protectContent != null) 'protect_content': protectContent,
          if (allowPaidBroadcast != null)
            'allow_paid_broadcast': allowPaidBroadcast,
          if (messageEffectId != null) 'message_effect_id': messageEffectId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        }),
      );

  /// Streams a rich message to the chat progressively, the way
  /// [sendMessageDraft] streams plain text — useful for showing a rich
  /// message being "typed out" block by block. See [sendRichMessage] for
  /// the shape of [richMessage].
  Future<bool> sendRichMessageDraft(
    Object chatId,
    Json richMessage, {
    String? businessConnectionId,
    int? messageThreadId,
    ReplyParameters? replyParameters,
  }) async =>
      _b(
        await call('sendRichMessageDraft', {
          'chat_id': chatId,
          'rich_message': richMessage,
          if (businessConnectionId != null)
            'business_connection_id': businessConnectionId,
          if (messageThreadId != null) 'message_thread_id': messageThreadId,
          if (replyParameters != null)
            'reply_parameters': replyParameters.toJson(),
        }),
      );

  /// Answers a join-request query routed to this bot by a chat that has
  /// designated it as a "guard bot" (see `ChatFullInfo.guard_bot`),
  /// resolving the request per [result]: `'approve'` to let the user join,
  /// `'decline'` to reject them, or `'queue'` to leave the decision to
  /// other administrators.
  Future<bool> answerChatJoinRequestQuery(
    String chatJoinRequestQueryId,
    String result,
  ) async =>
      _b(
        await call('answerChatJoinRequestQuery', {
          'chat_join_request_query_id': chatJoinRequestQueryId,
          'result': result,
        }),
      );

  /// Sends a Web App (Mini App) to a user whose join-request query this bot
  /// received as a guard bot — e.g. to collect information before
  /// approving them via [answerChatJoinRequestQuery]. [webApp] should be
  /// shaped like `WebAppInfo` (a `url` field); raw [Json] is used for
  /// consistency with [answerWebAppQuery].
  Future<Json> sendChatJoinRequestWebApp(
    String chatJoinRequestQueryId,
    Json webApp,
  ) async =>
      _o(
        await call('sendChatJoinRequestWebApp', {
          'chat_join_request_query_id': chatJoinRequestQueryId,
          'web_app': webApp,
        }),
      );

  /// Edits the text of an ephemeral message (one only visible to a single
  /// [receiverUserId], as sent with a `receiver_user_id` argument to methods
  /// like [sendLivePhoto]) previously sent in [chatId].
  Future<dynamic> editEphemeralMessageText(
    Object chatId,
    int receiverUserId,
    int ephemeralMessageId,
    String text, {
    String? businessConnectionId,
    ParseMode? parseMode,
    List<Json>? entities,
    LinkPreviewOptions? linkPreviewOptions,
    InlineKeyboardMarkup? replyMarkup,
  }) =>
      call('editEphemeralMessageText', {
        'chat_id': chatId,
        'receiver_user_id': receiverUserId,
        'ephemeral_message_id': ephemeralMessageId,
        'text': text,
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (parseMode != null) 'parse_mode': parseMode.value,
        if (entities != null) 'entities': entities,
        if (linkPreviewOptions != null)
          'link_preview_options': linkPreviewOptions.toJson(),
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      });

  /// Replaces the media of an ephemeral message. See [editEphemeralMessageText].
  Future<dynamic> editEphemeralMessageMedia(
    Object chatId,
    int receiverUserId,
    int ephemeralMessageId,
    InputMedia media, {
    String? businessConnectionId,
    InlineKeyboardMarkup? replyMarkup,
  }) {
    final files = <String, InputFile>{};
    String mediaRef;
    if (media.media.isUpload) {
      files['file'] = media.media;
      mediaRef = 'attach://file';
    } else {
      mediaRef = media.media.remoteValue!;
    }
    String? thumbRef;
    if (media.thumbnail != null) {
      if (media.thumbnail!.isUpload) {
        files['thumb'] = media.thumbnail!;
        thumbRef = 'attach://thumb';
      } else {
        thumbRef = media.thumbnail!.remoteValue;
      }
    }
    return call(
      'editEphemeralMessageMedia',
      {
        'chat_id': chatId,
        'receiver_user_id': receiverUserId,
        'ephemeral_message_id': ephemeralMessageId,
        'media': media.toJson(mediaRef, thumbRef: thumbRef),
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      },
      files,
    );
  }

  /// Edits the caption of an ephemeral message. See [editEphemeralMessageText].
  Future<dynamic> editEphemeralMessageCaption(
    Object chatId,
    int receiverUserId,
    int ephemeralMessageId, {
    String? businessConnectionId,
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    bool? showCaptionAboveMedia,
    InlineKeyboardMarkup? replyMarkup,
  }) =>
      call('editEphemeralMessageCaption', {
        'chat_id': chatId,
        'receiver_user_id': receiverUserId,
        'ephemeral_message_id': ephemeralMessageId,
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (caption != null) 'caption': caption,
        if (parseMode != null) 'parse_mode': parseMode.value,
        if (captionEntities != null) 'caption_entities': captionEntities,
        if (showCaptionAboveMedia != null)
          'show_caption_above_media': showCaptionAboveMedia,
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      });

  /// Replaces the inline keyboard of an ephemeral message. See [editEphemeralMessageText].
  Future<dynamic> editEphemeralMessageReplyMarkup(
    Object chatId,
    int receiverUserId,
    int ephemeralMessageId, {
    String? businessConnectionId,
    InlineKeyboardMarkup? replyMarkup,
  }) =>
      call('editEphemeralMessageReplyMarkup', {
        'chat_id': chatId,
        'receiver_user_id': receiverUserId,
        'ephemeral_message_id': ephemeralMessageId,
        if (businessConnectionId != null)
          'business_connection_id': businessConnectionId,
        if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
      });

  /// Deletes an ephemeral message. See [editEphemeralMessageText].
  Future<bool> deleteEphemeralMessage(
    Object chatId,
    int receiverUserId,
    int ephemeralMessageId,
  ) async =>
      _b(
        await call('deleteEphemeralMessage', {
          'chat_id': chatId,
          'receiver_user_id': receiverUserId,
          'ephemeral_message_id': ephemeralMessageId,
        }),
      );

  /// Changes a user's emoji status on the bot's behalf (requires prior user consent via a Mini App).
  Future<bool> setUserEmojiStatus(
    String businessConnectionId,
    int userId, {
    String? emojiStatusCustomEmojiId,
    int? emojiStatusExpirationDate,
  }) async =>
      _b(
        await call('setUserEmojiStatus', {
          'business_connection_id': businessConnectionId,
          'user_id': userId,
          if (emojiStatusCustomEmojiId != null)
            'emoji_status_custom_emoji_id': emojiStatusCustomEmojiId,
          if (emojiStatusExpirationDate != null)
            'emoji_status_expiration_date': emojiStatusExpirationDate,
        }),
      );

  /// Fetches details about a Telegram Business connection by its ID.
  Future<Json> getBusinessConnection(String businessConnectionId) async => _o(
        await call(
          'getBusinessConnection',
          {'business_connection_id': businessConnectionId},
        ),
      );

  /// Changes the first/last name on a connected business account.
  Future<bool> setBusinessAccountName(
    String businessConnectionId,
    String firstName, {
    String? lastName,
  }) async =>
      _b(
        await call('setBusinessAccountName', {
          'business_connection_id': businessConnectionId,
          'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        }),
      );

  /// Changes the username on a connected business account.
  Future<bool> setBusinessAccountUsername(
    String businessConnectionId, {
    String? username,
  }) async =>
      _b(
        await call('setBusinessAccountUsername', {
          'business_connection_id': businessConnectionId,
          if (username != null) 'username': username,
        }),
      );

  /// Changes the bio on a connected business account.
  Future<bool> setBusinessAccountBio(
    String businessConnectionId, {
    String? bio,
  }) async =>
      _b(
        await call('setBusinessAccountBio', {
          'business_connection_id': businessConnectionId,
          if (bio != null) 'bio': bio,
        }),
      );

  /// Sets the profile photo of a connected business account.
  Future<bool> setBusinessAccountProfilePhoto(
    String businessConnectionId,
    InputProfilePhoto photo, {
    bool? isPublic,
  }) async {
    final files = <String, InputFile>{};
    final photoJson = photo.toJson(files);
    return _b(
      await call(
        'setBusinessAccountProfilePhoto',
        {
          'business_connection_id': businessConnectionId,
          'photo': photoJson,
          if (isPublic != null) 'is_public': isPublic,
        },
        files,
      ),
    );
  }

  /// Removes the profile photo of a connected business account.
  Future<bool> removeBusinessAccountProfilePhoto(
    String businessConnectionId, {
    bool? isPublic,
  }) async =>
      _b(
        await call('removeBusinessAccountProfilePhoto', {
          'business_connection_id': businessConnectionId,
          if (isPublic != null) 'is_public': isPublic,
        }),
      );

  /// Configures which gift types a connected business account accepts, via [acceptedGiftTypes].
  Future<bool> setBusinessAccountGiftSettings(
    String businessConnectionId,
    bool showGiftButton,
    AcceptedGiftTypes acceptedGiftTypes,
  ) async =>
      _b(
        await call('setBusinessAccountGiftSettings', {
          'business_connection_id': businessConnectionId,
          'show_gift_button': showGiftButton,
          'accepted_gift_types': acceptedGiftTypes.toJson(),
        }),
      );

  /// Returns the Telegram Stars balance of a connected business account.
  Future<Json> getBusinessAccountStarBalance(
    String businessConnectionId,
  ) async =>
      _o(
        await call(
          'getBusinessAccountStarBalance',
          {'business_connection_id': businessConnectionId},
        ),
      );

  /// Transfers Telegram Stars out of a connected business account.
  Future<bool> transferBusinessAccountStars(
    String businessConnectionId,
    int starCount,
  ) async =>
      _b(
        await call('transferBusinessAccountStars', {
          'business_connection_id': businessConnectionId,
          'star_count': starCount,
        }),
      );

  /// Lists gifts owned by a connected business account.
  Future<Json> getBusinessAccountGifts(
    String businessConnectionId, {
    bool? excludeUnsaved,
    bool? excludeSaved,
    bool? excludeUnlimited,
    bool? excludeLimitedUpgradable,
    bool? excludeLimitedNonUpgradable,
    bool? excludeUnique,
    bool? sortByPrice,
    String? offset,
    int? limit,
  }) async =>
      _o(
        await call('getBusinessAccountGifts', {
          'business_connection_id': businessConnectionId,
          if (excludeUnsaved != null) 'exclude_unsaved': excludeUnsaved,
          if (excludeSaved != null) 'exclude_saved': excludeSaved,
          if (excludeUnlimited != null) 'exclude_unlimited': excludeUnlimited,
          if (excludeLimitedUpgradable != null)
            'exclude_limited_upgradable': excludeLimitedUpgradable,
          if (excludeLimitedNonUpgradable != null)
            'exclude_limited_non_upgradable': excludeLimitedNonUpgradable,
          if (excludeUnique != null) 'exclude_unique': excludeUnique,
          if (sortByPrice != null) 'sort_by_price': sortByPrice,
          if (offset != null) 'offset': offset,
          if (limit != null) 'limit': limit,
        }),
      );

  /// Lists gifts publicly displayed on a user's profile.
  Future<Json> getUserGifts(
    int userId, {
    bool? excludeUnlimited,
    bool? excludeLimitedUpgradable,
    bool? excludeLimitedNonUpgradable,
    bool? excludeUnique,
    bool? excludeFromBlockchain,
    bool? sortByPrice,
    String? offset,
    int? limit,
  }) async =>
      _o(
        await call('getUserGifts', {
          'user_id': userId,
          if (excludeUnlimited != null) 'exclude_unlimited': excludeUnlimited,
          if (excludeLimitedUpgradable != null)
            'exclude_limited_upgradable': excludeLimitedUpgradable,
          if (excludeLimitedNonUpgradable != null)
            'exclude_limited_non_upgradable': excludeLimitedNonUpgradable,
          if (excludeUnique != null) 'exclude_unique': excludeUnique,
          if (excludeFromBlockchain != null)
            'exclude_from_blockchain': excludeFromBlockchain,
          if (sortByPrice != null) 'sort_by_price': sortByPrice,
          if (offset != null) 'offset': offset,
          if (limit != null) 'limit': limit,
        }),
      );

  /// Lists gifts publicly displayed on a channel chat's profile.
  Future<Json> getChatGifts(
    Object chatId, {
    bool? excludeUnlimited,
    bool? excludeLimitedUpgradable,
    bool? excludeLimitedNonUpgradable,
    bool? excludeUnique,
    bool? excludeFromBlockchain,
    bool? sortByPrice,
    String? offset,
    int? limit,
  }) async =>
      _o(
        await call('getChatGifts', {
          'chat_id': chatId,
          if (excludeUnlimited != null) 'exclude_unlimited': excludeUnlimited,
          if (excludeLimitedUpgradable != null)
            'exclude_limited_upgradable': excludeLimitedUpgradable,
          if (excludeLimitedNonUpgradable != null)
            'exclude_limited_non_upgradable': excludeLimitedNonUpgradable,
          if (excludeUnique != null) 'exclude_unique': excludeUnique,
          if (excludeFromBlockchain != null)
            'exclude_from_blockchain': excludeFromBlockchain,
          if (sortByPrice != null) 'sort_by_price': sortByPrice,
          if (offset != null) 'offset': offset,
          if (limit != null) 'limit': limit,
        }),
      );

  /// Converts a regular gift owned by a business account into Telegram Stars.
  Future<bool> convertGiftToStars(
    String businessConnectionId,
    String ownedGiftId,
  ) async =>
      _b(
        await call('convertGiftToStars', {
          'business_connection_id': businessConnectionId,
          'owned_gift_id': ownedGiftId,
        }),
      );

  /// Upgrades a regular gift owned by a business account into a unique gift.
  Future<bool> upgradeGift(
    String businessConnectionId,
    String ownedGiftId, {
    bool? keepOriginalDetails,
    int? starCount,
  }) async =>
      _b(
        await call('upgradeGift', {
          'business_connection_id': businessConnectionId,
          'owned_gift_id': ownedGiftId,
          if (keepOriginalDetails != null)
            'keep_original_details': keepOriginalDetails,
          if (starCount != null) 'star_count': starCount,
        }),
      );

  /// Transfers a unique gift owned by a business account to another owner.
  Future<bool> transferGift(
    String businessConnectionId,
    String ownedGiftId,
    int newOwnerChatId, {
    int? starCount,
  }) async =>
      _b(
        await call('transferGift', {
          'business_connection_id': businessConnectionId,
          'owned_gift_id': ownedGiftId,
          'new_owner_chat_id': newOwnerChatId,
          if (starCount != null) 'star_count': starCount,
        }),
      );

  /// Marks a message in a connected business account's chat as read.
  Future<bool> readBusinessMessage(
    String businessConnectionId,
    int chatId,
    int messageId,
  ) async =>
      _b(
        await call('readBusinessMessage', {
          'business_connection_id': businessConnectionId,
          'chat_id': chatId,
          'message_id': messageId,
        }),
      );

  /// Deletes messages on behalf of a connected business account.
  Future<bool> deleteBusinessMessages(
    String businessConnectionId,
    List<int> messageIds,
  ) async =>
      _b(
        await call('deleteBusinessMessages', {
          'business_connection_id': businessConnectionId,
          'message_ids': messageIds,
        }),
      );

  /// Posts a new Telegram Story on behalf of a connected business account.
  Future<Json> postStory(
    String businessConnectionId,
    InputStoryContent content,
    int activePeriod, {
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    List<Json>? areas,
    bool? postToChatPage,
    bool? protectContent,
  }) async {
    final files = <String, InputFile>{};
    final contentJson = content.toJson(files);
    return _o(
      await call(
        'postStory',
        {
          'business_connection_id': businessConnectionId,
          'content': contentJson,
          'active_period': activePeriod,
          if (caption != null) 'caption': caption,
          if (parseMode != null) 'parse_mode': parseMode.value,
          if (captionEntities != null) 'caption_entities': captionEntities,
          if (areas != null) 'areas': areas,
          if (postToChatPage != null) 'post_to_chat_page': postToChatPage,
          if (protectContent != null) 'protect_content': protectContent,
        },
        files,
      ),
    );
  }

  /// Edits a previously posted Telegram Story.
  Future<Json> editStory(
    String businessConnectionId,
    int storyId,
    InputStoryContent content, {
    String? caption,
    ParseMode? parseMode,
    List<Json>? captionEntities,
    List<Json>? areas,
  }) async {
    final files = <String, InputFile>{};
    final contentJson = content.toJson(files);
    return _o(
      await call(
        'editStory',
        {
          'business_connection_id': businessConnectionId,
          'story_id': storyId,
          'content': contentJson,
          if (caption != null) 'caption': caption,
          if (parseMode != null) 'parse_mode': parseMode.value,
          if (captionEntities != null) 'caption_entities': captionEntities,
          if (areas != null) 'areas': areas,
        },
        files,
      ),
    );
  }

  /// Deletes a previously posted Telegram Story.
  Future<bool> deleteStory(String businessConnectionId, int storyId) async =>
      _b(
        await call('deleteStory', {
          'business_connection_id': businessConnectionId,
          'story_id': storyId,
        }),
      );

  /// Reposts a story from one connected business account to another. Both
  /// accounts must be managed by this bot, and the source story must have
  /// been posted (or reposted) by this bot. Requires the
  /// `can_manage_stories` business bot right on both accounts. [activePeriod]
  /// must be one of `6 * 3600`, `12 * 3600`, `86400`, or `2 * 86400` seconds.
  Future<Json> repostStory(
    String businessConnectionId,
    int fromChatId,
    int fromStoryId,
    int activePeriod, {
    bool? postToChatPage,
    bool? protectContent,
  }) async =>
      _o(
        await call('repostStory', {
          'business_connection_id': businessConnectionId,
          'from_chat_id': fromChatId,
          'from_story_id': fromStoryId,
          'active_period': activePeriod,
          if (postToChatPage != null) 'post_to_chat_page': postToChatPage,
          if (protectContent != null) 'protect_content': protectContent,
        }),
      );

  /// Lists all gifts currently purchasable to send to users.
  Future<Json> getAvailableGifts() async => _o(await call('getAvailableGifts'));

  /// Sends a gift to a user or channel, optionally paid for in Telegram Stars.
  Future<bool> sendGift(
    String giftId, {
    int? userId,
    Object? chatId,
    String? text,
    ParseMode? textParseMode,
    List<Json>? textEntities,
    bool? payForUpgrade,
  }) async =>
      _b(
        await call('sendGift', {
          'gift_id': giftId,
          if (userId != null) 'user_id': userId,
          if (chatId != null) 'chat_id': chatId,
          if (text != null) 'text': text,
          if (textParseMode != null) 'text_parse_mode': textParseMode.value,
          if (textEntities != null) 'text_entities': textEntities,
          if (payForUpgrade != null) 'pay_for_upgrade': payForUpgrade,
        }),
      );

  /// Gifts a Telegram Premium subscription to a user.
  Future<bool> giftPremiumSubscription(
    int userId,
    int monthCount,
    int starCount, {
    String? text,
    ParseMode? textParseMode,
    List<Json>? textEntities,
  }) async =>
      _b(
        await call('giftPremiumSubscription', {
          'user_id': userId,
          'month_count': monthCount,
          'star_count': starCount,
          if (text != null) 'text': text,
          if (textParseMode != null) 'text_parse_mode': textParseMode.value,
          if (textEntities != null) 'text_entities': textEntities,
        }),
      );

  /// Reports validation errors on a user's Telegram Passport data, prompting them to resubmit.
  Future<bool> setPassportDataErrors(int userId, List<Json> errors) async => _b(
        await call(
          'setPassportDataErrors',
          {'user_id': userId, 'errors': errors},
        ),
      );

  /// Validates and parses the `initData` string a Telegram Mini App sends
  /// you, using this bot's [token] to verify Telegram's HMAC signature.
  ///
  /// Always check `.isValid` on the result before trusting any of its
  /// fields — this confirms the data really came from Telegram and wasn't
  /// tampered with by the client.
  WebAppInitData verifyWebAppInitData(String initData) =>
      webapp.verifyWebAppInitData(initData, token);
}
