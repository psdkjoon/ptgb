import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'core.dart';
import 'input_file.dart';

/// Low-level HTTP transport used internally by [Bot] to talk to the
/// Telegram Bot API. You normally never need to touch this directly —
/// use [Bot.call] or one of its typed methods instead.
class TelegramHttpClient {
  /// Base URL requests are POSTed to, e.g. `https://api.telegram.org/bot<token>`.
  final String apiBaseUrl;

  /// Base URL files are downloaded from, e.g. `https://api.telegram.org/file/bot<token>`.
  final String fileBaseUrl;

  /// How long to wait for a request to complete before giving up with a
  /// [TimeoutException]. Applied on top of Telegram's own long-polling
  /// `timeout` parameter (see [Bot.getUpdates]), so this should generally
  /// be set comfortably higher than the longest `timeout` you pass to
  /// [Bot.poll] — the default (35s) already leaves 5s of headroom over
  /// [Bot.poll]'s default 30s long-poll timeout.
  final Duration requestTimeout;

  final HttpClient _client;

  /// Creates a client pointed at [apiBaseUrl] and [fileBaseUrl]. Every
  /// request (including long-polling calls to `getUpdates`) is aborted
  /// with a [TimeoutException] after [requestTimeout] if Telegram hasn't
  /// responded by then.
  TelegramHttpClient(
    this.apiBaseUrl,
    this.fileBaseUrl, {
    this.requestTimeout = const Duration(seconds: 35),
  }) : _client = HttpClient()..connectionTimeout = requestTimeout;

  /// Calls [method] with [params] and optional multipart [files], returning
  /// the raw `result` field on success or throwing [TelegramApiException] on
  /// failure. Throws [TelegramApiException] (rather than a raw
  /// [FormatException]) if Telegram's response isn't valid JSON — this can
  /// happen when an intermediary (proxy, load balancer, ...) returns an
  /// HTML error page instead of the API responding, e.g. during a 502/503.
  Future<dynamic> call(
    String method, [
    Json? params,
    Map<String, InputFile>? files,
  ]) async {
    final uri = Uri.parse('$apiBaseUrl/$method');
    final hasUpload = files != null && files.values.any((f) => f.isUpload);

    final HttpClientRequest request =
        await _client.postUrl(uri).timeout(requestTimeout);
    late final List<int> body;

    if (hasUpload) {
      final boundary = '----ptgb${DateTime.now().microsecondsSinceEpoch}';
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      body = await _buildMultipartBody(boundary, params, files);
    } else {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      final merged = <String, dynamic>{...?params};
      files?.forEach((key, value) {
        final ref = value.remoteValue;
        if (ref != null) merged[key] = ref;
      });
      body = utf8.encode(jsonEncode(merged));
    }

    request.contentLength = body.length;
    request.add(body);

    final response = await request.close().timeout(requestTimeout);
    final responseBody =
        await response.transform(utf8.decoder).join().timeout(requestTimeout);

    final Json decoded;
    try {
      decoded = jsonDecode(responseBody) as Json;
    } on FormatException catch (e) {
      throw TelegramApiException(
        response.statusCode,
        'Telegram API returned a non-JSON response (HTTP ${response.statusCode}): ${e.message}',
        null,
      );
    }

    if (decoded['ok'] == true) return decoded['result'];

    throw TelegramApiException(
      decoded['error_code'] as int? ?? response.statusCode,
      decoded['description'] as String? ?? 'unknown telegram api error',
      decoded['parameters'] as Json?,
    );
  }

  /// Downloads the raw bytes of [filePath] (as returned by `getFile`).
  Future<Uint8List> downloadFile(String filePath) async {
    final uri = Uri.parse('$fileBaseUrl/$filePath');
    final request = await _client.getUrl(uri).timeout(requestTimeout);
    final response = await request.close().timeout(requestTimeout);
    final builder = BytesBuilder();
    await for (final chunk in response.timeout(requestTimeout)) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<List<int>> _buildMultipartBody(
    String boundary,
    Json? params,
    Map<String, InputFile> files,
  ) async {
    final builder = BytesBuilder();

    void writeField(String name, String value) {
      builder.add(utf8.encode('--$boundary\r\n'));
      builder.add(
        utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'),
      );
      builder.add(utf8.encode(value));
      builder.add(utf8.encode('\r\n'));
    }

    params?.forEach((key, value) {
      if (value == null) return;
      writeField(key, value is String ? value : jsonEncode(value));
    });

    for (final entry in files.entries) {
      final file = entry.value;
      if (file.isUpload) {
        final data = await file.readBytes();
        builder.add(utf8.encode('--$boundary\r\n'));
        builder.add(
          utf8.encode(
            'Content-Disposition: form-data; name="${entry.key}"; filename="${file.filename}"\r\n',
          ),
        );
        builder
            .add(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
        builder.add(data);
        builder.add(utf8.encode('\r\n'));
      } else if (file.remoteValue != null) {
        writeField(entry.key, file.remoteValue!);
      }
    }

    builder.add(utf8.encode('--$boundary--\r\n'));
    return builder.takeBytes();
  }

  /// Closes the underlying [HttpClient], aborting any in-flight requests.
  void close() => _client.close(force: true);
}
