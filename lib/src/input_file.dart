import 'dart:io';
import 'dart:typed_data';

/// Represents a file to be sent to Telegram — a `file_id` you already have,
/// a public URL, a path on disk, or raw bytes in memory.
///
/// Used everywhere Telegram accepts a "photo, video, document, ..." — e.g.
/// [Bot.sendPhoto], [Bot.sendDocument], [InputMedia.photo]. Pick the factory
/// that matches what you have:
///
/// ```dart
/// InputFile.id('AgACAgIAAxk...');           // reuse a file already on Telegram's servers
/// InputFile.url('https://example.com/a.png'); // let Telegram fetch it
/// InputFile.path('assets/photo.jpg');          // upload a local file
/// InputFile.bytes(myBytes, filename: 'a.png'); // upload in-memory bytes
/// ```
class InputFile {
  final String? _fileId;
  final String? _url;
  final String? _path;
  final Uint8List? _bytes;
  final String? _filename;

  const InputFile._(
    this._fileId,
    this._url,
    this._path,
    this._bytes,
    this._filename,
  );

  /// Reuses a file already stored on Telegram's servers by its `file_id`.
  /// This is the fastest option since no bytes are re-uploaded.
  factory InputFile.id(String fileId) =>
      InputFile._(fileId, null, null, null, null);

  /// Points Telegram at a publicly accessible [url] to fetch the file from.
  factory InputFile.url(String url) => InputFile._(null, url, null, null, null);

  /// Uploads a local file from disk at [path]. [filename] defaults to the
  /// file's base name if not provided.
  factory InputFile.path(String path, {String? filename}) => InputFile._(
        null,
        null,
        path,
        null,
        filename ?? path.split(Platform.pathSeparator).last,
      );

  /// Uploads raw in-memory [bytes] under the given [filename], useful when
  /// you generated or downloaded the file content without writing it to disk.
  factory InputFile.bytes(List<int> bytes, {required String filename}) =>
      InputFile._(null, null, null, Uint8List.fromList(bytes), filename);

  /// Whether this file needs to be uploaded as multipart form data, as
  /// opposed to being referenced by a `file_id` or URL string.
  bool get isUpload => _path != null || _bytes != null;

  /// The `file_id` or URL string to send as-is, or `null` if this file must be uploaded.
  String? get remoteValue => _fileId ?? _url;

  /// The filename to report to Telegram when uploading.
  String get filename => _filename ?? 'file';

  /// Reads the file's bytes, from memory if provided via [InputFile.bytes],
  /// or from disk if provided via [InputFile.path].
  Future<Uint8List> readBytes() async {
    if (_bytes != null) return _bytes;
    return Uint8List.fromList(await File(_path!).readAsBytes());
  }
}
