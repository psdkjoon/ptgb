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
  final HttpClient _client = HttpClient();

  /// Creates a client pointed at [apiBaseUrl] and [fileBaseUrl].
  TelegramHttpClient(this.apiBaseUrl, this.fileBaseUrl);

  /// Calls [method] with [params] and optional multipart [files], returning
  /// the raw `result` field on success or throwing [TelegramApiException] on failure.
  Future<dynamic> call(String method, [Json? params, Map<String, InputFile>? files]) async {
    final uri = Uri.parse('$apiBaseUrl/$method');
    final hasUpload = files != null && files.values.any((f) => f.isUpload);

    final HttpClientRequest request = await _client.postUrl(uri);
    late final List<int> body;

    if (hasUpload) {
      final boundary = '----ptgb${DateTime.now().microsecondsSinceEpoch}';
      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
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

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(responseBody) as Json;

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
    final request = await _client.getUrl(uri);
    final response = await request.close();
    final builder = BytesBuilder();
    await for (final chunk in response) {
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
      builder.add(utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'));
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
        builder.add(utf8.encode(
            'Content-Disposition: form-data; name="${entry.key}"; filename="${file.filename}"\r\n',),);
        builder.add(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
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
