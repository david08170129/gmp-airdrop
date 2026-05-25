import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'ios_native_picker_service.dart';

class IosUploadProgress {
  const IosUploadProgress({
    required this.sentBytes,
    required this.totalBytes,
  });

  final int sentBytes;
  final int totalBytes;

  double get value {
    if (totalBytes <= 0) return 0;
    return (sentBytes / totalBytes).clamp(0, 1).toDouble();
  }
}

class IosWirelessUploadService {
  Future<int> upload({
    required Uri receiverUrl,
    required List<IosPickedFile> files,
    required void Function(IosUploadProgress progress) onProgress,
  }) async {
    if (files.isEmpty) return 0;

    final token = receiverUrl.queryParameters['t'];
    if (token == null || token.isEmpty) {
      throw const FormatException('Receiver URL is missing its upload token.');
    }

    final uploadUrl = receiverUrl.replace(
      path: '/upload',
      queryParameters: {'t': token},
    );
    final boundary = 'gmp-airdrop-${DateTime.now().microsecondsSinceEpoch}'
        '-${Random.secure().nextInt(1 << 32)}';
    final client = HttpClient();
    final request = await client.postUrl(uploadUrl);
    request.headers.contentType = ContentType(
      'multipart',
      'form-data',
      parameters: {'boundary': boundary},
    );

    final totalBytes = await _multipartLength(files, boundary);
    request.contentLength = totalBytes;

    var sentBytes = 0;
    void addBytes(List<int> bytes) {
      request.add(bytes);
      sentBytes += bytes.length;
      onProgress(IosUploadProgress(
        sentBytes: sentBytes,
        totalBytes: totalBytes,
      ));
    }

    for (final picked in files) {
      final file = picked.file;
      final name = picked.name.isEmpty ? p.basename(picked.path) : picked.name;
      final mimeType =
          lookupMimeType(picked.path) ?? 'application/octet-stream';
      addBytes(utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="files"; '
        'filename="${_quoted(name)}"\r\n'
        'Content-Type: $mimeType\r\n\r\n',
      ));

      await for (final chunk in file.openRead()) {
        addBytes(chunk);
      }

      addBytes(utf8.encode('\r\n'));
    }

    addBytes(utf8.encode('--$boundary--\r\n'));

    try {
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _messageFromResponse(body) ??
            'Upload failed with HTTP ${response.statusCode}.';
        throw HttpException(message, uri: uploadUrl);
      }

      return files.length;
    } finally {
      client.close();
    }
  }

  Future<int> _multipartLength(
    List<IosPickedFile> files,
    String boundary,
  ) async {
    var length = 0;
    for (final picked in files) {
      final file = picked.file;
      final name = picked.name.isEmpty ? p.basename(picked.path) : picked.name;
      final mimeType =
          lookupMimeType(picked.path) ?? 'application/octet-stream';
      length += utf8
          .encode(
            '--$boundary\r\n'
            'Content-Disposition: form-data; name="files"; '
            'filename="${_quoted(name)}"\r\n'
            'Content-Type: $mimeType\r\n\r\n',
          )
          .length;
      length += await file.length();
      length += 2;
    }
    length += utf8.encode('--$boundary--\r\n').length;
    return length;
  }

  String _quoted(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('"', r'\"');
  }

  String? _messageFromResponse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return json['message']?.toString();
      }
    } on FormatException {
      return body.trim().isEmpty ? null : body.trim();
    }
    return null;
  }
}
